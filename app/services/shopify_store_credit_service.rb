class ShopifyStoreCreditService
  attr_reader :shop, :session

  def initialize(shop)
    @shop = shop
    @session = ShopifyAPI::Auth::Session.new(
      shop: shop.shopify_domain,
      access_token: shop.shopify_token
    )
  end

  # Create a customer account credit using GraphQL
  def create_store_credit(email:, amount:, expires_at:, note: nil)
    # First, find or get customer by email
    customer = find_customer_by_email(email)

    unless customer
      return {
        success: false,
        error: "Customer with email #{email} not found in Shopify"
      }
    end

    customer_id = customer['id']

    # Create the store credit using customerCreditGrant mutation
    mutation = <<~GRAPHQL
      mutation customerCreditGrant($input: CustomerCreditGrantInput!) {
        customerCreditGrant(input: $input) {
          customerCredit {
            id
            amount {
              value
              currencyCode
            }
            expiresAt
            customer {
              id
              email
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    variables = {
      input: {
        customerId: customer_id,
        amount: {
          amount: amount.to_s,
          currencyCode: shop.currency || 'USD'
        },
        expiresAt: expires_at.iso8601,
        note: note || "Store credit from bulk upload"
      }
    }

    response = execute_graphql(mutation, variables)

    if response.dig('data', 'customerCreditGrant', 'userErrors')&.any?
      errors = response['data']['customerCreditGrant']['userErrors']
      return {
        success: false,
        error: errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
      }
    end

    credit_data = response.dig('data', 'customerCreditGrant', 'customerCredit')

    if credit_data
      {
        success: true,
        credit_id: extract_gid(credit_data['id']),
        amount: credit_data.dig('amount', 'value'),
        currency: credit_data.dig('amount', 'currencyCode'),
        expires_at: credit_data['expiresAt']
      }
    else
      {
        success: false,
        error: 'Failed to create store credit - no response from Shopify'
      }
    end
  rescue => e
    Rails.logger.error("Shopify API Error: #{e.message}\n#{e.backtrace.join("\n")}")
    {
      success: false,
      error: e.message
    }
  end

  # Find customer by email using GraphQL
  def find_customer_by_email(email)
    query = <<~GRAPHQL
      query getCustomerByEmail($email: String!) {
        customers(first: 1, query: $email) {
          edges {
            node {
              id
              email
              displayName
            }
          }
        }
      }
    GRAPHQL

    variables = {
      email: "email:#{email}"
    }

    response = execute_graphql(query, variables)
    customers = response.dig('data', 'customers', 'edges')

    return nil if customers.nil? || customers.empty?

    customers.first['node']
  end

  # Get customer credit balance
  def get_customer_credits(customer_email)
    customer = find_customer_by_email(customer_email)
    return [] unless customer

    query = <<~GRAPHQL
      query getCustomerCredits($customerId: ID!) {
        customer(id: $customerId) {
          id
          email
          creditBalance {
            value
            currencyCode
          }
        }
      }
    GRAPHQL

    variables = {
      customerId: customer['id']
    }

    response = execute_graphql(query, variables)
    response.dig('data', 'customer', 'creditBalance')
  end

  private

  def execute_graphql(query, variables = {})
    client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    response = client.query(query: query, variables: variables)

    if response.body.is_a?(Hash)
      response.body
    else
      JSON.parse(response.body)
    end
  rescue => e
    Rails.logger.error("GraphQL execution error: #{e.message}")
    raise
  end

  # Extract numeric ID from GraphQL Global ID
  # e.g., "gid://shopify/CustomerCredit/123" => "123"
  def extract_gid(gid)
    gid.to_s.split('/').last
  end
end
