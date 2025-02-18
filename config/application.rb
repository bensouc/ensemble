require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ensemble
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.active_support.cache_format_version = 7.0
    config.i18n.default_locale = :fr
    # config.active_record.legacy_connection_handling = false
    # Configuration for the application, engines, and railties goes here.
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
    Rails.application.config.active_storage.variant_processor = :mini_magick
    # config.active_storage.replace_on_assign_to_many = true
    # config.active_job.queue_adapter = :solid_queue

    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Paris"
    config.active_record.default_timezone = :local
    # CONFIG LOGRAGE
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new

    # Configure Zeitwerk to ignore node_modules
    config.autoload_paths -= [Rails.root.join('node_modules').to_s]
    config.eager_load_paths -= [Rails.root.join('node_modules').to_s]


    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
