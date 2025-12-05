class CreateShopifyCustomers < ActiveRecord::Migration[7.1]
  def up
    create_table :shopify_customers do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :email, null: false
      t.string :shopify_customer_id, null: false

      t.timestamps
    end

    # Add unique index to prevent duplicate customer records
    add_index :shopify_customers, [:shop_id, :email], unique: true
    add_index :shopify_customers, [:shop_id, :shopify_customer_id], unique: true

    # Rename the old shopify_customer_id column to shopify_customer_id_legacy
    rename_column :store_credits, :shopify_customer_id, :shopify_customer_id_legacy

    # Add foreign key from store_credits to shopify_customers table
    add_reference :store_credits, :shopify_customer, foreign_key: true
  end

  def down
    remove_reference :store_credits, :shopify_customer, foreign_key: true
    rename_column :store_credits, :shopify_customer_id_legacy, :shopify_customer_id
    remove_index :shopify_customers, [:shop_id, :shopify_customer_id]
    remove_index :shopify_customers, [:shop_id, :email]
    drop_table :shopify_customers
  end
end
