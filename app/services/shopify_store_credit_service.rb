class ShopifyStoreCreditService
  attr_reader :shop, :session

  def initialize(shop)
    @shop = shop
    @session = ShopifyAPI::Auth::Session.new(
      shop: shop.shopify_domain,
      access_token: shop.shopify_token
    )
  end

  # Create or find a customer, ensure they have a store credit account, and add credit
  # This is the main method to use for adding credits, especially for new customers
  def create_customer_and_credit(email:, amount:, expires_at:, first_name: nil, last_name: nil, note: nil)
    # First, try to find existing customer
    customer = find_customer_with_store_credit_account(email)

    # If customer doesn't exist, create them
    unless customer
      Rails.logger.info("Customer #{email} not found, creating new customer...")
      result = create_customer(email: email, first_name: first_name, last_name: last_name)

      if result[:success]
        customer = result[:customer]
      else
        return {
          success: false,
          error: "Failed to create customer: #{result[:error]}"
        }
      end
    end

    # Now add the store credit
    create_store_credit(email: email, amount: amount, expires_at: expires_at, note: note)
  end

  # Create a customer account credit using GraphQL
  def create_store_credit(email:, amount:, expires_at:, note: nil)
    # Find customer and their store credit account
    customer = find_customer_with_store_credit_account(email)

    unless customer
      return {
        success: false,
        error: "Customer with email #{email} not found in Shopify. Use create_customer_and_credit to create the customer first."
      }
    end

    # Get the store credit account ID from the customer
    # Note: The storeCreditAccountCredit mutation will create the account if it doesn't exist
    account = customer.dig('storeCreditAccounts', 'edges', 0, 'node')

    if account
      # Account exists, use its ID
      account_id = account['id']
      Rails.logger.info("Using existing store credit account: #{account_id}")
    else
      # Account doesn't exist yet, derive the ID from customer ID
      # The mutation will create it automatically
      customer_id = customer['id']
      account_id = customer_id.gsub('/Customer/', '/StoreCreditAccount/')
      Rails.logger.info("Store credit account doesn't exist yet. Will be auto-created with ID: #{account_id}")
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

      # Check if it's the "account does not exist" error
      error_message = errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
      if error_message.include?('Store credit account does not exist')
        error_message += ". To fix: Go to Shopify Admin → Customers → #{email} → Grant a small store credit to create the account, then try again."
      end

      return {
        success: false,
        error: error_message
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

  # Find customer by email and include their store credit accounts
  def find_customer_with_store_credit_account(email)
    query = <<~GRAPHQL
      query getCustomerWithStoreCredit($query: String!) {
        customers(first: 1, query: $query) {
          edges {
            node {
              id
              storeCreditAccounts(first: 1) {
                edges {
                  node {
                    id
                    balance {
                      amount
                      currencyCode
                    }
                  }
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

  # Find customer by email using GraphQL (simple version without store credit data)
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

  # Create a new customer in Shopify
  def create_customer(email:, first_name: nil, last_name: nil)
    mutation = <<~GRAPHQL
      mutation customerCreate($input: CustomerInput!) {
        customerCreate(input: $input) {
          customer {
            id
            email
            firstName
            lastName
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    # Parse name from email if not provided
    if first_name.nil? && last_name.nil?
      email_parts = email.split('@').first.split(/[._-]/)
      first_name = email_parts.first&.capitalize || "New"
      last_name = email_parts.last&.capitalize if email_parts.length > 1
    end

    variables = {
      input: {
        email: email,
        firstName: first_name,
        lastName: last_name
      }.compact
    }

    Rails.logger.info("Creating customer with email: #{email}")
    response = execute_graphql(mutation, variables)
    Rails.logger.info("Customer creation response: #{response.inspect}")

    # Check for GraphQL errors
    if response['errors']
      Rails.logger.error("GraphQL errors: #{response['errors'].inspect}")
      return {
        success: false,
        error: response['errors'].map { |e| e['message'] }.join(', ')
      }
    end

    if response.dig('data', 'customerCreate', 'userErrors')&.any?
      errors = response['data']['customerCreate']['userErrors']
      Rails.logger.error("User errors: #{errors.inspect}")
      return {
        success: false,
        error: errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
      }
    end

    customer_data = response.dig('data', 'customerCreate', 'customer')

    if customer_data
      # Return the customer in the same format as find_customer_with_store_credit_account
      # but without store credit accounts since they don't exist yet
      {
        success: true,
        customer: {
          'id' => customer_data['id'],
          'email' => customer_data['email'],
          'storeCreditAccounts' => { 'edges' => [] }
        }
      }
    else
      Rails.logger.error("No customer data in response. Full response: #{response.inspect}")
      {
        success: false,
        error: 'Failed to create customer - no response from Shopify'
      }
    end
  rescue => e
    Rails.logger.error("Shopify API Error: #{e.message}\n#{e.backtrace.join("\n")}")
    {
      success: false,
      error: e.message
    }
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
