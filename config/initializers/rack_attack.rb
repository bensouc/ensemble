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
  # Compteurs throttle/fail2ban dans Redis (cohérents entre workers Puma).
  # Le blocklist par chemin ci-dessous ne dépend PAS du cache : il fonctionne
  # même si Redis est indisponible (degradation gracieuse).
  if ENV["REDIS_URL"].present?
    self.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV["REDIS_URL"],
      namespace: "rack_attack",
      error_handler: ->(method:, returning:, exception:) do
        Rails.logger.warn("[rack-attack] cache indisponible: #{exception.class}")
      end
    )
  end

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

  blocklist("bots: chemins de scan") { |req| BAD_PATHS.match?(req.path) }

  # Fail2ban applicatif : une IP qui touche 3 mauvais chemins en 1 min est
  # bannie 1 h (toutes ses requêtes -> 403, y compris légitimes).
  blocklist("fail2ban: scanners") do |req|
    Rack::Attack::Fail2Ban.filter("scan-#{req.ip}", maxretry: 3, findtime: 60, bantime: 3600) do
      BAD_PATHS.match?(req.path)
    end
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