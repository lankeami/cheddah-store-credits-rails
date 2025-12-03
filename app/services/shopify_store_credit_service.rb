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
    # Find the store credit account for this email
    account_id = find_customer_id_for_store_credit(email)

    unless account_id
      return {
        success: false,
        error: "Store credit account not found for #{email}. Please ensure the customer exists and has a store credit account enabled."
      }
    end

    # Create the store credit using storeCreditAccountCredit mutation
    mutation = <<~GRAPHQL
      mutation storeCreditAccountCredit($id: ID!, $creditInput: StoreCreditAccountCreditInput!) {
        storeCreditAccountCredit(id: $id, creditInput: $creditInput) {
          storeCreditAccountTransaction {
            id
            amount {
              amount
              currencyCode
            }
            expiresAt
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    variables = {
      id: account_id,
      creditInput: {
        creditAmount: {
          amount: amount.to_s,
          currencyCode: shop.currency || 'USD'
        },
        expiresAt: expires_at.iso8601
      }
    }

    response = execute_graphql(mutation, variables)

    Rails.logger.info("storeCreditAccountCredit response: #{response.inspect}")

    # Check for GraphQL errors
    if response['errors']
      Rails.logger.error("GraphQL errors: #{response['errors'].inspect}")
      return {
        success: false,
        error: response['errors'].map { |e| e['message'] }.join(', ')
      }
    end

    if response.dig('data', 'storeCreditAccountCredit', 'userErrors')&.any?
      errors = response['data']['storeCreditAccountCredit']['userErrors']
      Rails.logger.error("User errors: #{errors.inspect}")
      return {
        success: false,
        error: errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
      }
    end

    credit_data = response.dig('data', 'storeCreditAccountCredit', 'storeCreditAccountTransaction')

    if credit_data
      {
        success: true,
        credit_id: extract_gid(credit_data['id']),
        amount: credit_data.dig('amount', 'amount'),
        currency: credit_data.dig('amount', 'currencyCode'),
        expires_at: credit_data['expiresAt']
      }
    else
      Rails.logger.error("No credit data in response. Full response: #{response.inspect}")
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

  # Find store credit account ID for an email
  # Uses storeCreditAccounts query which doesn't require protected customer data access
  def find_customer_id_for_store_credit(email)
    query = <<~GRAPHQL
      query getStoreCreditAccounts($query: String!) {
        storeCreditAccounts(first: 1, query: $query) {
          edges {
            node {
              id
              owner {
                ... on Customer {
                  email
                }
              }
            }
          }
        }
      }
    GRAPHQL

    variables = {
      query: "email:#{email}"
    }

    Rails.logger.info("Searching for store credit account with query: #{variables[:query]}")
    response = execute_graphql(query, variables)
    Rails.logger.info("Store credit account search response: #{response.inspect}")

    accounts = response.dig('data', 'storeCreditAccounts', 'edges')

    return nil if accounts.nil? || accounts.empty?

    accounts.first.dig('node', 'id')
  end

  # Find customer by email using GraphQL
  def find_customer_by_email(email)
    query = <<~GRAPHQL
      query getCustomerByEmail($query: String!) {
        customers(first: 1, query: $query) {
          edges {
            node {
              id
            }
          }
        }
      }
    GRAPHQL

    variables = {
      query: "email:#{email}"
    }

    Rails.logger.info("Searching for customer with query: #{variables[:query]}")
    response = execute_graphql(query, variables)
    Rails.logger.info("Customer search response: #{response.inspect}")

    # Check for errors
    if response['errors']
      Rails.logger.error("GraphQL errors: #{response['errors'].inspect}")
      return nil
    end

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
