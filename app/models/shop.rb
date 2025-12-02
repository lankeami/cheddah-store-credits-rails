class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  serialize :enabled_presentment_currencies, type: Array, coder: JSON

  validates :shopify_domain, presence: true, uniqueness: true

  def api_version
    ShopifyApp.configuration.api_version
  end

  def sync_shop_data
    with_shopify_session do |session|
      shop_data = ShopifyAPI::Shop.current(session: session)

      update(
        name: shop_data.name,
        email: shop_data.email,
        domain: shop_data.domain,
        phone: shop_data.phone,
        address1: shop_data.address1,
        address2: shop_data.address2,
        city: shop_data.city,
        province: shop_data.province,
        province_code: shop_data.province_code,
        country: shop_data.country,
        country_code: shop_data.country_code,
        country_name: shop_data.country_name,
        zip: shop_data.zip,
        currency: shop_data.currency,
        timezone: shop_data.timezone,
        iana_timezone: shop_data.iana_timezone,
        shop_owner: shop_data.shop_owner,
        money_format: shop_data.money_format,
        money_with_currency_format: shop_data.money_with_currency_format,
        weight_unit: shop_data.weight_unit,
        plan_name: shop_data.plan_name,
        plan_display_name: shop_data.plan_display_name,
        primary_locale: shop_data.primary_locale,
        enabled_presentment_currencies: shop_data.enabled_presentment_currencies,
        tax_shipping: shop_data.tax_shipping,
        taxes_included: shop_data.taxes_included,
        has_storefront: shop_data.has_storefront,
        has_discounts: shop_data.has_discounts,
        setup_required: shop_data.setup_required,
        pre_launch_enabled: shop_data.pre_launch_enabled,
        customer_email: shop_data.customer_email,
        myshopify_domain: shop_data.myshopify_domain,
        created_at_shopify: shop_data.created_at,
        updated_at_shopify: shop_data.updated_at,
        checkout_api_supported: shop_data.checkout_api_supported,
        multi_location_enabled: shop_data.multi_location_enabled,
        force_ssl: shop_data.force_ssl,
        password_enabled: shop_data.password_enabled,
        eligible_for_payments: shop_data.eligible_for_payments,
        requires_extra_payments_agreement: shop_data.requires_extra_payments_agreement,
        eligible_for_card_reader_giveaway: shop_data.eligible_for_card_reader_giveaway,
        finances: shop_data.finances,
        marketing_sms_consent_enabled_at_checkout: shop_data.marketing_sms_consent_enabled_at_checkout
      )
    end
  rescue => e
    Rails.logger.error("Failed to sync shop data for #{shopify_domain}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  private

  def with_shopify_session(&block)
    session = ShopifyAPI::Auth::Session.new(
      shop: shopify_domain,
      access_token: shopify_token
    )
    yield(session)
  end
end
