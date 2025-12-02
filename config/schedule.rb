# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
# Learn more: http://github.com/javan/whenever

# Set the environment (defaults to production)
set :environment, ENV.fetch('RAILS_ENV', 'production')

# Set output to a log file
set :output, 'log/cron.log'

# Sync shop data daily at 2:00 AM
every 1.day, at: '2:00 am' do
  rake 'shop:sync_all'
end

# Process store credits every hour
every 1.hour do
  rake 'store_credits:process_all'
end

# Cleanup expired store credits daily at 3:00 AM
every 1.day, at: '3:00 am' do
  rake 'store_credits:cleanup_expired'
end

# Example: Run every hour
# every 1.hour do
#   rake 'shop:sync_all'
# end

# Example: Run every 30 minutes
# every 30.minutes do
#   rake 'shop:sync_all'
# end

# Example: Run at specific times
# every 1.day, at: ['4:30 am', '6:00 pm'] do
#   rake 'shop:sync_all'
# end

# Example: Run on specific days
# every :monday, at: '12:00 pm' do
#   rake 'reports:weekly'
# end

# Example: Run on weekdays only
# every :weekday, at: '9:00 am' do
#   rake 'notifications:send_daily'
# end

# Example: Run a custom job
# every 1.day, at: '3:00 am' do
#   runner 'Shop.find_each(&:sync_shop_data)'
# end

# Example: Run a raw command
# every 1.day, at: '5:00 am' do
#   command '/usr/bin/my_custom_script.sh'
# end
