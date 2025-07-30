Mobbie::Rails::Engine.routes.draw do
  namespace :api do
    # Authentication routes
    post 'auth/anonymous', to: 'auth#anonymous'
    post 'auth/refresh', to: 'auth#refresh'
    
    # User routes
    patch 'users/link_apple_account', to: 'users#link_apple_account'
    
    # Paywall configuration
    get 'paywall_config', to: 'paywall_config#show'
    
    # Purchases and Subscriptions
    resources :purchases, only: [:create]
    resources :subscriptions, only: [:create, :index] do
      collection do
        get 'current'
      end
    end
    
    # Support tickets
    resources :support_requests, only: [:create]
  end
end