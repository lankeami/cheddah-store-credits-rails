# Scheduling Quick Start Guide

Get your shop sync running on a schedule in under 5 minutes.

> **Using Docker?** See [Docker Scheduling Guide](DOCKER_SCHEDULING.md) for Docker-specific instructions.

## Step 1: Install Dependencies

```bash
# In Docker
docker-compose exec web bundle install

# Or locally
bundle install
```

## Step 2: Preview Your Schedule

```bash
# See what cron jobs will be created
bundle exec whenever
```

You should see output like:
```
0 2 * * * /bin/bash -l -c 'cd /path/to/app && RAILS_ENV=production bundle exec rake shop:sync_all'
```

## Step 3: Install the Schedule

### For Production Server

```bash
# Install cron jobs on your system
bundle exec whenever --update-crontab cheddah-rails --set environment=production
```

### For Docker

Since you're using Docker, you have two options:

**Option A: Run from Host Machine (Recommended)**

Add to your host crontab (`crontab -e`):
```bash
0 2 * * * cd /path/to/cheddah-rails && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production >> log/cron.log 2>&1
```

**Option B: Install Cron in Docker Container**

You'll need to modify your Dockerfile to include cron and start it with your app.

## Step 4: Verify Installation

```bash
# Check installed jobs
bundle exec whenever --list

# Or check system crontab
crontab -l
```

## Step 5: Monitor Logs

```bash
# Watch cron logs
tail -f log/cron.log

# Or production logs
tail -f log/production.log | grep SyncShopData
```

## Common Tasks

### Change Schedule Time

Edit [config/schedule.rb](../config/schedule.rb):
```ruby
# Run at 3 AM instead of 2 AM
every 1.day, at: '3:00 am' do
  rake 'shop:sync_all'
end
```

Then update:
```bash
bundle exec whenever --update-crontab cheddah-rails
```

### Add More Scheduled Jobs

Edit [config/schedule.rb](../config/schedule.rb):
```ruby
# Your existing job
every 1.day, at: '2:00 am' do
  rake 'shop:sync_all'
end

# Add a new job
every 1.hour do
  rake 'some:other_task'
end
```

Update crontab:
```bash
bundle exec whenever --update-crontab cheddah-rails
```

### Remove All Scheduled Jobs

```bash
bundle exec whenever --clear-crontab cheddah-rails
```

### Test Manually

```bash
# Test the rake task
bundle exec rake shop:sync_all

# Or in Docker
docker-compose exec web bundle exec rake shop:sync_all
```

## Troubleshooting

### Jobs Not Running?

1. **Check cron is running:**
   ```bash
   systemctl status cron
   ```

2. **Verify jobs are installed:**
   ```bash
   crontab -l
   ```

3. **Check logs:**
   ```bash
   tail -f log/cron.log
   ```

4. **Test manually:**
   ```bash
   bundle exec rake shop:sync_all
   ```

### Need More Help?

- See [WHENEVER_GUIDE.md](WHENEVER_GUIDE.md) for comprehensive documentation
- See [SHOP_SYNC_SETUP.md](../SHOP_SYNC_SETUP.md) for shop sync details

## Current Setup

Your app is currently configured to:
- ✅ Sync shop data **on installation** (via `after_authenticate_job`)
- ✅ Sync all shops **daily at 2:00 AM** (via Whenever gem)

All shop data fields are automatically kept up to date!
