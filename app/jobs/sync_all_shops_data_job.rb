class SyncAllShopsDataJob < ActiveJob::Base
  queue_as :default

  def perform
    Shop.find_each do |shop|
      SyncShopDataJob.perform_later(shop_domain: shop.shopify_domain)
    end

    Rails.logger.info("Queued sync jobs for #{Shop.count} shops")
  rescue => e
    Rails.logger.error("SyncAllShopsDataJob failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
