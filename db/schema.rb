# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_04_213858) do
  create_table "campaigns", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "name"], name: "index_campaigns_on_shop_id_and_name", unique: true
    t.index ["shop_id"], name: "index_campaigns_on_shop_id"
  end

  create_table "shops", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.string "access_scopes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "email"
    t.string "domain"
    t.string "phone"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "province"
    t.string "province_code"
    t.string "country"
    t.string "country_code"
    t.string "country_name"
    t.string "zip"
    t.string "currency"
    t.string "timezone"
    t.string "iana_timezone"
    t.string "shop_owner"
    t.string "money_format"
    t.string "money_with_currency_format"
    t.string "weight_unit"
    t.string "plan_name"
    t.string "plan_display_name"
    t.string "primary_locale"
    t.text "enabled_presentment_currencies"
    t.boolean "tax_shipping"
    t.boolean "taxes_included"
    t.boolean "has_storefront"
    t.boolean "has_discounts"
    t.boolean "setup_required"
    t.boolean "pre_launch_enabled"
    t.string "customer_email"
    t.string "myshopify_domain"
    t.datetime "created_at_shopify"
    t.datetime "updated_at_shopify"
    t.boolean "checkout_api_supported"
    t.boolean "multi_location_enabled"
    t.boolean "force_ssl"
    t.boolean "password_enabled"
    t.boolean "eligible_for_payments"
    t.boolean "requires_extra_payments_agreement"
    t.boolean "eligible_for_card_reader_giveaway"
    t.boolean "finances"
    t.boolean "marketing_sms_consent_enabled_at_checkout"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "store_credits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "email", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "expiry_hours", null: false
    t.datetime "expires_at"
    t.string "status", default: "pending", null: false
    t.string "shopify_credit_id"
    t.text "error_message"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "campaign_id"
    t.string "shopify_customer_id"
    t.index ["campaign_id", "status"], name: "index_store_credits_on_campaign_id_and_status"
    t.index ["campaign_id"], name: "index_store_credits_on_campaign_id"
    t.index ["expires_at"], name: "index_store_credits_on_expires_at"
    t.index ["shop_id", "email"], name: "index_store_credits_on_shop_id_and_email"
    t.index ["shop_id"], name: "index_store_credits_on_shop_id"
    t.index ["status"], name: "index_store_credits_on_status"
  end

  add_foreign_key "campaigns", "shops"
  add_foreign_key "store_credits", "campaigns"
  add_foreign_key "store_credits", "shops"
end
