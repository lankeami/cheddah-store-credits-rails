#!/bin/bash

# Script to get Shopify access token for Postman testing

echo "=== Shopify Access Token for Postman ==="
echo ""

docker-compose exec web bin/rails runner "
shop = Shop.find_by(shopify_domain: 'cheddah-dev.myshopify.com')
if shop
  puts '✓ Shop Domain: ' + shop.shopify_domain
  puts '✓ Access Token: ' + shop.shopify_token
  puts ''
  puts 'Copy the access token above and paste it into Postman:'
  puts '1. Right-click the collection → Edit'
  puts '2. Go to Variables tab'
  puts '3. Set Current Value for access_token'
else
  puts '✗ Shop not found'
end
"
