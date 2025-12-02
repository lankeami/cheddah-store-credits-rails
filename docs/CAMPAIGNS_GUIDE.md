# Campaign Tracking Guide

Organize and track your store credit distributions with campaigns for easy debugging and reporting.

## What are Campaigns?

Campaigns allow you to group store credits together for tracking and analytics purposes. Each campaign has:
- **Unique ID** - Auto-generated system identifier
- **Custom Name** - Your own descriptive name (e.g., "Black Friday 2024", "Welcome Credits")
- **Description** - Optional detailed notes
- **Statistics** - Automatic tracking of credit counts and amounts

## Features

### Campaign Statistics

Each campaign automatically tracks:
- **Total Credits** - Number of credits created
- **Total Amount** - Sum of all credit amounts
- **Pending** - Credits not yet processed
- **Completed** - Successfully applied credits
- **Failed** - Credits that encountered errors

### Benefits

1. **Organization** - Group related credits together
2. **Debugging** - Quickly identify which campaign credits belong to
3. **Reporting** - See total amounts distributed per campaign
4. **Audit Trail** - Track when campaigns were created and who received credits

## Using Campaigns

### Creating a Campaign

1. Go to **Campaigns** from the home page
2. Click **New Campaign**
3. Enter a campaign name (required, must be unique)
4. Add optional description
5. Click **Create Campaign**

### Assigning Credits to a Campaign

**When Uploading CSV:**
1. Go to **Store Credits Manager**
2. Select a campaign from the dropdown (or leave as "None")
3. Upload your CSV file
4. All credits will be assigned to the selected campaign

**Example:**
```
Campaign: Black Friday 2024
CSV uploads → All credits tagged with this campaign
```

### Viewing Campaign Details

1. Go to **Campaigns**
2. Click on any campaign name
3. View:
   - Campaign statistics (total credits, amounts, status breakdown)
   - List of all credits in this campaign
   - Individual credit details and errors

### Editing a Campaign

1. Go to **Campaigns**
2. Click **Edit** on any campaign
3. Update name or description
4. Click **Update Campaign**

### Deleting a Campaign

1. Go to **Campaigns**
2. Click **Delete** on any campaign
3. Confirm deletion

**Note:** Deleting a campaign does NOT delete the credits. Credits will remain but lose their campaign association.

## Campaign Workflows

### Example 1: Seasonal Promotion

```
1. Create campaign: "Holiday 2024 Promotion"
   Description: "$25 credit for loyalty customers during holidays"

2. Upload CSV with customer emails
   - Select "Holiday 2024 Promotion" campaign
   - Upload file with 500 customers

3. Monitor progress:
   - View campaign page
   - Check completed vs failed counts
   - Review any error messages

4. Results:
   - Total: 500 credits
   - Total Amount: $12,500
   - Completed: 485
   - Failed: 15 (review errors)
```

### Example 2: Welcome Credits

```
1. Create campaign: "New Customer Welcome"
   Description: "$10 welcome credit for all new signups in Q4"

2. Upload weekly batches:
   Week 1: 50 customers → "New Customer Welcome"
   Week 2: 75 customers → "New Customer Welcome"
   Week 3: 60 customers → "New Customer Welcome"

3. View campaign totals:
   - Total: 185 credits
   - Total Amount: $1,850
   - Track cumulative impact
```

### Example 3: Testing & Debugging

```
1. Create campaign: "TEST - Nov 2024"
   Description: "Testing credit system with sample data"

2. Upload small test CSV
   - 5-10 test credits
   - Assign to TEST campaign

3. Process and verify:
   - Check campaign shows correct counts
   - Verify credits in Shopify
   - Review any errors

4. Clean up:
   - Delete test credits
   - Campaign shows accurate historical data
```

## Best Practices

### Naming Conventions

**Good Campaign Names:**
- "Black Friday 2024"
- "Welcome Credits - Q4 2024"
- "VIP Customer Appreciation"
- "Support Ticket Resolution Credits"

**Poor Campaign Names:**
- "test" (not descriptive)
- "credits" (too generic)
- "123" (meaningless)

### Using Descriptions

Add context that will help you later:
```
Name: Black Friday 2024
Description:
  Promotion period: Nov 24-27, 2024
  Target: Customers who spent $100+ in the past 6 months
  Credit amount: $25
  Expiry: 30 days
  Approval: Marketing team (email dated Nov 15)
```

### Campaign Organization

**By Event:**
- "Christmas 2024"
- "Valentine's Day 2025"
- "Back to School 2024"

**By Purpose:**
- "Customer Retention - Q4"
- "Service Recovery Credits"
- "Referral Rewards"

**By Segment:**
- "VIP Tier Credits"
- "New Customer Welcome"
- "Inactive Customer Win-back"

## API Integration

### Creating Credits with Campaign

When creating credits programmatically:

```ruby
# Find or create campaign
campaign = shop.campaigns.find_or_create_by!(
  name: "Black Friday 2024"
) do |c|
  c.description = "Holiday promotion credits"
end

# Create credits assigned to campaign
shop.store_credits.create!(
  email: "customer@example.com",
  amount: 25.00,
  expiry_hours: 72,
  campaign: campaign
)
```

### Querying Campaign Statistics

```ruby
campaign = Campaign.find(123)

# Get statistics
stats = campaign.stats
# => {
#   total_credits: 500,
#   total_amount: 12500.00,
#   pending: 10,
#   completed: 485,
#   failed: 5
# }

# Get credits
credits = campaign.store_credits
pending = campaign.store_credits.pending
failed = campaign.store_credits.failed
```

## Database Schema

### Campaigns Table

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Unique campaign ID (auto-generated) |
| shop_id | integer | Reference to shop |
| name | string | Campaign name (unique per shop) |
| description | text | Optional campaign details |
| created_at | datetime | When campaign was created |
| updated_at | datetime | Last modification time |

**Indexes:**
- Unique index on (shop_id, name)

### Store Credits Table

Added column:
- `campaign_id` (integer, nullable) - Reference to campaign

**Index:**
- Index on (campaign_id, status) for fast filtering

## Troubleshooting

### "Name has already been taken"

**Cause:** Campaign name must be unique per shop.

**Solution:**
- Use a different name
- Or edit the existing campaign instead

### Campaign shows wrong totals

**Possible causes:**
1. Credits were deleted
2. Credits were reassigned to different campaign

**Solution:** Statistics are calculated in real-time from current data.

### Can't delete campaign

**Check:**
- You must have permission to manage campaigns
- Try refreshing the page

**Note:** You can always delete campaigns - credits won't be deleted.

## Reports & Analytics

### View All Campaigns

Navigate to **Campaigns** to see:
- Campaign list sorted by creation date (newest first)
- Quick stats: Total credits and total amount
- Created date

### Campaign Detail Page

For each campaign, view:
- Full statistics breakdown
- Latest 100 credits (most recent first)
- Status indicators for each credit
- Error messages for failed credits

### Export Options

**Manual Export:**
1. View campaign details
2. Copy data from table
3. Paste into spreadsheet

**Programmatic Export:**
```ruby
campaign = Campaign.find(123)
csv_data = campaign.store_credits.to_csv
# Custom export logic
```

## Makefile Commands

The following commands work with campaigns:

```bash
# View all credits (includes campaign column)
make credits-stats

# Process credits (maintains campaign association)
make credits-process-shop SHOP=your-shop.myshopify.com

# Test credits (can optionally assign to campaign)
make test-credits EMAIL=test@example.com
```

## Advanced Usage

### Bulk Campaign Assignment

If you have existing credits without campaigns:

```ruby
# In Rails console
shop = Shop.first

# Create campaign
campaign = shop.campaigns.create!(
  name: "Backfill - Historical Credits",
  description: "Credits imported before campaign tracking"
)

# Assign all uncategorized credits
shop.store_credits.where(campaign_id: nil).update_all(campaign_id: campaign.id)
```

### Campaign-Based Processing

Process only credits from specific campaign:

```ruby
campaign = Campaign.find_by(name: "VIP Credits")

campaign.store_credits.pending.each do |credit|
  credit.process_now!
end
```

### Archive Old Campaigns

```ruby
# Mark campaign as archived (add archived column first via migration)
campaign.update!(archived: true)

# Or add description suffix
campaign.update!(name: "#{campaign.name} [ARCHIVED]")
```

## Next Steps

1. ✅ Create your first campaign
2. ✅ Upload credits assigned to the campaign
3. ✅ Monitor campaign statistics
4. 📊 Review campaign performance
5. 🔄 Refine your campaign strategy

## Related Documentation

- [Store Credits Guide](STORE_CREDITS_GUIDE.md)
- [Testing Guide](TESTING_STORE_CREDITS.md)
- [Shopify Integration](SHOPIFY_INTEGRATION.md)

---

**Questions or Issues?**

Check the main documentation or review campaign statistics to debug issues.
