require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ensemble
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.active_support.cache_format_version = 7.0
    config.i18n.default_locale = :fr
    config.active_record.legacy_connection_handling = false
    # Configuration for the application, engines, and railties goes here.
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
    Rails.application.config.active_storage.variant_processor = :mini_magick


    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
