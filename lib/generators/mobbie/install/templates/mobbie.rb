# Mobbie Rails Configuration
#
# Configure the Mobbie Rails engine settings here.

Mobbie::Rails.configure do |config|
  # JWT Configuration
  # You can set the JWT secret key here or use Rails credentials
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