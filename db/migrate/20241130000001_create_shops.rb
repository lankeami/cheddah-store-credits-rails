class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.string :shopify_domain, null: false
      t.string :shopify_token, null: false
      t.string :access_scopes
      t.timestamps
    end

    add_index :shops, :shopify_domain, unique: true
  end
end
