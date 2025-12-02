# Shop Data Sync Setup

This application automatically syncs shop data from Shopify to keep your local database up to date.

## How It Works

### On Installation
When a merchant installs your app, the `SyncShopDataJob` automatically runs to fetch and save all shop information.

### Daily Sync
To keep shop data current, you should schedule the sync task to run daily.

## Scheduled Sync Options

### Option 1: Whenever Gem (Recommended - Already Configured!)

The Whenever gem is already set up in this project. It provides a clean Ruby syntax for managing cron jobs.

**Quick Start:**

1. Install the gem:
   ```bash
   bundle install
   ```

2. Update your crontab:
   ```bash
   bundle exec whenever --update-crontab cheddah-rails
   ```

3. Verify it's installed:
   ```bash
   bundle exec whenever --list
   ```

**Configuration:**

The schedule is defined in [config/schedule.rb](config/schedule.rb). By default, it runs shop sync daily at 2:00 AM:

```ruby
every 1.day, at: '2:00 am' do
  rake 'shop:sync_all'
end
```

**Common Commands:**
```bash
# Preview schedule without installing
bundle exec whenever

# Update crontab
bundle exec whenever --update-crontab cheddah-rails

# Remove all jobs
bundle exec whenever --clear-crontab cheddah-rails
```

**Need more details?** See the comprehensive [Whenever Guide](docs/WHENEVER_GUIDE.md) for advanced usage, troubleshooting, and best practices.

### Option 2: Manual Cron Job (For Advanced Users)

Add this line to your crontab (run `crontab -e`):

```bash
# Run shop sync daily at 2 AM
0 2 * * * cd /path/to/cheddah-rails && RAILS_ENV=production bundle exec rake shop:sync_all >> log/shop_sync.log 2>&1
```

### Option 3: Heroku Scheduler

If you're deploying to Heroku (Whenever doesn't work on Heroku):

1. Add the Heroku Scheduler addon:
   ```bash
   heroku addons:create scheduler:standard
   ```

2. Open the scheduler dashboard:
   ```bash
   heroku addons:open scheduler
   ```

3. Add a new job with this command:
   ```bash
   rake shop:sync_all
   ```

4. Set it to run daily at your preferred time.

### Option 4: Sidekiq-Cron (If Using Sidekiq)

Add to your Gemfile:
```ruby
gem 'sidekiq-cron'
```

Then create an initializer `config/initializers/sidekiq_cron.rb`:
```ruby
schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
```

Create `config/schedule.yml`:
```yaml
sync_all_shops:
  cron: "0 2 * * *"  # Daily at 2 AM
  class: SyncAllShopsDataJob
  queue: default
```

## Manual Sync

### Sync All Shops
```bash
rake shop:sync_all
```

### Sync Specific Shop
```bash
rake shop:sync[shop-name.myshopify.com]
```

## What Data Gets Synced

The sync fetches and stores:
- Store name, email, phone, and address
- Domain information (custom domain and myshopify domain)
- Store owner information
- Currency, timezone, and locale settings
- Plan information (plan name and display name)
- Tax and shipping settings
- Store capabilities (storefront, discounts, payments, etc.)
- Store status flags (password enabled, pre-launch, setup required, etc.)
- Multi-location and SSL settings
- Marketing and finance settings

## Monitoring

Check sync logs:
```bash
tail -f log/production.log | grep "SyncShopData"
```

## Troubleshooting

If a sync fails:
1. Check that the shop's access token is still valid
2. Verify the shop hasn't uninstalled the app
3. Review logs for API errors
4. Ensure the app has the necessary API scopes

## Testing

Test the sync manually before setting up automation:
```bash
# In development
rake shop:sync_all

# Or for a specific shop
rake shop:sync[your-dev-shop.myshopify.com]
```
