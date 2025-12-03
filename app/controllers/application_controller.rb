class ApplicationController < ShopifyApp::AuthenticatedController
  protect_from_forgery with: :exception, unless: :embedded_shopify_app?

  private

  def embedded_shopify_app?
    # Skip CSRF for embedded Shopify requests with JWT token
    params[:embedded].present? && params[:id_token].present?
  end
end
