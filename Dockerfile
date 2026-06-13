# =============================================================================
# Dockerfile — recette pour fabriquer l'image de l'app "Ensemble"
# =============================================================================
# Principe (multi-stage build) : on travaille en 3 temps pour obtenir une image
# finale LÉGÈRE. On installe les outils de compilation dans une image jetable
# ("build"), et on ne garde dans l'image finale que le strict nécessaire pour
# faire TOURNER l'app (pas les compilateurs).
#
#   1. base   : socle commun (Ruby + variables d'env)
#   2. build  : installe gems + JS + compile les assets  (JETÉ à la fin)
#   3. final  : base + Chromium + le résultat copié depuis "build"
#
# La même image sert pour le web (Puma) ET pour le worker (Sidekiq) : seule la
# commande de démarrage change (gérée côté Coolify).
# -----------------------------------------------------------------------------

# Versions épinglées (= reproductibilité). Elles correspondent à .ruby-version
# et au champ "engines" de package.json.
ARG RUBY_VERSION=3.3.10
ARG NODE_VERSION=20.17.0
ARG YARN_VERSION=1.22.22


# -----------------------------------------------------------------------------
# Étape 0 — Image Node officielle, utilisée UNIQUEMENT comme source à copier.
# Plus simple et plus rapide que de compiler Node nous-mêmes. Même base Debian
# (bookworm) que l'image Ruby ci-dessous, donc les binaires sont compatibles.
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-bookworm-slim AS node


# -----------------------------------------------------------------------------
# Étape 1 — base : socle commun aux étapes build et final.
# -----------------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim AS base

# Dossier de travail de l'app dans le conteneur.
WORKDIR /rails

# Variables d'environnement valables pour la construction ET l'exécution.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"


# -----------------------------------------------------------------------------
# Étape 2 — build : image JETABLE où l'on compile tout.
# -----------------------------------------------------------------------------
FROM base AS build

# Outils nécessaires POUR COMPILER (présents seulement ici, pas dans l'image finale) :
#  - build-essential : compilateur C/C++ (gems natives comme pg, sassc...)
#  - git             : certaines gems sont tirées depuis Git
#  - libpq-dev       : en-têtes PostgreSQL pour compiler la gem "pg"
#  - libyaml-dev     : pour psych/YAML
#  - pkg-config      : aide les gems natives à trouver les libs système
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# --- Node.js + Yarn (copiés depuis l'image officielle Node de l'étape 0) ---
# On récupère juste le binaire node et les modules npm globaux, puis on
# installe Yarn (version classique 1.x, comme en local).
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    npm install -g yarn@${YARN_VERSION}

# --- Gems Ruby ---
# On copie d'abord SEULEMENT Gemfile/Gemfile.lock : tant qu'ils ne changent pas,
# Docker réutilise le cache de cette couche (= builds beaucoup plus rapides).
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache && \
    bundle exec bootsnap precompile --gemfile

# --- Dépendances JavaScript ---
# Même logique de cache : package.json + yarn.lock d'abord.
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# --- Code de l'app + compilation des assets ---
COPY . .

# Précompile bootsnap (démarrage plus rapide au runtime).
RUN bundle exec bootsnap precompile app/ lib/

# Bundle JavaScript avec esbuild AVANT la précompilation Sprockets.
# INDISPENSABLE : app/assets/builds/ est gitignoré → vide dans le clone Git de
# Coolify. Sans ce build explicite, app/assets/builds/application.js n'existe pas,
# Sprockets ne le digère pas, et l'app retombe sur /javascripts/application.js (404)
# → tout le JS (Stimulus/Turbo) casse. On ne se repose donc PAS sur le hook jsbundling.
RUN yarn build

# Compile les assets Sprockets : digère le bundle JS produit ci-dessus + le SCSS.
# SECRET_KEY_BASE_DUMMY=1 fournit une clé bidon → pas besoin du vrai master.key au build.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# -----------------------------------------------------------------------------
# Étape 3 — final : l'image qui sera réellement déployée.
# Repart de "base" (légère) + dépendances de RUNTIME uniquement.
# -----------------------------------------------------------------------------
FROM base

# Paquets nécessaires pour FAIRE TOURNER l'app :
#  - libpq5            : client PostgreSQL (requis par la gem pg)
#  - libvips           : traitement d'images (gem image_processing)
#  - postgresql-client : commandes psql/pg_dump (debug, maintenance)
#  - chromium          : navigateur headless pour la génération de PDF (Ferrum/Grover)
#  - fonts-*           : polices, sinon les PDF rendent mal les accents/emojis
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libpq5 \
      libvips \
      postgresql-client \
      chromium \
      fonts-liberation \
      fonts-noto-color-emoji && \
    rm -rf /var/lib/apt/lists/*

# Chemin du binaire Chromium installé ci-dessus. config/initializers/ferrum.rb
# lit CHROME_PATH en priorité : aucune modif de code Ruby nécessaire.
ENV CHROME_PATH="/usr/bin/chromium"

# Runtime JavaScript (Node) requis AU DÉMARRAGE par execjs/autoprefixer-rails :
# sans lui, le boot échoue ("Could not find a JavaScript runtime").
# On copie uniquement le binaire node (pas npm/yarn) depuis l'étape Node.
COPY --from=node /usr/local/bin/node /usr/local/bin/node

# On récupère, depuis l'étape "build" jetable :
#  - les gems déjà installées
#  - l'app + les assets déjà compilés
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Sécurité : on ne tourne PAS en root. On crée un utilisateur dédié "rails"
# et on lui donne les droits sur les seuls dossiers où l'app écrit.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp storage && \
    chown -R rails:rails log tmp storage
USER 1000:1000

# Entrypoint : prépare l'environnement avant de lancer la commande (voir le script).
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Port exposé (Puma écoute sur $PORT, défaut 3000). Coolify/Traefik route dessus.
EXPOSE 3000

# Commande par défaut = serveur web Puma (identique au Procfile actuel).
# Le conteneur worker Sidekiq surchargera cette commande côté Coolify.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
