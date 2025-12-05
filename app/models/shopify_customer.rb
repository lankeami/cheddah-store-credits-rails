class ShopifyCustomer < ActiveRecord::Base
  belongs_to :shop
  has_many :store_credits

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :shopify_customer_id, presence: true
  validates :email, uniqueness: { scope: :shop_id }
  validates :shopify_customer_id, uniqueness: { scope: :shop_id }

  # Find or create a customer mapping from Shopify API response
  def self.find_or_create_from_shopify(shop:, email:, shopify_customer_id:)
    find_or_create_by!(shop: shop, email: email) do |customer|
      customer.shopify_customer_id = shopify_customer_id
    end
  end

  # Generate Shopify admin customer URL
  def shopify_customer_url
    "https://#{shop.shopify_domain}/admin/customers/#{shopify_customer_id}"
  end
end
