# Store Credits Manager - Quick Start

A simple CSV upload system for bulk creating store credits.

## Access the Feature

1. Open your Shopify app
2. Click "💳 Store Credits Manager" on the home page
3. Or navigate to `/store_credits`

## Quick Upload

### 1. Prepare Your CSV

Create a file with three columns:

```csv
email,amount,expiry_hours
customer@example.com,25.00,72
another@example.com,50.00,168
```

**Download sample:** [public/sample_store_credits.csv](public/sample_store_credits.csv)

### 2. Upload

1. Click "Choose File"
2. Select your CSV
3. Click "Upload CSV"
4. View results and any errors

### 3. Monitor

The dashboard shows:
- 📊 Total, Pending, Completed, Failed counts
- 📝 List of all credits with status
- ❌ Error messages for failed credits

## CSV Format

| Column | Description | Example |
|--------|-------------|---------|
| `email` | Customer email | customer@example.com |
| `amount` | Credit amount | 25.00 |
| `expiry_hours` | Hours until expiry | 72 (3 days) |

## Makefile Commands

```bash
# View statistics
make credits-stats

# Process credits NOW
make credits-process-shop SHOP=your-shop.myshopify.com

# Queue processing (all shops)
make credits-process

# Remove expired credits
make credits-cleanup
```

## What Happens After Upload?

1. Credits are saved with `pending` status
2. **Processing runs automatically every hour** via background job
3. Job finds customers in Shopify and creates store credits using GraphQL
4. Status changes to `completed` or `failed`
5. Error messages are stored for failed credits

## Processing Credits

### Automatic (Configured!)

Credits are processed automatically every hour:

```ruby
# Configured in config/schedule.rb
every 1.hour do
  rake 'store_credits:process_all'
end
```

### Manual Processing

```bash
# Process all pending credits
make credits-process

# Process specific shop NOW (synchronous)
make credits-process-shop SHOP=your-shop.myshopify.com

# View results
make credits-stats
```

## Next Steps

1. ✅ Upload your CSV file
2. ✅ Credits process automatically every hour
3. 📊 Monitor with `make credits-stats`
4. 📋 Review [Shopify Integration Guide](docs/SHOPIFY_INTEGRATION.md) for advanced features

## Complete Documentation

See [docs/STORE_CREDITS_GUIDE.md](docs/STORE_CREDITS_GUIDE.md) for:
- Processing credits with background jobs
- Scheduling automated cleanup
- API methods and database schema
- Troubleshooting and best practices

## Features

✅ CSV bulk upload
✅ Email validation
✅ Expiry calculation
✅ Status tracking
✅ Error reporting
✅ Batch deletion
✅ Statistics dashboard
✅ Makefile commands
✅ Rake tasks

## Database

- **Table**: `store_credits`
- **Status**: pending → processing → completed/failed
- **Auto-expiry**: Based on expiry_hours
- **Shop isolation**: Each shop sees only their credits

## Support

For detailed information:
- [Complete Guide](docs/STORE_CREDITS_GUIDE.md)
- [Documentation Index](docs/README.md)
