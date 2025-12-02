Rails.application.routes.draw do
  root to: 'home#index'
  mount ShopifyApp::Engine, at: '/'

  get 'home/index'

  # Campaigns
  resources :campaigns

  # Store Credits
  resources :store_credits, only: [:index, :destroy] do
    collection do
      post :upload
      delete :destroy_all
    end
  end

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
