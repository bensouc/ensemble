require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ensemble
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.active_support.cache_format_version = 7.1
    config.i18n.default_locale = :fr
    # Configuration for the application, engines, and railties goes here.
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
    Rails.application.config.active_storage.variant_processor = :vips
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
