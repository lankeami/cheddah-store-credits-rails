ShopifyAPI::Context.setup(
  api_key: ENV.fetch('SHOPIFY_API_KEY', ''),
  api_secret_key: ENV.fetch('SHOPIFY_API_SECRET', ''),
  host: ENV.fetch('HOST', 'https://localhost:3000'),
  scope: ENV.fetch('SCOPES', 'read_products,write_products'),
  is_embedded: true,
  api_version: '2024-10',
  is_private: false,
  user_agent_prefix: 'Cheddah Rails App'
)
