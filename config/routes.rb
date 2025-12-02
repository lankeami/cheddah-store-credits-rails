Rails.application.routes.draw do
  root to: 'home#index'
  mount ShopifyApp::Engine, at: '/'

  get 'home/index'

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
