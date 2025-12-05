namespace :store_credits do
  desc "Backfill shopify_customers table and link store credits"
  task backfill_customer_ids: :environment do
    puts 'Backfilling customer mapping for existing store credits...'

    Shop.find_each do |shop|
      puts "\nProcessing shop: #{shop.shopify_domain}"

      # Get credits without shopify_customer relationship
      credits = shop.store_credits.where(shopify_customer_id: nil)

      next if credits.empty?

      puts "  Found #{credits.count} credits without customer mapping"

      service = ShopifyStoreCreditService.new(shop)
      updated_count = 0
      failed_count = 0

      credits.each do |credit|
        begin
          # Find or create shopify_customer record
          customer = service.find_customer_by_email(credit.email)

          if customer
            customer_gid = customer['id']
            customer_id = service.send(:extract_gid, customer_gid)

            # Find or create ShopifyCustomer record
            shopify_customer = ShopifyCustomer.find_or_create_from_shopify(
              shop: shop,
              email: credit.email,
              shopify_customer_id: customer_id
            )

            # Link the credit to the customer
            credit.update_columns(
              shopify_customer_id: shopify_customer.id,
              shopify_customer_id_legacy: customer_id
            )

            updated_count += 1
            puts "  ✓ Updated credit ##{credit.id} for #{credit.email}: customer_id=#{customer_id}"
          else
            failed_count += 1
            puts "  ✗ Customer not found for #{credit.email}"
          end

          # Small delay to avoid rate limits
          sleep(0.2)
        rescue => e
          failed_count += 1
          puts "  ✗ Error processing credit ##{credit.id}: #{e.message}"
        end
      end

      puts "  Summary: #{updated_count} updated, #{failed_count} failed"
    end

    puts "\nDone!"
  end
end
