namespace :shop do
  desc "Sync shop data for all shops from Shopify API"
  task sync_all: :environment do
    puts "Starting shop data sync for all shops..."
    SyncAllShopsDataJob.perform_now
    puts "Shop data sync completed!"
  end

  desc "Sync shop data for a specific shop"
  task :sync, [:shop_domain] => :environment do |t, args|
    if args[:shop_domain].blank?
      puts "Usage: rake shop:sync[shop-name.myshopify.com]"
      exit 1
    end

    shop = Shop.find_by(shopify_domain: args[:shop_domain])
    if shop
      puts "Syncing data for #{args[:shop_domain]}..."
      SyncShopDataJob.perform_now(shop_domain: args[:shop_domain])
      puts "Sync completed!"
    else
      puts "Shop not found: #{args[:shop_domain]}"
      exit 1
    end
  end
end
