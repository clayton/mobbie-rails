Mobbie::Rails::Engine.routes.draw do
  # No namespace needed - will be mounted at /api/v1/mobbie
  
  # Authentication routes
  post 'auth/anonymous', to: 'api/auth#anonymous'
  post 'auth/refresh', to: 'api/auth#refresh'
  
  # User routes
  patch 'users/link_apple_account', to: 'api/users#link_apple_account'
  get 'user/subscription_status', to: 'api/users#subscription_status'
  
  # Paywall configuration
  get 'paywall_config', to: 'api/paywall_config#show'
  
  # Purchases and Subscriptions
  resources :purchases, only: [:create], controller: 'api/purchases'
  resources :subscriptions, only: [:create, :index], controller: 'api/subscriptions' do
    collection do
      get 'current'
    end
  end
  resources :subscription_plans, only: [:index], controller: 'api/subscription_plans'
  
  # Support tickets
  resources :support_requests, only: [:create], controller: 'api/support_requests'
  
  # Smart restore
  post 'smart_restore', to: 'api/smart_restore#create'
end