# Whenever Gem - Cron Job Scheduling Guide

This guide covers how to use the Whenever gem to schedule recurring jobs in your Rails application.

## Table of Contents
- [What is Whenever?](#what-is-whenever)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Schedule Syntax](#schedule-syntax)
- [Common Patterns](#common-patterns)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## What is Whenever?

Whenever is a Ruby gem that provides a clean syntax for writing and deploying cron jobs. Instead of writing cryptic cron syntax, you write Ruby code that gets converted to cron entries.

**Benefits:**
- Clean, readable Ruby syntax instead of cron syntax
- Environment-aware (development, staging, production)
- Easy to version control
- Integrates seamlessly with Rails

## Installation

### 1. Add to Gemfile (Already Done)

The gem is already in your [Gemfile](../Gemfile:28):
```ruby
gem 'whenever', require: false
```

### 2. Install the Gem

```bash
# Local development
bundle install

# In Docker
docker-compose exec web bundle install
```

### 3. Verify Installation

```bash
# Check whenever command is available
bundle exec whenever --help
```

## Basic Usage

### View Current Schedule

See what cron jobs will be created:

```bash
bundle exec whenever
```

This shows the cron syntax that will be installed (doesn't actually install it).

### Update Crontab

Install/update the cron jobs on your system:

```bash
# Update crontab with jobs from schedule.rb
bundle exec whenever --update-crontab

# Or specify the app name (recommended for multiple apps)
bundle exec whenever --update-crontab cheddah-rails
```

### View Installed Cron Jobs

```bash
# List all whenever-managed cron jobs
bundle exec whenever --list

# Or use system crontab command
crontab -l
```

### Clear Cron Jobs

Remove all whenever-managed jobs:

```bash
bundle exec whenever --clear-crontab

# Or for specific app
bundle exec whenever --clear-crontab cheddah-rails
```

## Schedule Syntax

The schedule is defined in [config/schedule.rb](../config/schedule.rb). Here's the syntax:

### Time-Based Scheduling

```ruby
# Every X minutes
every 15.minutes do
  rake 'task:name'
end

# Every X hours
every 3.hours do
  rake 'task:name'
end

# Daily at specific time
every 1.day, at: '2:00 am' do
  rake 'task:name'
end

# Multiple times per day
every 1.day, at: ['4:30 am', '12:00 pm', '8:00 pm'] do
  rake 'task:name'
end

# Specific days
every :monday, at: '12:00 pm' do
  rake 'task:name'
end

# Weekdays only
every :weekday, at: '9:00 am' do
  rake 'task:name'
end

# Weekend only
every :weekend, at: '10:00 am' do
  rake 'task:name'
end

# Specific day and time
every :sunday, at: '3:00 am' do
  rake 'task:name'
end
```

### Job Types

```ruby
# Run a rake task
every 1.day do
  rake 'shop:sync_all'
end

# Run a Rails runner command
every 1.hour do
  runner 'Shop.find_each(&:sync_shop_data)'
end

# Run a custom command/script
every 1.day, at: '5:00 am' do
  command '/usr/bin/custom_script.sh'
end

# Run multiple commands
every 1.day, at: '2:00 am' do
  rake 'db:backup'
  rake 'shop:sync_all'
  command 'echo "Daily tasks complete"'
end
```

### Configuration Options

```ruby
# Set environment (production, staging, development)
set :environment, 'production'

# Or use ENV variable
set :environment, ENV.fetch('RAILS_ENV', 'production')

# Set output log location
set :output, 'log/cron.log'

# Append to log instead of truncate
set :output, { error: 'log/cron_error.log', standard: 'log/cron.log' }

# Silence output
set :output, '/dev/null'

# Set custom job template
set :job_template, "/bin/bash -l -c ':job'"

# Set PATH
set :path, '/usr/local/bin:/usr/bin:/bin'
```

## Common Patterns

### Pattern 1: Daily Maintenance Tasks

```ruby
every 1.day, at: '2:00 am' do
  rake 'shop:sync_all'
  rake 'db:cleanup_old_records'
  rake 'cache:clear_expired'
end
```

### Pattern 2: Hourly Data Sync

```ruby
every 1.hour do
  rake 'data:sync'
end
```

### Pattern 3: Business Hours Only

```ruby
# Run every hour during business hours (9 AM - 5 PM)
(9..17).each do |hour|
  every 1.day, at: "#{hour}:00" do
    rake 'notifications:send_business_updates'
  end
end
```

### Pattern 4: Different Schedules per Environment

```ruby
case @environment
when 'production'
  every 1.day, at: '2:00 am' do
    rake 'shop:sync_all'
  end
when 'staging'
  every 1.day, at: '3:00 am' do
    rake 'shop:sync_all'
  end
when 'development'
  every 1.hour do
    rake 'shop:sync_all'
  end
end
```

### Pattern 5: Weekly Reports

```ruby
# Every Monday at 9 AM
every :monday, at: '9:00 am' do
  rake 'reports:weekly'
end

# First day of month
every '0 0 1 * *' do
  rake 'reports:monthly'
end
```

### Pattern 6: High-Frequency Jobs

```ruby
# Every 5 minutes
every 5.minutes do
  runner 'Monitor.check_system_health'
end

# Every 30 seconds (use with caution!)
every '*/30 * * * * *' do
  runner 'RealTimeMonitor.ping'
end
```

## Deployment

### Local/VPS Deployment

1. **SSH into your server**
2. **Navigate to your app directory**
   ```bash
   cd /path/to/cheddah-rails
   ```
3. **Update crontab**
   ```bash
   bundle exec whenever --update-crontab cheddah-rails --set environment=production
   ```
4. **Verify installation**
   ```bash
   crontab -l
   ```

### Docker Deployment

For Docker, you have two options:

#### Option A: Install cron in container

Add to your `Dockerfile`:
```dockerfile
RUN apt-get update && apt-get install -y cron

# Add whenever to entrypoint
RUN bundle exec whenever --update-crontab --set environment=production

# Start cron
CMD cron && bundle exec rails server
```

#### Option B: Host-level cron (Recommended)

Run cron on the host machine instead of in the container:

```bash
# Add to host crontab
0 2 * * * cd /path/to/app && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production >> log/cron.log 2>&1
```

### Heroku Deployment

Whenever doesn't work on Heroku. Use **Heroku Scheduler** instead:

```bash
heroku addons:create scheduler:standard
heroku addons:open scheduler
```

Then add your task: `rake shop:sync_all`

### Capistrano Deployment

If using Capistrano, add to `Capfile`:
```ruby
require 'whenever/capistrano'
```

Whenever will automatically update crontab on each deploy.

## Troubleshooting

### Jobs Not Running

**Check if cron is running:**
```bash
systemctl status cron
# or
service cron status
```

**Verify crontab is updated:**
```bash
crontab -l | grep cheddah
```

**Check logs:**
```bash
tail -f log/cron.log
```

### Environment Issues

**Ensure PATH is set correctly:**
```ruby
# In config/schedule.rb
set :path, '/usr/local/bin:/usr/bin:/bin'
```

**Set Ruby version explicitly:**
```ruby
set :job_template, "/bin/bash -l -c 'source ~/.bashrc && :job'"
```

**Use rbenv/rvm path:**
```ruby
# For rbenv
set :job_template, "/bin/bash -l -c 'eval \"$(rbenv init -)\" && :job'"

# For rvm
set :job_template, "/bin/bash -l -c 'source ~/.rvm/scripts/rvm && :job'"
```

### Permission Issues

```bash
# Make sure log directory is writable
chmod 755 log/
touch log/cron.log
chmod 644 log/cron.log
```

### Test Jobs Manually

Run the exact command that cron will run:

```bash
# View the cron command
bundle exec whenever | grep shop:sync

# Copy and test the command
cd /path/to/app && RAILS_ENV=production bundle exec rake shop:sync_all
```

### Check Syntax

```bash
# Validate schedule.rb syntax
bundle exec whenever --write-crontab --

# This will show errors without installing
```

## Best Practices

### 1. Use Descriptive Comments

```ruby
# Sync shop data from Shopify - Runs daily at 2 AM
every 1.day, at: '2:00 am' do
  rake 'shop:sync_all'
end
```

### 2. Set Appropriate Log Output

```ruby
# Always log output for debugging
set :output, 'log/cron.log'

# Or separate error logs
set :output, {
  error: 'log/cron_error.log',
  standard: 'log/cron.log'
}
```

### 3. Use Environment Variables

```ruby
set :environment, ENV.fetch('RAILS_ENV', 'production')
```

### 4. Avoid Overlapping Jobs

```ruby
# Bad: Job might still be running when next one starts
every 5.minutes do
  rake 'long_running_task'
end

# Good: Give it enough time to complete
every 1.hour do
  rake 'long_running_task'
end
```

### 5. Use Job Queues for Heavy Tasks

Instead of running heavy tasks directly in cron:

```ruby
# Instead of this:
every 1.hour do
  rake 'heavy:task'
end

# Do this:
every 1.hour do
  runner 'HeavyTaskJob.perform_later'
end
```

### 6. Monitor Job Execution

Add monitoring to your jobs:

```ruby
# In your rake task
task sync_all: :environment do
  start_time = Time.current

  begin
    SyncAllShopsDataJob.perform_now
    Rails.logger.info "[CRON] shop:sync_all completed in #{Time.current - start_time}s"
  rescue => e
    Rails.logger.error "[CRON] shop:sync_all failed: #{e.message}"
    # Send alert email, Slack notification, etc.
    raise
  end
end
```

### 7. Use Whenever Identifiers

```ruby
# Update with app-specific identifier
bundle exec whenever --update-crontab cheddah-rails

# Makes it easy to manage multiple apps
bundle exec whenever --list
bundle exec whenever --clear-crontab cheddah-rails
```

### 8. Version Control Your Schedule

Always commit `config/schedule.rb` to git so your schedule is versioned with your code.

### 9. Test Before Deploying

```bash
# Preview what will be added to crontab
bundle exec whenever

# Test the actual rake task
bundle exec rake shop:sync_all
```

### 10. Document Timezone Awareness

```ruby
# Add timezone info to schedule.rb
# All times are in server timezone (usually UTC in production)
set :output, 'log/cron.log'

# For specific timezone, use raw cron with TZ
every 1.day do
  command 'TZ=America/New_York rake shop:sync_all'
end
```

## Quick Reference

| Task | Command |
|------|---------|
| View schedule | `bundle exec whenever` |
| Install schedule | `bundle exec whenever --update-crontab` |
| Install with app name | `bundle exec whenever --update-crontab cheddah-rails` |
| List installed jobs | `bundle exec whenever --list` |
| Clear all jobs | `bundle exec whenever --clear-crontab` |
| View crontab | `crontab -l` |
| Edit crontab manually | `crontab -e` |
| Check logs | `tail -f log/cron.log` |
| Test syntax | `bundle exec whenever --write-crontab --` |

## Additional Resources

- [Whenever GitHub](https://github.com/javan/whenever)
- [Cron Expression Generator](https://crontab.guru/)
- [Cron Documentation](https://en.wikipedia.org/wiki/Cron)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs in `log/cron.log`
3. Test rake tasks manually
4. Verify cron service is running
5. Check file permissions
