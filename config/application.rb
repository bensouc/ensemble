require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ensemble
  class Application < Rails::Application
    # Les réglages par défaut de Rails 8.1. L'app n'en chargeait AUCUN jusqu'au
    # 03/10/2026 : elle tournait avec ceux d'avant Rails 5 — cookies chiffrés en
    # CBC et sans SameSite, origine des requêtes jamais comparée, un asset
    # introuvable changé en lien mort au lieu d'une erreur.
    #
    # De 7.2 à 8.1, rien de visible : une redirection vers un chemin relatif
    # (« dashboard » au lieu de « /dashboard ») lève au lieu d'être suivie, une
    # regex qui s'emballe s'arrête au bout d'une seconde, les champs cachés
    # perdent un `autocomplete="off"` invalide, le JSON rendu n'échappe plus
    # `<` ni `>`, YJIT s'allume en production (il l'était déjà par
    # RUBY_YJIT_ENABLE).
    config.load_defaults 8.1

    # Le seul réglage tenu à l'ancien comportement, et pour de bon. Changer la
    # clé de dérivation casserait tout ce qui est signé : sgid des
    # tableaux et images des exercices, URL Active Storage écrites dans les
    # textes, cookies. Comme une rotation de SECRET_KEY_BASE, il faudrait d'abord
    # re-signer les pièces jointes des textes.
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1

    config.i18n.default_locale = :fr
    # Jobs en base : tables solid_queue_* de la base principale (config/queue.yml).
    config.active_job.queue_adapter = :solid_queue
    # Tableau de bord des jobs (/jobs) : l'accès passe par Devise et la route
    # réservée aux admins, pas par l'authentification HTTP de la gem.
    config.mission_control.jobs.base_controller_class = "JobsDashboardController"
    config.mission_control.jobs.http_basic_auth_enabled = false
    # Le tableau de bord lit Solid Queue partout, y compris en test, où les jobs
    # restent sinon dans l'adaptateur :test, qu'il ne sait pas lire.
    config.mission_control.jobs.adapters = Set[:solid_queue]

    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Paris"
    config.active_record.default_timezone = :local
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
