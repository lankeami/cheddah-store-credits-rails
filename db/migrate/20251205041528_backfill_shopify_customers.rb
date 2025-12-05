class BackfillShopifyCustomers < ActiveRecord::Migration[7.1]
  def up
    # Backfill shopify_customers table from existing store_credits data
    # Group by shop_id, email, and shopify_customer_id_legacy to find unique customers

    execute <<-SQL
      INSERT INTO shopify_customers (shop_id, email, shopify_customer_id, created_at, updated_at)
      SELECT DISTINCT
        sc.shop_id,
        sc.email,
        sc.shopify_customer_id_legacy,
        NOW(),
        NOW()
      FROM store_credits sc
      WHERE sc.shopify_customer_id_legacy IS NOT NULL
      ON DUPLICATE KEY UPDATE updated_at = NOW()
    SQL

    # Now update store_credits to reference the shopify_customers table
    execute <<-SQL
      UPDATE store_credits sc
      INNER JOIN shopify_customers cust
        ON sc.shop_id = cust.shop_id
        AND sc.email = cust.email
      SET sc.shopify_customer_id = cust.id
      WHERE sc.shopify_customer_id_legacy IS NOT NULL
    SQL
  end

  def down
    # Clear the foreign keys
    execute "UPDATE store_credits SET shopify_customer_id = NULL"

    # Clear the shopify_customers table
    execute "DELETE FROM shopify_customers"
  end
end
