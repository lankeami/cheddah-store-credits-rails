class SyncShopDataJob < ActiveJob::Base
  queue_as :default

  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    return unless shop

    shop.sync_shop_data
    Rails.logger.info("Successfully synced shop data for #{shop_domain}")

    # Register webhooks after installation
    shop.register_webhooks
    Rails.logger.info("Successfully registered webhooks for #{shop_domain}")
  rescue => e
    Rails.logger.error("SyncShopDataJob failed for #{shop_domain}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
