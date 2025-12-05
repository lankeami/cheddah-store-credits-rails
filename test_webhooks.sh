#!/bin/bash

# Test webhook endpoints locally
# Make sure your Rails server is running first

HOST="http://localhost:3000"
SHOP_DOMAIN="cheddah-dev.myshopify.com"

echo "Testing webhooks..."
echo ""

# Test 1: customers/data_request
echo "1. Testing customers/data_request webhook..."
curl -X POST "$HOST/webhooks/customers_data_request" \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: test" \
  -d "{
    \"shop_domain\": \"$SHOP_DOMAIN\",
    \"customer\": {
      \"email\": \"test@example.com\",
      \"id\": 123456789
    }
  }"
echo ""
echo ""

# Test 2: customers/redact
echo "2. Testing customers/redact webhook..."
curl -X POST "$HOST/webhooks/customers_redact" \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: test" \
  -d "{
    \"shop_domain\": \"$SHOP_DOMAIN\",
    \"customer\": {
      \"email\": \"test@example.com\",
      \"id\": 123456789
    }
  }"
echo ""
echo ""

# Test 3: app/uninstalled
echo "3. Testing app/uninstalled webhook..."
curl -X POST "$HOST/webhooks/app_uninstalled" \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: test" \
  -d "{
    \"shop_domain\": \"$SHOP_DOMAIN\"
  }"
echo ""
echo ""

# Test 4: shop/redact
echo "4. Testing shop/redact webhook..."
curl -X POST "$HOST/webhooks/shop_redact" \
  -H "Content-Type: application/json" \
  -H "X-Shopify-Hmac-Sha256: test" \
  -d "{
    \"shop_domain\": \"$SHOP_DOMAIN\"
  }"
echo ""
echo ""

echo "Check your Rails logs at: docker-compose logs -f web"
