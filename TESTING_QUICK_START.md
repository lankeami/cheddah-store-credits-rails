# Testing Store Credits - Quick Start

5-minute guide to test your store credits are working.

## Prerequisites

1. ✅ Development store at Shopify
2. ✅ App installed in dev store
3. ✅ At least one customer in Shopify (with a real email)

## Quick Test (3 steps)

### Step 1: Check if a customer exists

```bash
make test-customer EMAIL=your-customer@example.com
```

**Expected output:**
```
🔍 Looking up customer: your-customer@example.com
✓ Found customer:
  ID: gid://shopify/Customer/123
  Email: your-customer@example.com
  Name: John Doe
```

**If customer not found:** Create customer in Shopify Admin first.

### Step 2: Run quick test

```bash
make test-credits EMAIL=your-customer@example.com
```

**Expected output:**
```
============================================================
STORE CREDITS QUICK TEST
============================================================

📍 Shop: your-dev-store.myshopify.com
🔑 Scopes: read_products,write_products,read_customers,write_customers

🔍 Checking if customer exists...
✓ Customer found: John Doe (your-customer@example.com)

💳 Creating test credit...
✓ Credit created: ID #1
  Amount: $10.0
  Expires: 2024-12-04 23:00

⚡ Processing credit...
✓ SUCCESS! Credit applied to Shopify
  Shopify Credit ID: 123
  Amount: $10.00 USD
  Status: completed

✅ TEST PASSED - Check customer in Shopify Admin
============================================================
```

### Step 3: Verify in Shopify

1. Go to Shopify Admin → Customers
2. Find the customer
3. Check "Store credit" section
4. Should show $10.00 credit

## If Test Passes ✅

Your integration is working! You can now:

1. **Upload CSV files** at `/store_credits`
2. **Process automatically** - runs every hour
3. **Monitor** with `make credits-stats`

## If Test Fails ❌

### Error: "Customer not found"

**Cause:** Email doesn't exist in Shopify
**Fix:** Create customer in Shopify Admin first

### Error: "Insufficient permissions"

**Cause:** App doesn't have customer scopes
**Fix:**
1. Check scopes:
   ```bash
   make console
   # In console:
   Shop.first.access_scopes
   ```
2. If missing `read_customers,write_customers`, reinstall app

### Error: "Shop not found"

**Cause:** App not installed
**Fix:** Install app in your development store

## Additional Tests

### Create and process multiple credits

```bash
# Create 5 sample credits
make test-create-samples

# View them
make test-credits-status

# Process them
make credits-process-shop SHOP=your-dev-store.myshopify.com

# Check results
make credits-stats
```

### Test via CSV upload

1. Create `test.csv`:
   ```csv
   email,amount,expiry_hours
   customer1@example.com,25.00,72
   customer2@example.com,50.00,168
   ```

2. Upload at `/store_credits`

3. Process:
   ```bash
   make credits-process-shop SHOP=your-dev-store.myshopify.com
   ```

4. Verify in Shopify Admin

## Monitoring

```bash
# View statistics
make credits-stats

# Detailed status of each credit
make test-credits-status

# Watch logs
docker-compose exec web tail -f log/development.log | grep StoreCredit
```

## Complete Testing Documentation

For comprehensive testing scenarios, see:
- [Complete Testing Guide](docs/TESTING_STORE_CREDITS.md)
- [Shopify Integration Details](docs/SHOPIFY_INTEGRATION.md)

## Quick Reference

| Command | Description |
|---------|-------------|
| `make test-credits EMAIL=x` | Quick end-to-end test |
| `make test-customer EMAIL=x` | Check if customer exists |
| `make test-create-samples` | Create 5 test credits |
| `make test-credits-status` | Detailed status view |
| `make credits-stats` | Summary statistics |
| `make credits-process-shop SHOP=x` | Process credits NOW |

## Next Steps

1. ✅ Run quick test
2. ✅ Verify in Shopify Admin
3. 📤 Upload real CSV file
4. 📊 Monitor with `make credits-stats`
5. 🚀 Credits process automatically every hour!

## Troubleshooting

See [Complete Testing Guide](docs/TESTING_STORE_CREDITS.md#common-issues--solutions) for detailed troubleshooting.
