ShopifyApp.configure do |config|
  config.application_name = "Cheddah Rails App"
  config.api_key = ENV.fetch('SHOPIFY_API_KEY', '')
  config.secret = ENV.fetch('SHOPIFY_API_SECRET', '')
  config.scope = ENV.fetch('SCOPES', 'read_products,write_products')
  config.embedded_app = true
  config.after_authenticate_job = { job: "SyncShopDataJob", inline: false }
  config.api_version = "2024-10"
  config.shop_session_repository = 'Shop'
  config.reauth_on_access_scope_changes = true
  config.root_url = ENV.fetch('HOST', 'https://localhost:3000')
end
