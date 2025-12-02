class CreateStoreCredits < ActiveRecord::Migration[7.1]
  def change
    create_table :store_credits do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :email, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :expiry_hours, null: false
      t.datetime :expires_at
      t.string :status, default: 'pending', null: false
      t.string :shopify_credit_id
      t.text :error_message
      t.datetime :processed_at
      t.timestamps
    end

    add_index :store_credits, [:shop_id, :email]
    add_index :store_credits, :status
    add_index :store_credits, :expires_at
  end
end
