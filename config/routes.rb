Rails.application.routes.draw do
  root to: 'home#index'
  mount ShopifyApp::Engine, at: '/'

  get 'home/index'

  # Campaigns
  resources :campaigns, except: [:destroy]

  # Store Credits
  resources :store_credits, only: [:index] do
    collection do
      post :upload
    end
  end

  # Webhooks
  post 'webhooks/app_uninstalled', to: 'webhooks#app_uninstalled'

  # GDPR Webhooks (required by Shopify)
  post 'webhooks/customers_data_request', to: 'webhooks#customers_data_request'
  post 'webhooks/customers_redact', to: 'webhooks#customers_redact'
  post 'webhooks/shop_redact', to: 'webhooks#shop_redact'

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
