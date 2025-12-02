# Shopify Store Credits - GraphQL API Integration

Complete guide to the Shopify GraphQL integration for processing store credits.

## Overview

The store credits feature uses Shopify's GraphQL Admin API to create customer account credits. Credits are processed via background jobs that:

1. Find the customer by email
2. Create a store credit using `customerCreditGrant` mutation
3. Track the credit ID and status
4. Handle errors and retries

## Required Permissions

Your app must request these scopes:

```ruby
# config/initializers/shopify_app.rb
config.scope = 'read_products,write_products,read_customers,write_customers'
```

**Important:** After adding new scopes, existing stores must reinstall or reauthorize the app.

## Architecture

### Components

1. **ShopifyStoreCreditService** - GraphQL API wrapper
2. **ProcessStoreCreditsJob** - Background job processor
3. **StoreCredit Model** - Data model with processing methods
4. **Rake Tasks** - Manual processing commands

### Flow

```
CSV Upload
    ↓
StoreCredit (status: pending)
    ↓
ProcessStoreCreditsJob (hourly)
    ↓
ShopifyStoreCreditService.create_store_credit
    ↓
GraphQL customerCreditGrant mutation
    ↓
StoreCredit (status: completed/failed)
```

## GraphQL Mutations

### customerCreditGrant

Creates a store credit for a customer:

```graphql
mutation customerCreditGrant($input: CustomerCreditGrantInput!) {
  customerCreditGrant(input: $input) {
    customerCredit {
      id
      amount {
        value
        currencyCode
      }
      expiresAt
      customer {
        id
        email
      }
    }
    userErrors {
      field
      message
    }
  }
}
```

**Input Variables:**

```ruby
{
  input: {
    customerId: "gid://shopify/Customer/123",
    amount: {
      amount: "25.00",
      currencyCode: "USD"
    },
    expiresAt: "2024-12-31T23:59:59Z",
    note: "Store credit from bulk upload"
  }
}
```

## Service Layer

### ShopifyStoreCreditService

Location: [app/services/shopify_store_credit_service.rb](../app/services/shopify_store_credit_service.rb)

#### Methods

**create_store_credit(email:, amount:, expires_at:, note:)**

Creates a store credit for a customer.

```ruby
service = ShopifyStoreCreditService.new(shop)
result = service.create_store_credit(
  email: "customer@example.com",
  amount: 25.00,
  expires_at: 72.hours.from_now,
  note: "Holiday promotion credit"
)

if result[:success]
  puts "Credit created: #{result[:credit_id]}"
  puts "Amount: #{result[:amount]} #{result[:currency]}"
else
  puts "Error: #{result[:error]}"
end
```

**find_customer_by_email(email)**

Finds a Shopify customer by email address.

```ruby
customer = service.find_customer_by_email("customer@example.com")
# Returns: { 'id' => 'gid://shopify/Customer/123', 'email' => '...', 'displayName' => '...' }
```

**get_customer_credits(customer_email)**

Gets the current credit balance for a customer.

```ruby
balance = service.get_customer_credits("customer@example.com")
# Returns: { 'value' => '50.00', 'currencyCode' => 'USD' }
```

## Background Job

### ProcessStoreCreditsJob

Location: [app/jobs/process_store_credits_job.rb](../app/jobs/process_store_credits_job.rb)

Processes pending store credits for a shop.

**Usage:**

```ruby
# Queue for background processing
ProcessStoreCreditsJob.perform_later(shop_domain: 'store.myshopify.com')

# Process immediately (synchronous)
ProcessStoreCreditsJob.perform_now(shop_domain: 'store.myshopify.com')
```

**Features:**
- Processes up to 50 credits per run (configurable)
- Skips expired credits
- 0.5 second delay between API calls (rate limiting)
- Detailed logging
- Error handling with status tracking

**Returns:**

```ruby
{
  shop: "store.myshopify.com",
  total: 10,
  success: 8,
  failure: 2
}
```

## Model Methods

### StoreCredit

Location: [app/models/store_credit.rb](../app/models/store_credit.rb)

#### process_now!

Process a single credit immediately:

```ruby
credit = StoreCredit.find(123)
result = credit.process_now!

if result[:success]
  puts "Processed! Shopify Credit ID: #{credit.shopify_credit_id}"
else
  puts "Failed: #{credit.error_message}"
end
```

#### Status Methods

```ruby
credit.mark_as_processing!  # Sets status to 'processing'
credit.mark_as_completed!(credit_id)  # Sets status to 'completed'
credit.mark_as_failed!(error)  # Sets status to 'failed'
```

## Rake Tasks

### Process All Shops

Queue processing jobs for all shops with pending credits:

```bash
rake store_credits:process_all
```

### Process Specific Shop

Process credits for one shop immediately (synchronous):

```bash
rake store_credits:process_shop[store.myshopify.com]
```

### Makefile Commands

```bash
# Queue processing for all shops
make credits-process

# Process specific shop NOW (blocks until complete)
make credits-process-shop SHOP=store.myshopify.com

# View statistics
make credits-stats

# Cleanup expired
make credits-cleanup
```

## Scheduling

Credits are automatically processed hourly via whenever:

```ruby
# config/schedule.rb
every 1.hour do
  rake 'store_credits:process_all'
end
```

See [Docker Scheduling Guide](DOCKER_SCHEDULING.md) for cron setup.

## Error Handling

### Common Errors

**Customer not found:**
```
Error: Customer with email customer@example.com not found in Shopify
```
**Solution:** Ensure customer exists in Shopify before uploading credit.

**Invalid amount:**
```
Error: amount: must be greater than 0
```
**Solution:** Check CSV has valid positive amounts.

**Expired credit:**
```
Credit skipped - already expired
```
**Solution:** Credits with past expiry dates are automatically skipped.

**Rate limiting:**
```
Error: Throttled
```
**Solution:** Job includes 0.5s delays. Increase if needed.

### Error Storage

Failed credits store the error message:

```ruby
credit.error_message  # "Customer with email x@y.com not found"
credit.status         # "failed"
credit.processed_at   # Timestamp of failure
```

View failed credits in the dashboard with full error details.

## Rate Limiting

Shopify API has rate limits:
- **REST API:** 2 requests/second (bucket size: 40)
- **GraphQL:** Cost-based (varies by query complexity)

The job includes a 0.5 second delay between requests to stay within limits.

**Adjust delay:**

```ruby
# In app/jobs/process_store_credits_job.rb
sleep(1.0)  # Increase to 1 second for safety
```

## Testing

### Test with Single Credit

```ruby
# In Rails console
shop = Shop.first
credit = shop.store_credits.create!(
  email: "existing-customer@example.com",
  amount: 10.00,
  expiry_hours: 72
)

result = credit.process_now!
puts result.inspect
```

### Test Service Directly

```ruby
service = ShopifyStoreCreditService.new(shop)

# Find customer
customer = service.find_customer_by_email("test@example.com")
puts customer.inspect

# Create credit
result = service.create_store_credit(
  email: "test@example.com",
  amount: 25.00,
  expires_at: 3.days.from_now,
  note: "Test credit"
)
puts result.inspect
```

### Test Job

```ruby
# Process all pending for a shop (dry run)
result = ProcessStoreCreditsJob.perform_now(
  shop_domain: 'dev-store.myshopify.com'
)
puts "Success: #{result[:success]}, Failed: #{result[:failure]}"
```

## Monitoring

### View Logs

```bash
# Processing logs
docker-compose exec web tail -f log/production.log | grep StoreCredit

# Successful credits
docker-compose exec web tail -f log/production.log | grep "✓ Created credit"

# Failed credits
docker-compose exec web tail -f log/production.log | grep "✗ Failed credit"
```

### Check Status

```bash
make credits-stats
```

Output:
```
Store Credits Statistics
==================================================

store.myshopify.com:
  Total: 100
  Pending: 5
  Completed: 90
  Failed: 5
  Expired: 0
```

## Troubleshooting

### Credits Stuck in Pending

**Possible causes:**
1. Processing job not running
2. Customers don't exist in Shopify
3. API permissions insufficient

**Debug:**

```bash
# Check for pending credits
make credits-stats

# Try processing manually
make credits-process-shop SHOP=your-shop.myshopify.com

# Check logs
docker-compose exec web tail -f log/production.log
```

### All Credits Failing

**Check permissions:**

```ruby
shop = Shop.first
shop.access_scopes
# Should include: "read_customers,write_customers"
```

If scopes are missing, shop needs to reinstall app.

### GraphQL Errors

Enable detailed GraphQL logging:

```ruby
# In app/services/shopify_store_credit_service.rb
Rails.logger.debug("GraphQL Query: #{query}")
Rails.logger.debug("Variables: #{variables.inspect}")
Rails.logger.debug("Response: #{response.inspect}")
```

## Best Practices

### 1. Verify Customers Exist

Before uploading CSVs, ensure customers exist in Shopify:

```ruby
service = ShopifyStoreCreditService.new(shop)
emails.each do |email|
  customer = service.find_customer_by_email(email)
  puts "#{email}: #{customer ? 'Found' : 'NOT FOUND'}"
end
```

### 2. Set Reasonable Expiry Times

```ruby
# Good: 72 hours (3 days)
expiry_hours: 72

# Better: 168 hours (1 week)
expiry_hours: 168

# Best: 720 hours (30 days)
expiry_hours: 720
```

### 3. Monitor Failed Credits

Check failed credits daily and investigate patterns:

```bash
# In Rails console
failed = StoreCredit.failed.where('created_at > ?', 1.day.ago)
failed.group(:error_message).count
```

### 4. Batch Processing

For large uploads (1000+ credits):
- Upload in batches of 500
- Monitor processing between batches
- Check for rate limit errors

### 5. Use Notes for Tracking

Include useful information in notes:

```ruby
note: "Black Friday 2024 - Expires #{expires_at.strftime('%m/%d/%Y')}"
```

## Advanced Usage

### Custom Processing Logic

Create a custom processor:

```ruby
class CustomStoreCreditProcessor
  def self.process_vip_customers(shop)
    credits = shop.store_credits.pending.where('amount >= ?', 100)

    credits.each do |credit|
      # Add extra processing for VIP credits
      result = credit.process_now!

      if result[:success]
        # Send notification email
        VipCreditMailer.credit_applied(credit).deliver_later
      end
    end
  end
end
```

### Webhook Integration

Listen for customer creation and auto-apply credits:

```ruby
# app/jobs/webhooks/customer_create_job.rb
class Webhooks::CustomerCreateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    email = webhook['email']

    # Find pending credits for this email
    pending = shop.store_credits.pending.where(email: email)

    pending.each(&:process_now!)
  end
end
```

## API Reference

### GraphQL Queries Used

**Customer Search:**
```graphql
query getCustomerByEmail($email: String!) {
  customers(first: 1, query: $email) {
    edges {
      node {
        id
        email
        displayName
      }
    }
  }
}
```

**Credit Balance:**
```graphql
query getCustomerCredits($customerId: ID!) {
  customer(id: $customerId) {
    creditBalance {
      value
      currencyCode
    }
  }
}
```

## Resources

- [Shopify GraphQL Admin API](https://shopify.dev/docs/api/admin-graphql)
- [Customer Credit API](https://shopify.dev/docs/api/admin-graphql/latest/mutations/customerCreditGrant)
- [Rate Limits](https://shopify.dev/docs/api/usage/rate-limits)
- [Store Credits Guide](STORE_CREDITS_GUIDE.md)
