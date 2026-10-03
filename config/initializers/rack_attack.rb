# frozen_string_literal: true
#
# Rack::Attack — protège l'app contre :
#   • les scanners de bots (WordPress / PHP / shells) qui spamment les logs
#   • le brute-force sur le login Devise (pas de :lockable)
#
# Placé EN TÊTE de la pile middleware (avant Rails::Rack::Logger) : une requête
# bloquée renvoie 403/429 immédiatement et ne génère AUCUNE ligne de log.

# N'agit qu'en production (laisse le dev + la suite RSpec tranquilles).
# staging.app-ensemble.fr tourne aussi en RAILS_ENV=production -> couvert.
Rack::Attack.enabled = Rails.env.production?

class Rack::Attack
  # Compteurs throttle/fail2ban dans Rails.cache, soit Solid Cache en production
  # (config/cache.yml) : en base, partagés par tous les processus, et conservés
  # d'un redéploiement à l'autre. Ils vivaient dans Redis, qui n'est plus là.
  # Le blocklist par chemin ci-dessous ne dépend PAS du cache.
  self.cache.store = Rails.cache

  # Chemins de scanners : n'existent jamais dans une app Rails -> 403 silencieux.
  BAD_PATHS = Regexp.union(
    %r{\.(php|phtml|asp|aspx|jsp|cgi)(/|$)}i, # *.php, *.asp, *.jsp...
    %r{^/wp[-/]}i,                            # /wp-admin, /wp-content, /wp-login
    %r{^/wordpress}i,
    %r{^/xmlrpc}i,
    %r{^/(wso|shell|alfa|c99|r57|cmd)\b}i,    # web shells courants
    %r{^/\.(env|git|aws|ssh)}i,               # /.env, /.git, /.aws...
    %r{^/(phpmyadmin|pma|adminer|cgi-bin|vendor)\b}i
  )

  # Fail2ban applicatif : une IP qui touche 3 mauvais chemins en 1 min est
  # bannie 1 h (toutes ses requêtes -> 403, y compris légitimes).
  #
  # EN PREMIER : Rack::Attack s'arrête à la première liste de blocage qui répond
  # (`blocklisted?` fait un `any?`). Déclaré après les deux suivantes, ce filtre
  # n'était jamais atteint sur les chemins qu'elles bloquent déjà, et le
  # bannissement n'avait jamais lieu. Il bloque lui-même chaque mauvaise
  # requête (403) en la comptant ; les deux suivantes restent en filet.
  #
  # `req.ip` est bien l'adresse du client derrière Traefik : Rack tient les
  # adresses privées du proxy pour fiables et lit X-Forwarded-For. Sans quoi un
  # seul scanner ferait bannir tout le monde.
  blocklist("fail2ban: scanners") do |req|
    Rack::Attack::Fail2Ban.filter("scan-#{req.ip}", maxretry: 3, findtime: 60, bantime: 3600) do
      BAD_PATHS.match?(req.path) || req.get_header("HTTP_NEXT_ACTION").present?
    end
  end

  blocklist("bots: chemins de scan") { |req| BAD_PATHS.match?(req.path) }

  # Sondes Next.js Server Actions : l'en-tête "Next-Action" (env HTTP_NEXT_ACTION)
  # n'a aucun sens sur une app Rails. Ces requêtes multipart malformées faisaient
  # planter exception_notification -> 403 silencieux.
  blocklist("bots: sondes Next-Action") do |req|
    req.get_header("HTTP_NEXT_ACTION").present?
  end

  # Anti brute-force login Devise — par IP et par email visé.
  throttle("login/ip", limit: 8, period: 60) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end
  throttle("login/email", limit: 8, period: 60) do |req|
    if req.post? && req.path == "/users/sign_in"
      req.params.dig("user", "email").to_s.downcase.presence
    end
  end

  # Garde-fou anti-flood général (hors assets / websocket / healthcheck).
  throttle("req/ip", limit: 300, period: 60) do |req|
    req.ip unless req.path.start_with?("/assets", "/cable", "/up")
  end
end

# Relocalise Rack::Attack tout en tête : le railtie l'ajoute en FIN de pile,
# on le déplace AVANT le logger pour que les requêtes bloquées soient muettes.
# (move_before déplace l'instance existante ; un delete + insert_before échoue
#  car Rails applique `delete` en dernier et retire TOUTES les occurrences.)
Rails.application.config.middleware.move_before(0, Rack::Attack)