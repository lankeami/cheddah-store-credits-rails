namespace :test do
  namespace :credits do
    desc "Run a quick test of store credits functionality"
    task :quick, [:email] => :environment do |t, args|
      email = args[:email] || "test@example.com"

      puts "\n" + "=" * 60
      puts "STORE CREDITS QUICK TEST"
      puts "=" * 60

      shop = Shop.first
      unless shop
        puts "❌ No shop found. Install app first."
        exit 1
      end

      puts "\n📍 Shop: #{shop.shopify_domain}"
      puts "🔑 Scopes: #{shop.access_scopes}"

      # Check customer exists
      puts "\n🔍 Checking if customer exists..."
      service = ShopifyStoreCreditService.new(shop)
      customer = service.find_customer_by_email(email)

      if customer
        puts "✓ Customer found: #{customer['displayName']} (#{customer['email']})"
      else
        puts "❌ Customer NOT found: #{email}"
        puts "   Create this customer in Shopify Admin first."
        exit 1
      end

      # Create test credit
      puts "\n💳 Creating test credit..."
      credit = shop.store_credits.create!(
        email: email,
        amount: 10.00,
        expiry_hours: 72
      )
      puts "✓ Credit created: ID ##{credit.id}"
      puts "  Amount: $#{credit.amount}"
      puts "  Expires: #{credit.expires_at.strftime('%Y-%m-%d %H:%M')}"

      # Process credit
      puts "\n⚡ Processing credit..."
      result = credit.process_now!

      if result[:success]
        puts "✓ SUCCESS! Credit applied to Shopify"
        puts "  Shopify Credit ID: #{result[:credit_id]}"
        puts "  Amount: $#{result[:amount]} #{result[:currency]}"
        puts "  Status: #{credit.reload.status}"
        puts "\n✅ TEST PASSED - Check customer in Shopify Admin"
      else
        puts "❌ FAILED to create credit"
        puts "  Error: #{result[:error]}"
        puts "  Status: #{credit.reload.status}"
        puts "\n❌ TEST FAILED"
      end

      puts "\n" + "=" * 60
    end

    desc "Test customer lookup"
    task :check_customer, [:email] => :environment do |t, args|
      email = args[:email] || "test@example.com"

      shop = Shop.first
      service = ShopifyStoreCreditService.new(shop)

      puts "\n🔍 Looking up customer: #{email}"
      customer = service.find_customer_by_email(email)

      if customer
        puts "✓ Found customer:"
        puts "  ID: #{customer['id']}"
        puts "  Email: #{customer['email']}"
        puts "  Name: #{customer['displayName']}"

        # Check credit balance
        balance = service.get_customer_credits(email)
        if balance
          puts "  Credit Balance: #{balance['value']} #{balance['currencyCode']}"
        end
      else
        puts "❌ Customer not found"
        puts "   Create customer in Shopify Admin:"
        puts "   https://#{shop.shopify_domain}/admin/customers"
      end
    end

    desc "Create sample credits for testing"
    task :create_samples, [:count] => :environment do |t, args|
      count = (args[:count] || 3).to_i
      shop = Shop.first

      puts "\n📝 Creating #{count} sample credits..."

      count.times do |i|
        credit = shop.store_credits.create!(
          email: "sample-#{i+1}@example.com",
          amount: (i + 1) * 10.0,
          expiry_hours: 72
        )
        puts "  #{i+1}. Created credit for $#{credit.amount} - ID ##{credit.id}"
      end

      puts "\n✓ Created #{count} sample credits"
      puts "  View with: make credits-stats"
      puts "  Process with: make credits-process-shop SHOP=#{shop.shopify_domain}"
    end

    desc "Show detailed status of all credits"
    task detailed_status: :environment do
      puts "\n" + "=" * 70
      puts "DETAILED STORE CREDITS STATUS"
      puts "=" * 70

      Shop.find_each do |shop|
        credits = shop.store_credits
        next if credits.empty?

        puts "\n📍 #{shop.shopify_domain}"
        puts "-" * 70

        credits.order(created_at: :desc).limit(10).each do |credit|
          status_icon = case credit.status
                        when 'pending' then '⏳'
                        when 'processing' then '⚡'
                        when 'completed' then '✅'
                        when 'failed' then '❌'
                        end

          puts "\n  #{status_icon} Credit ##{credit.id} - #{credit.status.upcase}"
          puts "     Email: #{credit.email}"
          puts "     Amount: $#{credit.amount}"
          puts "     Expires: #{credit.expires_at.strftime('%Y-%m-%d %H:%M')}"
          puts "     Created: #{credit.created_at.strftime('%Y-%m-%d %H:%M')}"

          if credit.completed?
            puts "     ✓ Shopify ID: #{credit.shopify_credit_id}"
            puts "     ✓ Processed: #{credit.processed_at.strftime('%Y-%m-%d %H:%M')}"
          elsif credit.failed?
            puts "     ✗ Error: #{credit.error_message}"
          end
        end
      end

      puts "\n" + "=" * 70
    end

    desc "Clean up test data"
    task :cleanup_test_data => :environment do
      puts "\n🧹 Cleaning up test credits..."

      # Delete credits with test emails
      test_credits = StoreCredit.where("email LIKE ? OR email LIKE ?", "test%", "sample%")
      count = test_credits.count

      if count > 0
        puts "Found #{count} test credits"
        print "Delete them? (y/N): "
        confirm = STDIN.gets.chomp

        if confirm.downcase == 'y'
          test_credits.destroy_all
          puts "✓ Deleted #{count} test credits"
        else
          puts "Cancelled"
        end
      else
        puts "No test credits found"
      end
    end
  end
end
