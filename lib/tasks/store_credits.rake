namespace :store_credits do
  desc "Remove expired store credits"
  task cleanup_expired: :environment do
    puts "Cleaning up expired store credits..."
    count = StoreCredit.expired.count
    puts "Found #{count} expired credits"

    StoreCredit.expired.destroy_all
    puts "Successfully removed #{count} expired store credits"
  end

  desc "Process pending store credits for all shops"
  task process_all: :environment do
    puts "Processing pending store credits for all shops..."

    total_queued = 0

    Shop.find_each do |shop|
      pending_count = shop.store_credits.pending.where('expires_at > ?', Time.current).count
      next if pending_count.zero?

      puts "Processing #{pending_count} credits for #{shop.shopify_domain}"
      ProcessStoreCreditsJob.perform_later(shop_domain: shop.shopify_domain)
      total_queued += pending_count
    end

    puts "Done! Queued #{total_queued} credits for processing"
  end

  desc "Process pending store credits for a specific shop NOW (synchronous)"
  task :process_shop, [:shop_domain] => :environment do |t, args|
    if args[:shop_domain].blank?
      puts "Usage: rake store_credits:process_shop[shop-name.myshopify.com]"
      exit 1
    end

    shop = Shop.find_by(shopify_domain: args[:shop_domain])
    unless shop
      puts "Shop not found: #{args[:shop_domain]}"
      exit 1
    end

    puts "Processing credits for #{args[:shop_domain]}..."
    result = ProcessStoreCreditsJob.perform_now(shop_domain: args[:shop_domain])
    puts "Results: #{result[:success]} succeeded, #{result[:failure]} failed"
  end

  desc "Show store credits statistics"
  task stats: :environment do
    puts "\nStore Credits Statistics"
    puts "=" * 50

    Shop.find_each do |shop|
      credits = shop.store_credits
      next if credits.empty?

      puts "\n#{shop.shopify_domain}:"
      puts "  Total: #{credits.count}"
      puts "  Pending: #{credits.pending.count}"
      puts "  Completed: #{credits.completed.count}"
      puts "  Failed: #{credits.failed.count}"
      puts "  Expired: #{credits.expired.count}"
    end

    puts "\n" + "=" * 50
    puts "Overall Totals:"
    puts "  Total: #{StoreCredit.count}"
    puts "  Pending: #{StoreCredit.pending.count}"
    puts "  Completed: #{StoreCredit.completed.count}"
    puts "  Failed: #{StoreCredit.failed.count}"
    puts "  Expired: #{StoreCredit.expired.count}"
  end
end
