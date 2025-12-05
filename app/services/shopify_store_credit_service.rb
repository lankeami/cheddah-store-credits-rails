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
  def create_customer_and_credit(email:, amount:, expires_at:, first_name: nil, last_name: nil, note: nil, campaign_name: nil)
    # First, check if we have this customer cached in our database
    shopify_customer = shop.shopify_customers.find_by(email: email)

    # If not cached, look them up in Shopify
    unless shopify_customer
      customer = find_customer_with_store_credit_account(email)

      # If customer doesn't exist in Shopify, create them
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

      # Cache the customer in our database
      customer_gid = customer['id']
      customer_id = extract_gid(customer_gid)
      shopify_customer = ShopifyCustomer.find_or_create_from_shopify(
        shop: shop,
        email: email,
        shopify_customer_id: customer_id
      )
      Rails.logger.info("Cached customer #{email} with ID #{customer_id}")
    end

    # Add campaign tag if campaign_name is provided
    if campaign_name.present?
      customer_gid = "gid://shopify/Customer/#{shopify_customer.shopify_customer_id}"
      tag_result = add_customer_tag(customer_gid, "cheddah_campaign:#{campaign_name}")
      unless tag_result[:success]
        Rails.logger.warn("Failed to add campaign tag: #{tag_result[:error]}")
        # Continue processing even if tagging fails
      end
    end

    # Now add the store credit
    result = create_store_credit(email: email, amount: amount, expires_at: expires_at, note: note)

    # Ensure shopify_customer is always included in the result
    result[:shopify_customer] = shopify_customer

    result
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

    # Extract customer ID for later use
    customer_id = customer['id']
    Rails.logger.info("Creating store credit for customer: #{customer_id}")

    # Create the store credit using storeCreditAccountCredit mutation
    # Note: The mutation accepts Customer ID directly and will auto-create the store credit account if needed
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
            account {
              id
              balance {
                amount
                currencyCode
              }
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
      id: customer_id,
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
        error: response['errors'].map { |e| e['message'] }.join(', '),
        customer_id: extract_gid(customer_id)
      }
    end

    if response.dig('data', 'storeCreditAccountCredit', 'userErrors')&.any?
      errors = response['data']['storeCreditAccountCredit']['userErrors']
      Rails.logger.error("User errors: #{errors.inspect}")

      error_message = errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')

      return {
        success: false,
        error: error_message,
        customer_id: extract_gid(customer_id)
      }
    end

    credit_data = response.dig('data', 'storeCreditAccountCredit', 'storeCreditAccountTransaction')

    if credit_data
      {
        success: true,
        credit_id: extract_gid(credit_data['id']),
        customer_id: extract_gid(customer_id),
        amount: credit_data.dig('amount', 'amount'),
        currency: credit_data.dig('amount', 'currencyCode'),
        expires_at: credit_data['expiresAt']
      }
    else
      Rails.logger.error("No credit data in response. Full response: #{response.inspect}")
      {
        success: false,
        error: 'Failed to create store credit - no response from Shopify',
        customer_id: extract_gid(customer_id)
      }
    end
  rescue => e
    Rails.logger.error("Shopify API Error: #{e.message}\n#{e.backtrace.join("\n")}")
    # customer_id might not be available in rescue block, so only include if it exists
    result = {
      success: false,
      error: e.message
    }
    result[:customer_id] = extract_gid(customer_id) if defined?(customer_id) && customer_id
    result
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

  # Find customer by email
  # We can use the simpler query since we don't need store credit account info anymore
  def find_customer_with_store_credit_account(email)
    find_customer_by_email(email)
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
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    # Only include email - firstName and lastName require protected customer data access
    variables = {
      input: {
        email: email
      }
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
      # Return the customer in the same format as find_customer_by_email
      {
        success: true,
        customer: {
          'id' => customer_data['id']
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

  # Add a tag to a customer
  def add_customer_tag(customer_id, tag)
    mutation = <<~GRAPHQL
      mutation tagsAdd($id: ID!, $tags: [String!]!) {
        tagsAdd(id: $id, tags: $tags) {
          node {
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    variables = {
      id: customer_id,
      tags: [tag]
    }

    Rails.logger.info("Adding tag '#{tag}' to customer #{customer_id}")
    response = execute_graphql(mutation, variables)
    Rails.logger.info("Tag addition response: #{response.inspect}")

    # Check for GraphQL errors
    if response['errors']
      Rails.logger.error("GraphQL errors: #{response['errors'].inspect}")
      return {
        success: false,
        error: response['errors'].map { |e| e['message'] }.join(', ')
      }
    end

    if response.dig('data', 'tagsAdd', 'userErrors')&.any?
      errors = response['data']['tagsAdd']['userErrors']
      Rails.logger.error("User errors: #{errors.inspect}")
      return {
        success: false,
        error: errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
      }
    end

    {
      success: true
    }
  rescue => e
    Rails.logger.error("Tag addition error: #{e.message}")
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
