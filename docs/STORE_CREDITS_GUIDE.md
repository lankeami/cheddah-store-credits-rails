# Store Credits Manager Guide

A bulk upload system for managing store credits via CSV files.

## Overview

The Store Credits Manager allows you to:
- Upload CSV files with customer email addresses and credit amounts
- Set expiry times for each credit
- Track the status of credit processing (pending, processing, completed, failed)
- View all uploaded credits with their current status
- Process credits via background jobs

## Accessing the Feature

1. Navigate to your app's home page
2. Click on "💳 Store Credits Manager"
3. Or go directly to `/store_credits`

## CSV Upload

### CSV Format

Your CSV file must include these three columns:

| Column | Description | Example |
|--------|-------------|---------|
| `email` | Customer's email address | customer@example.com |
| `amount` | Credit amount in dollars | 25.00 |
| `expiry_hours` | Hours until credit expires | 72 |

### Sample CSV

```csv
email,amount,expiry_hours
customer1@example.com,25.00,72
customer2@example.com,50.00,168
customer3@example.com,100.00,336
```

**Download:** A sample CSV is available at `/public/sample_store_credits.csv`

### Expiry Hours Examples

| Hours | Time Period |
|-------|-------------|
| 24 | 1 day |
| 48 | 2 days |
| 72 | 3 days |
| 168 | 1 week |
| 336 | 2 weeks |
| 720 | 30 days |

## Upload Process

1. Click "Choose File" and select your CSV
2. Click "Upload CSV"
3. The system will:
   - Validate each row
   - Check email format
   - Verify amount is positive
   - Ensure expiry_hours is a positive integer
   - Calculate expiration datetime
   - Save valid records to database

### Validation Rules

- **Email**: Must be a valid email format
- **Amount**: Must be greater than 0
- **Expiry Hours**: Must be a positive integer

### Upload Results

After upload, you'll see:
- Success count: How many credits were added
- Error count: How many rows failed
- Error details: Specific errors for each failed row

## Credit Status

Credits go through these statuses:

| Status | Description | Color |
|--------|-------------|-------|
| `pending` | Waiting to be processed | Yellow |
| `processing` | Currently being processed | Blue |
| `completed` | Successfully applied to Shopify | Green |
| `failed` | Processing failed (see error message) | Red |

## Dashboard Stats

The dashboard shows:
- **Total**: All credits uploaded
- **Pending**: Credits waiting to be processed
- **Completed**: Successfully processed credits
- **Failed**: Credits that encountered errors

## Managing Credits

### View Credits

- Latest 100 credits are displayed in a table
- Sortable columns show email, amount, expiry, status, and creation time
- Failed credits show error messages in red

### Delete Credit

- Click "Delete" button next to any credit
- Confirmation dialog will appear
- Credit will be permanently removed

### Delete All Credits

- Click "Delete All" button at the top right
- Confirmation dialog will appear
- All credits for your shop will be removed

## Processing Credits

Credits are set to `pending` status after upload. You need to create a background job to process them.

### Example Processing Job

Create a job in `app/jobs/process_store_credits_job.rb`:

```ruby
class ProcessStoreCreditsJob < ActiveJob::Base
  queue_as :default

  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    return unless shop

    shop.store_credits.pending.find_each do |credit|
      next if credit.expired?

      credit.mark_as_processing!

      begin
        # TODO: Implement your Shopify store credit creation logic here
        # Example:
        # shopify_credit_id = create_shopify_store_credit(
        #   shop: shop,
        #   email: credit.email,
        #   amount: credit.amount
        # )

        credit.mark_as_completed!(shopify_credit_id)
      rescue => e
        credit.mark_as_failed!(e.message)
        Rails.logger.error("Failed to process credit #{credit.id}: #{e.message}")
      end
    end
  end
end
```

### Scheduling Processing

Add to your `config/schedule.rb`:

```ruby
# Process store credits every hour
every 1.hour do
  runner "Shop.find_each { |shop| ProcessStoreCreditsJob.perform_later(shop_domain: shop.shopify_domain) }"
end
```

Or run manually:

```bash
# Process credits for a specific shop
rails runner "ProcessStoreCreditsJob.perform_now(shop_domain: 'your-shop.myshopify.com')"

# Process all shops
rails runner "Shop.find_each { |shop| ProcessStoreCreditsJob.perform_now(shop_domain: shop.shopify_domain) }"
```

## Database Schema

### StoreCredit Model

```ruby
create_table :store_credits do |t|
  t.references :shop, null: false, foreign_key: true
  t.string :email, null: false
  t.decimal :amount, precision: 10, scale: 2, null: false
  t.integer :expiry_hours, null: false
  t.datetime :expires_at
  t.string :status, default: 'pending', null: false
  t.string :shopify_credit_id
  t.text :error_message
  t.datetime :processed_at
  t.timestamps
end
```

### Indexes

- `[:shop_id, :email]` - Find credits by shop and customer
- `:status` - Query credits by status
- `:expires_at` - Find expired credits

## API Methods

### StoreCredit Model Methods

```ruby
# Status updates
credit.mark_as_processing!
credit.mark_as_completed!(shopify_credit_id)
credit.mark_as_failed!(error_message)

# Queries
credit.expired?  # Returns true if expires_at is in the past
StoreCredit.pending
StoreCredit.completed
StoreCredit.failed
StoreCredit.expired
```

### Shop Association

```ruby
shop.store_credits  # All credits for this shop
shop.store_credits.pending  # Pending credits
shop.store_credits.create(email:, amount:, expiry_hours:)
```

## Cleanup Tasks

### Remove Expired Credits

```ruby
# Rake task: lib/tasks/store_credits.rake
namespace :store_credits do
  desc "Remove expired store credits"
  task cleanup_expired: :environment do
    count = StoreCredit.expired.destroy_all
    puts "Removed #{count} expired store credits"
  end
end
```

Run daily:

```ruby
# In config/schedule.rb
every 1.day, at: '3:00 am' do
  rake 'store_credits:cleanup_expired'
end
```

## Security Considerations

1. **Access Control**: Only shop owners can upload credits for their shop
2. **Data Validation**: All inputs are validated before saving
3. **CSV Sanitization**: Malformed CSVs are rejected
4. **SQL Injection Protection**: Using Rails ORM prevents SQL injection

## Troubleshooting

### Upload Fails

**Issue**: CSV not accepted
- Check file has `.csv` extension
- Verify content type is `text/csv`
- Ensure headers match exactly: `email`, `amount`, `expiry_hours`

**Issue**: All rows fail validation
- Check email addresses are valid
- Verify amounts are positive numbers
- Ensure expiry_hours are positive integers

### Credits Stuck in Pending

- Check if processing job is running
- Look for errors in logs: `tail -f log/production.log | grep StoreCredit`
- Verify shop access token is still valid

### Failed Credits

- Check error message in the dashboard
- Review logs for detailed error traces
- Verify Shopify API permissions

## Performance Tips

### Large CSV Files

For files with 1000+ rows:
1. Process in batches
2. Use `find_each` instead of `all`
3. Add delay between API calls to avoid rate limits

```ruby
shop.store_credits.pending.find_each(batch_size: 50) do |credit|
  # Process credit
  sleep 0.5  # Avoid rate limits
end
```

### Database Optimization

```ruby
# Add composite index for common queries
add_index :store_credits, [:shop_id, :status, :expires_at]
```

## Future Enhancements

Potential additions:
- [ ] Email notifications to customers
- [ ] Import history tracking
- [ ] Credit usage tracking
- [ ] Scheduled credit releases
- [ ] Credit templates
- [ ] Webhook notifications on status change

## Support

For issues or questions:
1. Check logs: `log/production.log`
2. Review model validations in `app/models/store_credit.rb`
3. Test CSV format with sample file
4. Verify database migrations are up to date

## Related Documentation

- [Shop Sync Setup](../SHOP_SYNC_SETUP.md)
- [Whenever Guide](WHENEVER_GUIDE.md)
- [Docker Scheduling](DOCKER_SCHEDULING.md)
