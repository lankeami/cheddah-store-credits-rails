# Cheddah Rails - Shopify Embedded App

A containerized Ruby on Rails application configured as a Shopify embedded app with MySQL database.

## Features

- Ruby on Rails 7.1
- MySQL 8.0 database
- Shopify App Bridge integration
- Docker and Docker Compose setup
- Shopify embedded app authentication
- Ready for Shopify App Store deployment

## Prerequisites

- Docker and Docker Compose installed
- Shopify Partner account
- A Shopify development store (or production store for production use)

## Quick Start

### 1. Clone and Setup Environment

```bash
# Copy the example environment file
cp .env.example .env
```

### 2. Configure Shopify App

1. Go to your [Shopify Partner Dashboard](https://partners.shopify.com/)
2. Create a new app or use an existing one
3. Get your API credentials:
   - API Key
   - API Secret

4. Update your `.env` file:
```env
SHOPIFY_API_KEY=your_api_key_here
SHOPIFY_API_SECRET=your_api_secret_here
SCOPES=write_products,read_orders,read_customers
HOST=https://your-ngrok-url.ngrok.io
```

### 3. Configure App URLs in Shopify

You'll need a public URL for local development. Use [ngrok](https://ngrok.com/):

```bash
ngrok http 3000
```

In your Shopify Partner Dashboard, set:
- **App URL**: `https://your-ngrok-url.ngrok.io`
- **Allowed redirection URL(s)**:
  - `https://your-ngrok-url.ngrok.io/auth/shopify/callback`
  - `https://your-ngrok-url.ngrok.io/auth/callback`

Update the `HOST` variable in your `.env` file with your ngrok URL.

### 4. Build and Run with Docker

```bash
# Build the containers
docker-compose build

# Start the application
docker-compose up
```

The app will be available at `http://localhost:3000`

### 5. Install the App

Visit your app's installation URL:
```
https://your-ngrok-url.ngrok.io/login?shop=your-store.myshopify.com
```

Replace `your-store.myshopify.com` with your actual Shopify store domain.

## Development

### Running Commands

```bash
# Access Rails console
docker-compose exec web bundle exec rails console

# Run migrations
docker-compose exec web bundle exec rails db:migrate

# Generate a new migration
docker-compose exec web bundle exec rails generate migration MigrationName

# Run tests
docker-compose exec web bundle exec rails test

# View logs
docker-compose logs -f web
```

### Database

```bash
# Create database
docker-compose exec web bundle exec rails db:create

# Run migrations
docker-compose exec web bundle exec rails db:migrate

# Reset database
docker-compose exec web bundle exec rails db:reset

# Access MySQL console
docker-compose exec db mysql -uroot -ppassword cheddah_rails_development
```

### Stopping the Application

```bash
# Stop containers
docker-compose down

# Stop and remove volumes (clears database)
docker-compose down -v
```

## Project Structure

```
.
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb  # Base controller with Shopify auth
│   │   └── home_controller.rb         # Main app controller
│   ├── models/
│   │   └── shop.rb                    # Shop model for session storage
│   └── views/
│       ├── home/
│       │   └── index.html.erb         # Main app view
│       └── layouts/
│           ├── application.html.erb   # Default layout
│           └── embedded_app.html.erb  # Shopify embedded layout
├── config/
│   ├── initializers/
│   │   ├── shopify_app.rb             # Shopify configuration
│   │   └── content_security_policy.rb # CSP for embedded app
│   ├── database.yml                   # Database configuration
│   └── routes.rb                      # Application routes
├── db/
│   └── migrate/
│       └── *_create_shops.rb          # Shop table migration
├── docker-compose.yml                 # Docker services configuration
├── Dockerfile                         # Rails app container
├── Gemfile                            # Ruby dependencies
└── .env.example                       # Environment variables template
```

## Shopify Scopes

The app requests these scopes by default (configurable in `.env`):
- `write_products` - Create and modify products
- `read_orders` - Read order information
- `read_customers` - Read customer information

Modify the `SCOPES` environment variable to change required permissions.

## Production Deployment

### Environment Variables

Ensure these are set in your production environment:

```env
RAILS_ENV=production
SECRET_KEY_BASE=<generate with: rails secret>
SHOPIFY_API_KEY=<your_production_api_key>
SHOPIFY_API_SECRET=<your_production_api_secret>
HOST=https://your-production-domain.com
DATABASE_HOST=<your_mysql_host>
DATABASE_USERNAME=<your_mysql_user>
DATABASE_PASSWORD=<your_mysql_password>
```

### Building for Production

```bash
docker-compose -f docker-compose.yml build
```

### Security Considerations

- Always use HTTPS in production
- Keep your API secret secure
- Regularly update dependencies
- Use strong database passwords
- Enable database backups

## Troubleshooting

### Port Already in Use

If port 3000 is already in use, modify `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Use 3001 instead
```

### Database Connection Issues

Ensure the database container is healthy:
```bash
docker-compose ps
docker-compose logs db
```

### Shopify Authentication Errors

- Verify your API credentials in `.env`
- Check that your ngrok URL matches the HOST variable
- Ensure redirect URLs are configured in Shopify Partner Dashboard
- Clear browser cookies and try again

### Container Build Fails

```bash
# Clean rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

## Additional Resources

- [Shopify App Documentation](https://shopify.dev/docs/apps)
- [shopify_app gem](https://github.com/Shopify/shopify_app)
- [Shopify App Bridge](https://shopify.dev/docs/api/app-bridge)
- [Rails Guides](https://guides.rubyonrails.org/)

## License

This project is licensed under the MIT License.
