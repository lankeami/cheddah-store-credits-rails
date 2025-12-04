# Layout & Navigation

The app now includes a professional layout with consistent navigation and breadcrumbs.

## Features

### 1. Header with Logo and Navigation
- **Logo**: Custom "₵" symbol with gradient background
- **App Name**: "Cheddah" brand name
- **Navigation Tabs**:
  - Store Credits
  - Campaigns
- **Active State**: Highlighted background for current page
- **Sticky Header**: Stays at top when scrolling
- **Shop Domain**: Displays current shop in top-right

### 2. Breadcrumbs
Shows your location in the app hierarchy with clickable links to navigate back.

Examples:
- `Home > Store Credits`
- `Home > Campaigns > Campaign Name`
- `Home > Campaigns > Campaign Name > Edit`

### 3. Flash Messages
Consistent styling for:
- Success messages (green)
- Error/Alert messages (red)
- Automatically positioned below breadcrumbs

### 4. Responsive Container
- Maximum width: 1400px
- Centered layout
- Consistent padding

## Using Breadcrumbs in Views

Add breadcrumbs to any view using the `content_for :breadcrumbs` block:

```erb
<% content_for :breadcrumbs do %>
  <%= breadcrumb 'Home', root_path(shopify_path_params) %>
  <%= breadcrumb_separator %>
  <%= breadcrumb 'Page Name', page_path(shopify_path_params) %>
  <%= breadcrumb_separator %>
  <%= breadcrumb 'Current Page' %>
<% end %>
```

**Important**:
- Always use `shopify_path_params` helper when generating links
- Last breadcrumb should NOT have a link (it's the current page)
- Use `breadcrumb_separator` between items

## Helper Methods

### `breadcrumb(text, path = nil)`
Creates a breadcrumb link or text:
- With path: Creates clickable link
- Without path: Creates non-clickable current page indicator

### `breadcrumb_separator`
Creates the "›" separator between breadcrumbs

### `shopify_path_params`
Returns hash with Shopify authentication parameters:
```ruby
{
  shop: params[:shop],
  host: params[:host],
  embedded: params[:embedded],
  id_token: params[:id_token]
}
```

Use this when creating links to preserve authentication state.

## Color Scheme

- **Primary Blue**: #5C6AC4 (Shopify-style)
- **Text Primary**: #202223
- **Text Secondary**: #6d7175
- **Border**: #e1e3e5
- **Background**: #f6f6f7
- **Success**: #d4edda / #155724
- **Error**: #f8d7da / #721c24

## Layout File

The main layout is in `app/views/layouts/application.html.erb` and includes:
- Meta tags
- CSS reset
- Header with logo and navigation
- Breadcrumb container
- Flash messages
- Main content area

All page-specific content goes in the `<%= yield %>` section.
