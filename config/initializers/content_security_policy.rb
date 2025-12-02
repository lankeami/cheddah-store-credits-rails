Rails.application.config.content_security_policy do |policy|
  policy.frame_ancestors :self, "https://*.myshopify.com", "https://admin.shopify.com"
end

Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
Rails.application.config.content_security_policy_nonce_directives = %w(script-src)
