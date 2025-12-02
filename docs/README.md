# Documentation

This directory contains guides for scheduled jobs and background tasks.

## Available Guides

### [Scheduling Quick Start](SCHEDULING_QUICK_START.md)
**Start here!** Get your shop sync running on a schedule in under 5 minutes.

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
