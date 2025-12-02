class AddCampaignToStoreCredits < ActiveRecord::Migration[7.1]
  def change
    add_reference :store_credits, :campaign, foreign_key: true, null: true
    add_index :store_credits, [:campaign_id, :status]
  end
end
