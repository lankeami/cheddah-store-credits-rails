# Documentation

This directory contains guides for scheduled jobs and background tasks.

## Available Guides

### [Docker Scheduling Guide](DOCKER_SCHEDULING.md) 🐳
**Using Docker?** Start here for Docker-specific scheduling instructions.

- Host-level cron setup (recommended)
- Installing cron in Docker containers
- Cloud platform options
- Testing and monitoring

### [Scheduling Quick Start](SCHEDULING_QUICK_START.md)
Get your shop sync running on a schedule in under 5 minutes (for non-Docker setups).

- Quick installation steps
- Verify it's working
- Common tasks and troubleshooting

### [Whenever Guide](WHENEVER_GUIDE.md)
Comprehensive guide to using the Whenever gem for cron job scheduling.

- Complete syntax reference
- Common scheduling patterns
- Deployment instructions for different platforms
- Advanced troubleshooting
- Best practices

### [Store Credits Manager Guide](STORE_CREDITS_GUIDE.md) 💳
Complete guide to the store credits bulk upload system.

- CSV upload format and validation
- Status tracking and management
- Processing credits with background jobs
- Rake tasks and automation
- Troubleshooting and best practices

### [Shopify Integration Guide](SHOPIFY_INTEGRATION.md) 🔌
Technical documentation for Shopify GraphQL API integration.

- GraphQL mutations and queries
- Service layer architecture
- Background job processing
- Error handling and rate limiting
- Testing and monitoring
- Advanced usage patterns

### [Testing Store Credits](TESTING_STORE_CREDITS.md) 🧪
Complete guide to testing the store credits functionality.

- Quick test steps
- Detailed test scenarios
- Integration tests
- Debugging techniques
- Performance testing
- Automated test suite examples

## Other Documentation

### [Shop Sync Setup](../SHOP_SYNC_SETUP.md)
Details about the shop data synchronization system.

- What data gets synced
- All scheduling options (Whenever, Heroku, Sidekiq, etc.)
- Manual sync commands
- Monitoring and troubleshooting

## Quick Links

| Task | Command |
|------|---------|
| Install dependencies | `bundle install` |
| Preview schedule | `bundle exec whenever` |
| Install cron jobs | `bundle exec whenever --update-crontab cheddah-rails` |
| Manual sync | `bundle exec rake shop:sync_all` |
| View logs | `tail -f log/cron.log` |

## Current Scheduled Jobs

Your app automatically:
1. ✅ Syncs shop data when a merchant installs the app
2. ✅ Syncs all shop data daily at 2:00 AM (configured in [config/schedule.rb](../config/schedule.rb))

## Need Help?

1. Start with [Scheduling Quick Start](SCHEDULING_QUICK_START.md)
2. For detailed Whenever usage, see [Whenever Guide](WHENEVER_GUIDE.md)
3. For shop sync specifics, see [Shop Sync Setup](../SHOP_SYNC_SETUP.md)
