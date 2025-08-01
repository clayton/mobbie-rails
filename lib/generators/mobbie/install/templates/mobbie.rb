# Mobbie Rails Configuration
#
# Configure the Mobbie Rails engine settings here.

Mobbie::Rails.configure do |config|
  # User Model Configuration
  # Specify which model to use for Mobbie users
  # Default: 'Mobbie::User' (uses Mobbie's built-in User model)
  # To use your existing User model: config.user_class = 'User'
<% if @use_existing_user %>
  config.user_class = 'User'
<% else %>
  # config.user_class = 'User'
<% end %>
  
  # JWT Configuration
  # The JWT secret key defaults to your Rails app's secret_key_base
  # You can override it here or set via environment variable
  # config.jwt_secret_key = ENV['MOBBIE_JWT_SECRET_KEY']
  
  # Token expiration times
  config.jwt_expiration = 24.hours
  config.jwt_refresh_expiration = 30.days
  
  # Apple In-App Purchase Configuration (optional)
  # Required only if you want server-side receipt validation
  # config.apple_issuer_id = ENV['APPLE_ISSUER_ID']
  # config.apple_key_id = ENV['APPLE_KEY_ID']
  # config.apple_private_key = ENV['APPLE_PRIVATE_KEY']
  # config.apple_bundle_id = ENV['APPLE_BUNDLE_ID']
  
  # Subscription Products Configuration (optional)
  # Override the default subscription products
  # config.subscription_products = {
  #   'com.yourapp.premium.weekly' => {
  #     name: 'Weekly Premium',
  #     price_cents: 1299,
  #     billing_period: 'week',
  #     tier: 'premium'
  #   },
  #   'com.yourapp.premium.yearly' => {
  #     name: 'Yearly Premium',
  #     price_cents: 2999,
  #     billing_period: 'year',
  #     tier: 'premium'
  #   }
  # }
end