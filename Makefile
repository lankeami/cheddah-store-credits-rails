.PHONY: local build up down logs clean rebuild db-reset console help

# Tear down, rebuild from scratch, and run the app
local:
	@echo "🧹 Tearing down existing containers..."
	docker-compose down -v
	@echo "🔨 Rebuilding from scratch..."
	docker-compose build --no-cache
	@echo "🚀 Starting the application..."
	docker-compose up -d
	docker-compose logs -f web

# Restart the web container
restart:
	docker-compose restart web
	docker-compose logs -f web

# Build the containers
build:
	docker-compose build

# Start the application
up:
	docker-compose up

# Start in detached mode
up-d:
	docker-compose up -d

# Stop the application
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f web

# Clean everything (containers, volumes, images)
clean:
	@echo "🧹 Cleaning all containers, volumes, and images..."
	docker-compose down -v --rmi all --remove-orphans

# Rebuild without cache
rebuild:
	docker-compose build --no-cache

# Reset database
db-reset:
	docker-compose exec web bundle exec rails db:drop db:create db:migrate

# Run migrations
db-migrate:
	docker-compose exec web bundle exec rails db:migrate

# Open Rails console
console:
	docker-compose exec web bundle exec rails console

# Run tests
test:
	docker-compose exec web bundle exec rails test

# Install a gem (usage: make gem GEM=gem_name)
gem:
	docker-compose exec web bundle add $(GEM)
	docker-compose restart web

# Sync shop data from Shopify
sync-shops:
	docker-compose exec web bundle exec rake shop:sync_all

# Sync specific shop (usage: make sync-shop SHOP=store.myshopify.com)
sync-shop:
	docker-compose exec web bundle exec rake shop:sync[$(SHOP)]

# Preview whenever schedule
preview-schedule:
	docker-compose exec web bundle exec whenever

# Store Credits - cleanup expired credits
credits-cleanup:
	docker-compose exec web bundle exec rake store_credits:cleanup_expired

# Store Credits - show statistics
credits-stats:
	docker-compose exec web bundle exec rake store_credits:stats

# Store Credits - process all pending credits (queue jobs)
credits-process:
	docker-compose exec web bundle exec rake store_credits:process_all

# Store Credits - process specific shop NOW (usage: make credits-process-shop SHOP=store.myshopify.com)
credits-process-shop:
	docker-compose exec web bundle exec rake store_credits:process_shop[$(SHOP)]

# Test store credits - quick test (usage: make test-credits EMAIL=test@example.com)
test-credits:
	docker-compose exec web bundle exec rake test:credits:quick[$(EMAIL)]

# Test - check if customer exists (usage: make test-customer EMAIL=test@example.com)
test-customer:
	docker-compose exec web bundle exec rake test:credits:check_customer[$(EMAIL)]

# Test - create sample credits
test-create-samples:
	docker-compose exec web bundle exec rake test:credits:create_samples[5]

# Test - detailed status of all credits
test-credits-status:
	docker-compose exec web bundle exec rake test:credits:detailed_status

# Get the app install URL
install-url:
	@grep "^HOST=" .env | cut -d'=' -f2 | sed 's|$$|/login?shop=cheddah-dev.myshopify.com|'

# Help
help:
	@echo "Available commands:"
	@echo "  make local       - Tear down, rebuild from scratch, and run the app"
	@echo "  make build       - Build the Docker containers"
	@echo "  make up          - Start the application"
	@echo "  make up-d        - Start the application in detached mode"
	@echo "  make down        - Stop the application"
	@echo "  make logs        - View application logs"
	@echo "  make clean       - Remove all containers, volumes, and images"
	@echo "  make rebuild     - Rebuild without cache"
	@echo "  make db-reset    - Drop, create, and migrate database"
	@echo "  make db-migrate  - Run database migrations"
	@echo "  make console     - Open Rails console"
	@echo "  make test        - Run tests"
	@echo "  make gem GEM=name - Install a new gem"
	@echo "  make sync-shops  - Sync all shop data from Shopify"
	@echo "  make sync-shop SHOP=domain - Sync specific shop"
	@echo "  make preview-schedule - Preview the cron schedule"
	@echo "  make credits-cleanup - Remove expired store credits"
	@echo "  make credits-stats - Show store credits statistics"
	@echo "  make credits-process - Process pending credits (queue jobs)"
	@echo "  make credits-process-shop SHOP=domain - Process shop credits NOW"
	@echo "  make test-credits EMAIL=email - Run quick store credits test"
	@echo "  make test-customer EMAIL=email - Check if customer exists"
	@echo "  make test-create-samples - Create 5 sample test credits"
	@echo "  make test-credits-status - Show detailed credit status"
	@echo "  make install-url - Display the app install URL"
	@echo "  make help        - Show this help message"
