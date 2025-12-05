source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Rails
gem 'rails', '~> 7.1.0'

# Database
gem 'mysql2', '~> 0.5'

# Server
gem 'puma', '~> 6.0'

# Asset pipeline
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# JSON
gem 'jbuilder'

# Shopify
gem 'shopify_app', '~> 22.0'

# Cron job scheduling
gem 'whenever', require: false

# Pagination
gem 'kaminari'

# Performance
gem 'bootsnap', require: false

group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'dotenv-rails'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end
