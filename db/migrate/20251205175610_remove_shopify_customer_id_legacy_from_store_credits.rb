class RemoveShopifyCustomerIdLegacyFromStoreCredits < ActiveRecord::Migration[7.1]
  def change
    remove_column :store_credits, :shopify_customer_id_legacy, :string
  end
end
