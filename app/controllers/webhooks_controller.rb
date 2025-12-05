class WebhooksController < ApplicationController
  # Skip CSRF verification for webhooks
  skip_before_action :verify_authenticity_token

  # Skip Shopify authentication for webhooks (they use HMAC verification)
  skip_before_action :login_again_if_different_shop, raise: false
  skip_before_action :check_shop_known, raise: false
  skip_before_action :verify_shopify_session, raise: false

  before_action :verify_webhook

  # GDPR: Customer Data Request
  # Triggered when a customer requests their data (GDPR Article 15 - Right of Access)
  # You have 30 days to provide the data
  def customers_data_request
    shop_domain = webhook_params[:shop_domain]
    customer_email = webhook_params.dig(:customer, :email)

    Rails.logger.info("Customer data request received for #{customer_email} from #{shop_domain}")

    # Find all data for this customer
    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop
      store_credits = shop.store_credits.where(email: customer_email)
      shopify_customer = shop.shopify_customers.find_by(email: customer_email)

      data = {
        customer_email: customer_email,
        store_credits: store_credits.as_json(only: [:id, :email, :amount, :status, :expires_at, :created_at, :processed_at]),
        shopify_customer: shopify_customer&.as_json(only: [:email, :shopify_customer_id, :created_at])
      }

      # In production, you should email this data to the customer or shop owner
      Rails.logger.info("Customer data: #{data.to_json}")
    end

    head :ok
  end

  # GDPR: Customer Redact
  # Triggered 48 hours after a customer is deleted from a shop
  # You must delete or anonymize customer PII within 30 days
  def customers_redact
    shop_domain = webhook_params[:shop_domain]
    customer_email = webhook_params.dig(:customer, :email)
    customer_id = webhook_params.dig(:customer, :id)

    Rails.logger.info("Customer redaction request for #{customer_email} (ID: #{customer_id}) from #{shop_domain}")

    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop
      # Anonymize or delete customer data
      # Option 1: Anonymize by removing PII but keeping records for reporting
      shop.store_credits.where(email: customer_email).update_all(
        email: "deleted_customer_#{customer_id}@redacted.com"
      )

      # Option 2: Delete the customer mapping
      shopify_customer = shop.shopify_customers.find_by(email: customer_email)
      shopify_customer&.destroy

      Rails.logger.info("Customer data redacted for #{customer_email}")
    end

    head :ok
  end

  # App Uninstalled
  # Triggered immediately when a shop uninstalls your app
  # This fires BEFORE the shop/redact webhook (which comes later for GDPR compliance)
  def app_uninstalled
    shop_domain = webhook_params[:shop_domain] || webhook_params[:domain]

    Rails.logger.info("App uninstalled for #{shop_domain}")

    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop
      # Mark the shop as uninstalled (but don't delete data yet - wait for shop/redact)
      # You could add an uninstalled_at column to track this
      Rails.logger.info("App uninstalled notification received for: #{shop_domain}")

      # Optional: Send notification email, update analytics, etc.
    end

    head :ok
  end

  # GDPR: Shop Redact
  # Triggered when a shop uninstalls your app
  # You must delete shop data within 48 hours
  def shop_redact
    shop_domain = webhook_params[:shop_domain]

    Rails.logger.info("Shop redaction request for #{shop_domain}")

    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop
      # Delete all associated data
      shop.store_credits.destroy_all
      shop.shopify_customers.destroy_all
      shop.campaigns.destroy_all

      # Option 1: Delete the shop entirely
      shop.destroy

      # Option 2: Mark as uninstalled but keep for audit trail
      # shop.update(uninstalled_at: Time.current)

      Rails.logger.info("Shop data deleted for #{shop_domain}")
    end

    head :ok
  end

  private

  def verify_webhook
    # Verify the webhook came from Shopify using HMAC
    hmac_header = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']

    unless hmac_header
      Rails.logger.error("Missing HMAC header in webhook request")
      head :unauthorized
      return
    end

    # Get the raw request body
    data = request.body.read
    request.body.rewind

    # Calculate expected HMAC
    api_secret = ENV['SHOPIFY_API_SECRET']
    calculated_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', api_secret, data)
    )

    unless ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
      Rails.logger.error("Invalid HMAC signature in webhook request")
      head :unauthorized
      return
    end
  end

  def webhook_params
    @webhook_params ||= JSON.parse(request.body.read).with_indifferent_access
  rescue JSON::ParserError
    {}
  ensure
    request.body.rewind
  end
end
