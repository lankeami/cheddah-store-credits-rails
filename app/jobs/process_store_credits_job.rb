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

        result = service.create_store_credit(
          email: credit.email,
          amount: credit.amount,
          expires_at: credit.expires_at,
          note: "Store credit - expires #{credit.expires_at.strftime('%Y-%m-%d')}"
        )

        if result[:success]
          credit.mark_as_completed!(result[:credit_id])
          success_count += 1
          Rails.logger.info("✓ Created credit for #{credit.email}: $#{credit.amount}")
        else
          credit.mark_as_failed!(result[:error])
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
