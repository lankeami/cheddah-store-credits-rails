require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Allow ngrok and other development hosts
  config.hosts << "uninduced-dian-spongioblastic.ngrok-free.dev"
  config.hosts << ".ngrok-free.app"
  config.hosts << ".ngrok.io"

  # Force HTTPS for URL generation
  config.force_ssl = false
  config.action_controller.default_url_options = {
    protocol: 'https',
    host: ENV.fetch('HOST', 'localhost:3000').gsub('https://', '').gsub('http://', '')
  }

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_storage.service = :local
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.assets.quiet = true
  config.action_controller.raise_on_missing_callback_actions = true
end
