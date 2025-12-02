# Docker Scheduling Setup - Quick Reference

Since you're using Docker, here's the quickest way to set up scheduled shop syncing.

## TL;DR - What You Need to Do

Add this line to your **host machine's** crontab (not inside Docker):

```bash
# Edit your crontab
crontab -e

# Add this line (adjust the path to your project):
0 2 * * * cd /Users/jaychinthrajah/workspaces/_personal_/cheddah/cheddah-rails && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=development >> log/cron.log 2>&1
```

That's it! Your shops will sync daily at 2 AM.

## Why This Approach?

- ✅ Works immediately without modifying Docker setup
- ✅ Reliable - cron runs even if container restarts
- ✅ Easy to test and debug
- ✅ No need to install cron inside Docker

## Test It Now

```bash
# Test the sync manually
make sync-shops

# Or directly
docker-compose exec web bundle exec rake shop:sync_all
```

## Verify It Works

```bash
# Check shop data was updated
docker-compose exec web bundle exec rails runner "shop = Shop.first; puts 'Name: ' + shop.name.to_s; puts 'Email: ' + shop.email.to_s; puts 'Updated: ' + shop.updated_at.to_s"
```

## Makefile Commands (Already Added)

```bash
# Sync all shops
make sync-shops

# Sync specific shop
make sync-shop SHOP=store.myshopify.com

# Preview the cron schedule
make preview-schedule
```

## For Production

When deploying to production, use the same approach but change the environment:

```bash
0 2 * * * cd /path/to/production/app && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production >> log/cron.log 2>&1
```

## Monitoring

```bash
# View cron log (if using host cron)
tail -f log/cron.log

# View Rails production log
docker-compose exec web tail -f log/production.log | grep SyncShopData
```

## Need More Options?

See the detailed [Docker Scheduling Guide](docs/DOCKER_SCHEDULING.md) for:
- Installing cron inside Docker containers
- Using cloud platform schedulers
- Advanced monitoring and alerting
- Alternative approaches

## What's Already Configured

Your app already has:
- ✅ Shop model with all data fields
- ✅ Sync job that runs on installation
- ✅ Rake tasks for manual/scheduled sync
- ✅ Whenever gem configured (for schedule documentation)
- ✅ Makefile commands for easy testing

You just need to add the cron job to your host machine!
