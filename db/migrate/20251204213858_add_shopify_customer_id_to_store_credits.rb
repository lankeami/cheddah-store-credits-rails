class AddShopifyCustomerIdToStoreCredits < ActiveRecord::Migration[7.1]
  def change
    add_column :store_credits, :shopify_customer_id, :string
  end
end
