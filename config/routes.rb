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

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
