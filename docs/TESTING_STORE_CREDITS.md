# Testing Store Credits - Complete Guide

Step-by-step guide to test the store credits functionality.

## Prerequisites

Before testing, ensure:
1. ✅ You have a Shopify development store
2. ✅ App is installed in the dev store
3. ✅ App has customer read/write permissions
4. ✅ At least one customer exists in the store

## Quick Test Steps

### 1. Check Current Setup

```bash
# View your shop info
make console
```

```ruby
# In console
shop = Shop.first
puts "Shop: #{shop.shopify_domain}"
puts "Scopes: #{shop.access_scopes}"
# Should include: "read_customers,write_customers"
```

If scopes are missing, you need to reinstall the app.

### 2. Create a Test Customer (if needed)

**Option A: Via Shopify Admin**
1. Go to Customers in Shopify Admin
2. Add customer with email: `test@example.com`
3. Save

**Option B: Via Rails Console**
```ruby
shop = Shop.first
service = ShopifyStoreCreditService.new(shop)

# Check if customer exists
customer = service.find_customer_by_email("test@example.com")
puts customer.inspect

# If nil, create customer in Shopify Admin first
```

### 3. Create Test Credit

**Option A: Via CSV Upload**

1. Create `test_credits.csv`:
```csv
email,amount,expiry_hours
test@example.com,25.00,72
```

2. Upload via web UI at `/store_credits`

**Option B: Via Rails Console**
```ruby
shop = Shop.first
credit = shop.store_credits.create!(
  email: "test@example.com",
  amount: 25.00,
  expiry_hours: 72
)

puts "Created credit ##{credit.id}"
puts "Status: #{credit.status}"
puts "Expires: #{credit.expires_at}"
```

### 4. Process the Credit

**Option A: Process Immediately (Recommended for Testing)**
```bash
make credits-process-shop SHOP=your-dev-store.myshopify.com
```

**Option B: Via Rails Console**
```ruby
credit = StoreCredit.pending.first
result = credit.process_now!
puts result.inspect
```

**Option C: Via Rake Task**
```bash
docker-compose exec web bundle exec rake store_credits:process_shop[your-dev-store.myshopify.com]
```

### 5. Verify Results

**Check in Rails:**
```ruby
credit.reload
puts "Status: #{credit.status}"
puts "Shopify ID: #{credit.shopify_credit_id}"
puts "Error: #{credit.error_message}" if credit.failed?
```

**Check in Shopify Admin:**
1. Go to Customers
2. Find customer by email
3. Check "Store credit" section
4. Should show credit amount

### 6. Check Statistics

```bash
make credits-stats
```

Expected output:
```
Store Credits Statistics
==================================================

your-dev-store.myshopify.com:
  Total: 1
  Pending: 0
  Completed: 1
  Failed: 0
  Expired: 0
```

## Detailed Testing Scenarios

### Test 1: Successful Credit Creation

```ruby
# Setup
shop = Shop.first
email = "existing-customer@example.com"  # Must exist!

# Create credit
credit = shop.store_credits.create!(
  email: email,
  amount: 10.00,
  expiry_hours: 168  # 1 week
)

# Process
result = credit.process_now!

# Verify
puts "✓ Test 1: Successful Credit"
puts "  Result: #{result[:success] ? 'PASS' : 'FAIL'}"
puts "  Credit ID: #{result[:credit_id]}"
puts "  Amount: $#{result[:amount]} #{result[:currency]}"
puts "  Status: #{credit.reload.status}"
```

Expected:
- `result[:success]` = true
- `credit.status` = "completed"
- `credit.shopify_credit_id` = numeric ID

### Test 2: Customer Not Found

```ruby
# Create credit for non-existent customer
credit = shop.store_credits.create!(
  email: "nonexistent@example.com",
  amount: 50.00,
  expiry_hours: 72
)

result = credit.process_now!

# Verify
puts "✓ Test 2: Customer Not Found"
puts "  Result: #{result[:success] ? 'FAIL' : 'PASS'}"
puts "  Status: #{credit.reload.status}"
puts "  Error: #{credit.error_message}"
```

Expected:
- `result[:success]` = false
- `credit.status` = "failed"
- `credit.error_message` contains "not found"

### Test 3: Expired Credit

```ruby
# Create expired credit
credit = shop.store_credits.create!(
  email: "test@example.com",
  amount: 15.00,
  expiry_hours: -24  # Expired 24 hours ago
)

result = credit.process_now!

# Verify
puts "✓ Test 3: Expired Credit"
puts "  Expired: #{credit.expired? ? 'YES' : 'NO'}"
puts "  Result: #{result.inspect}"
puts "  Status: #{credit.reload.status}"
```

Expected:
- `credit.expired?` = true
- `result` = nil (skipped)
- `credit.status` = "pending" (unchanged)

### Test 4: Multiple Credits Batch

```ruby
# Create multiple credits
emails = [
  "customer1@example.com",
  "customer2@example.com",
  "customer3@example.com"
]

credits = emails.map do |email|
  shop.store_credits.create!(
    email: email,
    amount: 20.00,
    expiry_hours: 72
  )
end

# Process via job
result = ProcessStoreCreditsJob.perform_now(shop_domain: shop.shopify_domain)

# Verify
puts "✓ Test 4: Batch Processing"
puts "  Total: #{result[:total]}"
puts "  Success: #{result[:success]}"
puts "  Failed: #{result[:failure]}"
```

### Test 5: Service Direct Test

```ruby
service = ShopifyStoreCreditService.new(shop)

# Test customer lookup
customer = service.find_customer_by_email("test@example.com")
puts "✓ Test 5: Service Methods"
puts "  Customer found: #{customer ? 'YES' : 'NO'}"
if customer
  puts "  Customer ID: #{customer['id']}"
  puts "  Display Name: #{customer['displayName']}"
end

# Test credit creation
result = service.create_store_credit(
  email: "test@example.com",
  amount: 30.00,
  expires_at: 7.days.from_now,
  note: "Test credit from console"
)

puts "  Credit created: #{result[:success] ? 'YES' : 'NO'}"
puts "  Credit ID: #{result[:credit_id]}" if result[:success]
puts "  Error: #{result[:error]}" unless result[:success]
```

### Test 6: GraphQL Error Handling

```ruby
service = ShopifyStoreCreditService.new(shop)

# Test with invalid data
result = service.create_store_credit(
  email: "test@example.com",
  amount: -10.00,  # Invalid: negative amount
  expires_at: 1.day.from_now,
  note: "Invalid test"
)

puts "✓ Test 6: Invalid Data Handling"
puts "  Success: #{result[:success] ? 'FAIL' : 'PASS'}"
puts "  Error message: #{result[:error]}"
```

## Integration Tests

### Test Full CSV Upload Flow

1. **Create test CSV:**
```bash
cat > /tmp/test_credits.csv << EOF
email,amount,expiry_hours
customer1@example.com,25.00,72
customer2@example.com,50.00,168
customer3@example.com,10.00,48
EOF
```

2. **Upload via Web UI:**
- Navigate to `/store_credits`
- Upload file
- Check for success/error messages

3. **Process:**
```bash
make credits-process-shop SHOP=your-dev-store.myshopify.com
```

4. **Verify in Shopify:**
- Check each customer's credit balance
- Verify amounts match

### Test Scheduled Processing

1. **Create pending credits:**
```ruby
shop = Shop.first
5.times do |i|
  shop.store_credits.create!(
    email: "customer#{i+1}@example.com",
    amount: (i+1) * 10.0,
    expiry_hours: 72
  )
end
```

2. **Run scheduled task:**
```bash
make credits-process
```

3. **Check logs:**
```bash
docker-compose exec web tail -f log/production.log | grep StoreCredit
```

4. **Verify results:**
```bash
make credits-stats
```

## Debugging Tests

### Enable Detailed Logging

Add to `app/services/shopify_store_credit_service.rb`:

```ruby
def execute_graphql(query, variables = {})
  Rails.logger.debug("=" * 50)
  Rails.logger.debug("GraphQL Query: #{query}")
  Rails.logger.debug("Variables: #{variables.inspect}")

  client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  response = client.query(query: query, variables: variables)

  Rails.logger.debug("Response: #{response.body}")
  Rails.logger.debug("=" * 50)

  # ... rest of method
end
```

### Watch Logs During Testing

```bash
# Terminal 1: Watch all logs
docker-compose exec web tail -f log/development.log

# Terminal 2: Run tests
make console
# ... run test code
```

### Check GraphQL Response

```ruby
service = ShopifyStoreCreditService.new(shop)

# Capture raw response
class ShopifyStoreCreditService
  def test_raw_query
    query = <<~GRAPHQL
      {
        shop {
          name
          email
          currencyCode
        }
      }
    GRAPHQL

    client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    response = client.query(query: query)
    puts JSON.pretty_generate(response.body)
  end
end

service.test_raw_query
```

## Common Issues & Solutions

### Issue: "Customer not found"

**Check:**
```ruby
service = ShopifyStoreCreditService.new(shop)
customer = service.find_customer_by_email("test@example.com")

if customer.nil?
  puts "Customer doesn't exist - create in Shopify Admin"
else
  puts "Customer exists: #{customer['displayName']}"
end
```

**Solution:** Create customer in Shopify Admin first.

### Issue: "Insufficient permissions"

**Check scopes:**
```ruby
shop = Shop.first
puts shop.access_scopes
```

**Solution:**
1. Update scopes in `.env`: `SCOPES=read_products,write_products,read_customers,write_customers`
2. Reinstall app in dev store

### Issue: Rate limiting errors

**Test rate limits:**
```ruby
# Create many credits quickly
shop = Shop.first
10.times do |i|
  credit = shop.store_credits.create!(
    email: "test@example.com",
    amount: 5.00,
    expiry_hours: 72
  )

  result = credit.process_now!
  puts "#{i+1}: #{result[:success] ? '✓' : '✗'}"

  # No delay - test rate limits
end
```

**Solution:** Increase delay in `ProcessStoreCreditsJob`:
```ruby
sleep(1.0)  # Increase from 0.5 to 1.0
```

### Issue: Credits stuck in "processing"

**Find stuck credits:**
```ruby
stuck = StoreCredit.where(status: 'processing')
                   .where('updated_at < ?', 1.hour.ago)

puts "Found #{stuck.count} stuck credits"

# Reset to pending
stuck.update_all(status: 'pending', processed_at: nil)
```

## Performance Testing

### Test Batch Size

```ruby
# Create 100 test credits
shop = Shop.first
100.times do |i|
  shop.store_credits.create!(
    email: "batch-test-#{i}@example.com",
    amount: 10.00,
    expiry_hours: 168
  )
end

# Time the processing
start_time = Time.current
result = ProcessStoreCreditsJob.perform_now(
  shop_domain: shop.shopify_domain,
  limit: 50  # Process 50 at a time
)
duration = Time.current - start_time

puts "Processed #{result[:total]} credits in #{duration.round(2)}s"
puts "Rate: #{(result[:total] / duration).round(2)} credits/sec"
```

### Test Memory Usage

```bash
# Monitor memory during processing
docker stats web

# Or detailed view
docker-compose exec web ps aux | grep rails
```

## Automated Test Suite

Create `test/services/shopify_store_credit_service_test.rb`:

```ruby
require 'test_helper'

class ShopifyStoreCreditServiceTest < ActiveSupport::TestCase
  setup do
    @shop = shops(:one)
    @service = ShopifyStoreCreditService.new(@shop)
  end

  test "finds customer by email" do
    # Mock or use VCR cassette
    customer = @service.find_customer_by_email("test@example.com")
    assert_not_nil customer
    assert_equal "test@example.com", customer['email']
  end

  test "creates store credit" do
    result = @service.create_store_credit(
      email: "test@example.com",
      amount: 25.00,
      expires_at: 3.days.from_now,
      note: "Test"
    )

    assert result[:success]
    assert_not_nil result[:credit_id]
  end
end
```

## Manual Testing Checklist

- [ ] Create customer in Shopify
- [ ] Upload CSV with valid email
- [ ] Process credit manually
- [ ] Verify in Shopify Admin
- [ ] Check credit shows in customer account
- [ ] Test with invalid email
- [ ] Test with expired credit
- [ ] Test batch processing
- [ ] Monitor logs during processing
- [ ] Check statistics dashboard
- [ ] Test automatic scheduled processing
- [ ] Verify error messages display correctly
- [ ] Test delete functionality
- [ ] Test bulk delete

## Quick Test Commands

```bash
# Full test flow
make console

# In console, run:
# 1. Create test credit
shop = Shop.first
credit = shop.store_credits.create!(email: "test@example.com", amount: 25.00, expiry_hours: 72)

# 2. Process it
result = credit.process_now!
puts result.inspect

# 3. Check result
credit.reload
puts "Status: #{credit.status}"
puts "Shopify ID: #{credit.shopify_credit_id}"

# 4. Exit and check stats
exit
make credits-stats
```

## Resources

- [Shopify Integration Guide](SHOPIFY_INTEGRATION.md)
- [Store Credits Guide](STORE_CREDITS_GUIDE.md)
- [Shopify GraphQL Explorer](https://shopify.dev/docs/apps/tools/graphiql-admin-api)

Happy testing! 🧪
