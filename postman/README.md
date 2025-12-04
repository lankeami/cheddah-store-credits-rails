# Shopify Store Credits API - Postman Collection

This Postman collection helps you test the Shopify GraphQL API for creating customers and managing store credits.

## Setup

### 1. Import the Collection

1. Open Postman
2. Click **Import** → **File** → Select `Shopify_Store_Credits_API.postman_collection.json`
3. The collection will appear in your Collections sidebar

### 2. Configure Environment Variables

You need to set two variables:

#### Option A: Edit Collection Variables
1. Right-click the collection → **Edit**
2. Go to the **Variables** tab
3. Set the **Current Value** for:
   - `shop_domain`: Your shop domain (e.g., `cheddah-dev.myshopify.com`)
   - `access_token`: Your Shopify access token

#### Option B: Get Access Token from Database
Run this command to get your access token:

```bash
docker-compose exec web bin/rails runner "
  shop = Shop.find_by(shopify_domain: 'cheddah-dev.myshopify.com')
  puts 'Shop: ' + shop.shopify_domain
  puts 'Access Token: ' + shop.shopify_token
"
```

Copy the access token and paste it into Postman's `access_token` variable.

## Using the Collection

### Workflow: Create Customer and Add Store Credits

#### Step 1: Create a Customer
Run: **1. Create Customer**

- Modify the variables in the GraphQL query to use your desired email/name
- Copy the customer `id` from the response (format: `gid://shopify/Customer/123456`)

#### Step 2: Get Customer Details
Run: **2. Get Customer by Email**

- Update the `query` variable with your customer's email
- Check if they have any `storeCreditAccounts`
- If they have an account, copy the account `id` (format: `gid://shopify/StoreCreditAccount/123456`)

#### Step 3: Add Store Credit (IMPORTANT!)

**⚠️ Store Credit Account Must Exist First**

If the customer doesn't have a store credit account (empty `storeCreditAccounts` array), you must create it manually:

1. Go to Shopify Admin → Customers
2. Find the customer by email
3. Scroll to "Store credit" section
4. Click "Grant credit"
5. Add any small amount (even $0.01) to create the account
6. Save

Then run: **3. Add Store Credit**

- Replace `YOUR_ACCOUNT_ID_HERE` with the actual account ID
- Modify the `creditAmount` and `expiresAt` as needed
- The mutation will add credit to the existing account

### Additional Requests

**4. Get Store Credit Account Details**
- Query a specific account by ID to see balance and transactions

**5. List All Customers with Credits**
- View first 10 customers and their store credit balances
- Use pagination with `endCursor` for more results

**6. GraphQL Schema Introspection**
- Explore available fields and types in the Shopify API
- Useful for discovering new capabilities

## Common Issues

### Error: "Store credit account does not exist"
**Solution**: The customer needs a store credit account created first. Go to Shopify Admin and manually grant them a small credit (even $0.01) to create the account.

### Error: "Access denied"
**Solution**: Your access token might be missing the required scopes. Ensure you have:
- `write_customers` - To create customers
- `write_store_credit_account_transactions` - To add credits
- `read_store_credit_accounts` - To view balances

Reinstall the app to update scopes.

### Error: "Customer with email already exists"
**Solution**: The email is already in use. Either use a different email or look up the existing customer with request #2.

## Tips

1. **Save Customer IDs**: Keep a note of customer and account IDs for testing
2. **Use Variables**: Store commonly used IDs in Postman environment variables
3. **Test Mode**: Use a development store for testing
4. **Expiry Dates**: Use ISO 8601 format for `expiresAt` (e.g., `2025-12-31T23:59:59Z`)
5. **Currency**: Make sure to match your store's currency setting

## Example Workflow

```
1. Create Customer (newcustomer@example.com)
   → Returns: gid://shopify/Customer/7665513398351

2. Get Customer by Email (newcustomer@example.com)
   → Returns: No store credit accounts

3. Manually grant $0.01 in Shopify Admin
   → Creates account: gid://shopify/StoreCreditAccount/3172204623

4. Add Store Credit ($25.00)
   → Success! Balance is now $25.01

5. Get Store Credit Account Details
   → Confirms balance: $25.01 USD
```

## GraphQL Query Templates

### Create Customer with More Details
```graphql
mutation customerCreate($input: CustomerInput!) {
  customerCreate(input: $input) {
    customer {
      id
      email
      firstName
      lastName
      phone
      addresses {
        address1
        city
        province
        country
        zip
      }
    }
    userErrors {
      field
      message
    }
  }
}
```

Variables:
```json
{
  "input": {
    "email": "customer@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890",
    "addresses": [{
      "address1": "123 Main St",
      "city": "New York",
      "province": "NY",
      "country": "US",
      "zip": "10001"
    }]
  }
}
```

### Add Multiple Credits with Different Expiry
Run request #3 multiple times with different amounts and expiry dates to create multiple credit transactions on the same account.

## Resources

- [Shopify GraphQL Admin API Docs](https://shopify.dev/docs/api/admin-graphql)
- [Store Credits Documentation](https://shopify.dev/docs/api/admin-graphql/latest/objects/StoreCreditAccount)
- [Customer API Documentation](https://shopify.dev/docs/api/admin-graphql/latest/objects/Customer)
