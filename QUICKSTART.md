# Quick Start Guide

Get your Shopify app running in 5 minutes!

## Step 1: Get Shopify Credentials

1. Go to https://partners.shopify.com/
2. Create a new app (or use existing)
3. Note your **API Key** and **API Secret**

## Step 2: Setup ngrok

```bash
# Install ngrok if you haven't
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Start ngrok
ngrok http 3000
```

You'll get a URL like: `https://abc123.ngrok.io`

## Step 3: Configure Shopify App URLs

In your Shopify Partner Dashboard, set:

- **App URL**: `https://abc123.ngrok.io`
- **Allowed redirection URLs**:
  - `https://abc123.ngrok.io/auth/shopify/callback`
  - `https://abc123.ngrok.io/auth/callback`

## Step 4: Update Environment Variables

Edit the `.env` file:

```env
SHOPIFY_API_KEY=paste_your_api_key
SHOPIFY_API_SECRET=paste_your_api_secret
HOST=https://abc123.ngrok.io
```

## Step 5: Start the App

```bash
# Build and start containers
docker-compose up --build
```

Wait for the message: `* Listening on http://0.0.0.0:3000`

## Step 6: Install to Your Store

Visit: `https://abc123.ngrok.io/login?shop=your-store.myshopify.com`

Replace `your-store` with your actual Shopify store name.

## Done!

Your app should now be installed and running. You'll see the welcome page with your shop information.

## Common Issues

**Port 3000 in use?**
```bash
# Stop any process using port 3000
lsof -ti:3000 | xargs kill -9
```

**Need to rebuild?**
```bash
docker-compose down -v
docker-compose up --build
```

**Check logs?**
```bash
docker-compose logs -f web
```

## Next Steps

- Edit `app/views/home/index.html.erb` to customize your app
- Add new routes in `config/routes.rb`
- Create controllers in `app/controllers/`
- Access Shopify API through the `Shop` model

Happy coding!
