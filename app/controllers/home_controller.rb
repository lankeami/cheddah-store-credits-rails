class HomeController < ApplicationController
  def index
    @shop = Shop.find_by(shopify_domain: current_shopify_domain)
    @products_count = fetch_products_count if @shop
  end

  private

  def fetch_products_count
    session = ShopifyAPI::Auth::Session.new(
      shop: @shop.shopify_domain,
      access_token: @shop.shopify_token
    )

    ShopifyAPI::Product.count(session: session)
  rescue => e
    Rails.logger.error "Error fetching products: #{e.message}"
    0
  end
end
