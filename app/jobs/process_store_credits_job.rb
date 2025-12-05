class ProcessStoreCreditsJob < ActiveJob::Base
  queue_as :default

  def perform(shop_domain:, limit: 50)
    shop = Shop.find_by(shopify_domain: shop_domain)
    unless shop
      Rails.logger.error("Shop not found: #{shop_domain}")
      return
    end

    # Get pending credits that haven't expired
    credits = shop.store_credits
                  .pending
                  .where('expires_at > ?', Time.current)
                  .limit(limit)

    return if credits.empty?

    Rails.logger.info("Processing #{credits.count} store credits for #{shop_domain}")

    service = ShopifyStoreCreditService.new(shop)
    success_count = 0
    failure_count = 0

    credits.each do |credit|
      begin
        credit.mark_as_processing!

        # Build note with campaign info if available
        note = if credit.campaign
          "Campaign: #{credit.campaign.name} - Expires #{credit.expires_at.strftime('%Y-%m-%d')}"
        else
          "Store credit - Expires #{credit.expires_at.strftime('%Y-%m-%d')}"
        end

        # Use create_customer_and_credit to handle both new and existing customers
        result = service.create_customer_and_credit(
          email: credit.email,
          amount: credit.amount,
          expires_at: credit.expires_at,
          note: note,
          campaign_name: credit.campaign&.name
        )

        if result[:success]
          credit.mark_as_completed!(result[:credit_id], result[:customer_id])
          success_count += 1
          Rails.logger.info("✓ Created credit for #{credit.email}: $#{credit.amount}")
        else
          credit.mark_as_failed!(result[:error], result[:customer_id])
          failure_count += 1
          Rails.logger.warn("✗ Failed credit for #{credit.email}: #{result[:error]}")
        end

        # Small delay to avoid rate limits
        sleep(0.5)

      rescue => e
        credit.mark_as_failed!(e.message)
        failure_count += 1
        Rails.logger.error("✗ Exception processing credit #{credit.id}: #{e.message}")
      end
    end

    Rails.logger.info("Completed processing for #{shop_domain}: #{success_count} succeeded, #{failure_count} failed")

    {
      shop: shop_domain,
      total: credits.count,
      success: success_count,
      failure: failure_count
    }
  end
end
