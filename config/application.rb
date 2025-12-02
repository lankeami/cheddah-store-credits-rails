require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module CheddahRails
  class Application < Rails::Application
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties goes here.
    config.autoload_lib(ignore: %w(assets tasks))

    # Shopify embedded app configuration
    config.action_controller.forgery_protection_origin_check = false

    # Force HTTPS URL generation
    config.action_controller.default_url_options = { protocol: 'https' }
    config.action_mailer.default_url_options = { protocol: 'https' }
  end
end
