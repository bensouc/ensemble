# CLAUDE.md - Ensemble

Contexte pour Claude Code sur ce projet. Dérivé du `CLAUDE.md` de Wishes, lui-même dérivé de celui
d'osponso : **mêmes principes de travail**, adapté à Ensemble.

## Vue d'ensemble

**Ensemble** — l'app des professeur·es de l'école élémentaire (CP → CM2) qui travaillent **par
ceintures** : des compétences rangées par domaine et par ceinture (blanche → noire), des **plans de
travail** préparés pour chaque élève, l'évaluation, les **fiches de ceinture** imprimées, et
**Manipule**, l'app compagnon où l'élève s'entraîne en autocorrection.

Le code et l'écran ne parlent pas la même langue :

| Code | À l'écran |
| --- | --- |
| `WorkPlan` | plan de travail |
| `BeltSheet` | fiche de ceinture |
| `Challenge` | exercice — « exercice de ceinture », **jamais « épreuve »** |
| `Skill` / `Domain` / `Grade` | compétence / domaine / niveau |
| tableau de bord | **jamais « Cartable »** |
| `User` | professeur·e — **jamais « maîtresse »** |

La règle qui structure tout : **une école ne voit jamais les données d'une autre**. Une classe se
partage entre ses professeur·es et ceux à qui on la partage ; les exercices et les tableaux se
partagent dans toute l'école, jamais au-dessus. Toute policy, tout scope se relit à travers cette
phrase — et la spec de cloisonnement (`spec/requests/cloisonnement_des_ecoles_spec.rb`) ouvre toutes
les pages en traquant l'école d'à côté.

## Principes de Travail

### 1. Réfléchir avant de coder

Ne pas supposer. Ne pas masquer la confusion. Exposer les compromis.

- Énoncer explicitement ses hypothèses. En cas de doute, demander.
- S'il existe plusieurs interprétations, les présenter — ne pas choisir en silence.
- S'il existe une approche plus simple, le dire. Pousser en arrière quand c'est justifié.
- Si quelque chose est flou, s'arrêter. Nommer ce qui est confus. Demander.

### 2. Simplicité d'abord

Code minimum qui résout le problème. Rien de spéculatif.

- Pas de fonctionnalités au-delà de ce qui est demandé.
- Pas d'abstractions pour du code à usage unique.
- Pas de « flexibilité » ou « configurabilité » non demandée.
- Pas de gestion d'erreurs pour des scénarios impossibles.
- Si 200 lignes peuvent être réduites à 50, réécrire.

Se demander : « Un développeur senior dirait-il que c'est trop compliqué ? » Si oui, simplifier.

### 3. Changements chirurgicaux

Ne toucher que le strict nécessaire. Ne nettoyer que son propre bazar.

- Ne pas « améliorer » le code adjacent, les commentaires ou le formatage.
- Ne pas refactorer ce qui n'est pas cassé.
- **Une retouche visuelle ne s'étend pas d'elle-même** aux éléments voisins : la proposer en une
  ligne, ne pas la faire.
- Supprimer les imports/variables/fonctions rendus inutiles par SES changements — pas le code mort
  préexistant, sauf demande explicite.

### 4. Critères de succès explicites

Pour les tâches multi-étapes, énoncer un plan bref : `[Étape] → vérifier : [contrôle]`.

### 5. Pas de paresse

- Trouver les causes racines. Pas de correctifs temporaires.
- **Ne pas écrire de code qui viole le SRP** : une classe = une responsabilité, une méthode = une action.

### 6. Élégance mesurée

Pour les changements non triviaux : se demander « existe-t-il une solution plus élégante ? ». Si un
correctif semble hacky, implémenter la solution élégante. Pas de sur-ingénierie pour les corrections
évidentes. Remettre en question son propre travail avant de le présenter.

### 7. Correction autonome des bugs

Face à un rapport de bug : le corriger directement. Pointer les logs, erreurs, tests en échec — puis
les résoudre. Zéro changement de contexte requis de la part de l'utilisateur.

### Vérification avant validation

Ne jamais marquer une tâche comme terminée sans prouver qu'elle fonctionne : lancer les tests, vérifier
les logs, démontrer la correction. Ce qui se voit se **regarde** : un PDF se génère et se lit, un écran
s'ouvre dans le navigateur. « Un staff engineer approuverait-il cela ? »

**Ne jamais modifier l'arbre de travail pour prouver qu'un contrôle voit une régression** : le serveur
de développement tourne sur cet arbre et recompile à la requête suivante. Simuler la régression dans le
navigateur (une règle CSS injectée), pas dans le dépôt.

## Stack Technique

- **Ruby 3.4.11** / **Rails 8.1** (`load_defaults 8.1`)
- **PostgreSQL**
- **Propshaft** + **Dart Sass** (cssbundling, `bin/build-css`) — nos feuilles sont des modules (`@use`)
- **esbuild** (jsbundling) sous **Node 24** + yarn ; **Turbo 8** + **Stimulus**
- **TipTap 3** pour l'éditeur d'énoncé, enregistré au format ActionText (`app/javascript/editeur/`)
- **ViewComponent 4** — les composants partagés sous `Ui::`
- **Devise** (+ invitable, last_seen), **Pretender**, **Pundit**
- **Solid Queue** (dans Puma en production) et **Solid Cache**
- **Ferrum** (Chrome headless) pour les PDF : `app/modules/pdf_generator/`
- **Cloudinary** pour ActiveStorage, **Stripe** pour l'abonnement, **Brevo** pour les mails,
  **rails_admin** pour le back-office
- **RSpec** + **FactoryBot** ; bancs navigateur Ferrum dans `scripts/*_browser_check.rb`
- **Docker** → VPS OVH piloté par **Coolify v4**

## Commandes de Développement

```bash
bin/setup                    # dépendances + setup BDD
bin/dev                      # web, jobs, JS et CSS en veille (Procfile.dev)
bundle exec rspec            # suite RSpec
bundle exec rubocop          # lint Ruby
yarn build && yarn build:css # bundles JS et CSS (Node 24)
bin/ci                       # toute la CI locale, puis la signature GitHub
```

## Conventions de Code

### Couleurs — jamais en dur

**Toute couleur vient de la palette** `app/assets/stylesheets/config/_colors.scss` (`colors.$grisF`,
`colors.$belt-2`, `colors.$belt-pastilles`…). Jamais un hexadécimal, un `rgb()` ou un nom de couleur
dans une vue, un composant, une feuille de page ou un `<style>` ERB. Une teinte qui manque s'ajoute à la
palette, **nommée et commentée** (à quoi elle sert, pourquoi pas une autre).

Corollaire : **pas de `<style>` dans une vue**, qui ne voit pas la palette. La mise en page d'un PDF
vit dans une feuille chargée par `pdf.scss` (ex. `pdf_belt_sheets/_fiche.scss`), rangée sous la classe
racine de son gabarit — `pdf.scss` est lu par tous les PDF.

Les couleurs en dur déjà présentes sont un héritage : on les passe à la palette quand on touche la
feuille, pas avant.

### Reprendre le design system

- Un écran « comme X » **reprend le balisage de X** — ses partiels, ses composants, ses classes, l'ordre
  de ses colonnes — jamais une réécriture à la main ni un style inventé
- Boutons : `Ui::ButtonComponent` ; onglets : `Ui::TabsComponent` ; page : `Ui::PageComponent` ;
  étiquette : `Ui::TagComponent` ; nom de classe : `Classrooms::TitleComponent`
- Un ViewComponent dédié plutôt qu'un helper
- **Montrer plutôt qu'expliquer** : un aperçu vaut mieux qu'une carte explicative ou des boutons radio

### J'imprime ce que je vois

L'éditeur, l'affichage et le PDF montrent **la même chose**. Pas de règle propre au PDF qui change ce
que la professeur·e a vu dans l'éditeur ; pas de ligne, de marge ou de cadre dans l'éditeur qui
n'existe pas à l'impression — ou alors seulement là où est le curseur.

### Migrations

- Backfill **en boucle Ruby** (`find_each` + `update_column`), **jamais d'`execute` SQL**
- Schema-change et backfill séparés
- Toute migration à passer en production est **signalée dans la PR**

### Policies Pundit

- `authorize` sur chaque ressource ; le droit vit dans la policy, pas dans la vue
- Une classe : ses professeur·es et ceux à qui on la partage. Le partage d'un plan ou d'une fiche
  partage le contenu, **jamais l'élève**
- Toute nouvelle page passe par la spec de cloisonnement

### Mobile

**Édition en direct** : pas de formulaire ni de bouton Valider. Un appui = un enregistrement, l'état
voulu, la ligne redessinée en place.

### Commentaires

Un commentaire dit **pourquoi**, jamais ce que fait la ligne suivante. Il nomme la cause qui a imposé
le code (« sans ça, … ») — c'est elle qui empêche de le défaire.

## Pièges déjà rencontrés

- **Le compte Cloudinary est partagé entre dev et prod**, et la base de dev est une copie de la prod :
  supprimer une pièce jointe en développement effaçait le fichier de production.
  `config/initializers/cloudinary_dev_sans_suppression.rb` ignore ces suppressions en développement —
  ne jamais le contourner.
- **`assets:clobber` supprime aussi le bundle construit** : l'app se retrouve sans aucun JS. Relancer
  `yarn build && yarn build:css`.
- **Un serveur démarré avant une migration** ignore la nouvelle colonne au `SET`, sans exception.
  Redémarrer le serveur après `db:migrate`.
- **Un module ES ne se rejoue pas à la visite Turbo suivante**, et `turbo:load` est déjà passé à sa
  première exécution : brancher le code sur un contrôleur Stimulus, pas sur le chargement du module.
- **`layout "mobile"` sur une requête de cadre** rend deux cadres `general_modal` : rien ne s'ouvre.
- **`params.expect` n'est pas `permit`** : il lève sur une forme inattendue au lieu de filtrer.
- **acts_as_list** : changer le scope laisse un trou dans les positions et écrase celle d'un `dup` ;
  un `.sort` sur des enregistrements trie par id, pas par position (concern `Positionable`).
- **`only:` est ignoré sur `after_validation`** ; un effet de bord de validation se range ailleurs.
- **Le raccourci CSS `border` réécrit `border-color`** : avec une spécificité plus forte, il écrase la
  couleur d'une classe de variante. Poser `border-width` et `border-style` séparément.
- **Le port 3000 peut servir une autre app** : lire le `<title>` avant de conclure ; Ensemble tourne
  volontiers sur 3001.

## Tests

- **RSpec** : specs de requête par défaut, specs de vue pour les gabarits PDF (sans lancer Chrome),
  specs de composant pour `Ui::`
- **Pièges des factories** : `:user` crée un **admin** par défaut ; `:grade` et `:domain` tirent un nom
  au hasard (collision une fois sur cinq à neuf) ; `:classroom` peut appartenir à une autre école ;
  les partages exigent un admin ; l'abonnement plafonne le nombre de classes
- **Jamais de `before(:all)`** : la suite échouait une fois sur deux
- La spec fumée ouvre toutes les pages ; la spec de cloisonnement les ouvre avec l'école d'à côté
- **Les bancs navigateur (`scripts/`) sont la seule couverture du JavaScript** : ils pilotent Chrome
  par Ferrum, sans réseau. Un banc qui touche la prod est un bug

## CI, commits et PR

- **`bin/ci` tourne en local** (RuboCop, bundler-audit, Brakeman, builds, RSpec, bancs), puis signe
  le commit sur GitHub (`gh signoff`). `main` exige cette signature, admins compris : lancer `bin/ci`
  **après** le push, dans un arbre propre ; tout nouveau commit poussé est à re-signer
- **Commits en français**, conventional commits (`fix(ceintures): …`) ; le corps explique la **cause**,
  pas la liste des fichiers. **Aucune ligne `Co-Authored-By` ni mention de Claude**, ni dans les
  commits ni dans les PR
- **Ne rien pousser, ouvrir ni merger sans qu'on le demande** ; le merge et le déploiement restent à
  la main du mainteneur
- Les bugs croisés en route se signalent dans la PR ; un bug simple se corrige juste après, dans sa
  propre PR

## Déploiement

VPS OVH + **Coolify v4** (Docker, Traefik en frontal) — même chaîne que Wishes et CineClub.

- Une seule ressource : Puma, avec Solid Queue dedans (`SOLID_QUEUE_IN_PUMA`)
- Les PDF parlent à un Chrome distant (`CHROME_URL`) en production, à un Chrome local en développement
- Health check sur `/up`
