# Mobbie Rails

A mountable Rails engine that provides all the backend APIs, models, and controllers needed to support the [Mobbie iOS framework](https://github.com/clayton/Mobbie). This gem makes it easy to add iOS app backend support to any Rails application.

## Features

- 🔐 **JWT-based Authentication** - Anonymous and user authentication with secure token management
- 💳 **In-App Purchase Support** - Process and validate Apple IAP transactions for subscriptions and credit packs
- 📱 **Paywall Configuration** - Dynamic paywall offerings, features, and display settings
- 🎫 **Support Ticket System** - Handle user support requests with device information
- 💰 **Credit System** - Manage user credits for consumable purchases
- 🔄 **Smart Restore** - Restore previous purchases from Apple
- 🚀 **Easy Setup** - Rails generators for quick installation and configuration

## Requirements

- Ruby 3.1+
- Rails 7.1+ (supports up to Rails 9)
- A Rails application to mount the engine

## Installation

Add this line to your Rails application's Gemfile:

```ruby
gem 'mobbie-rails'
```

Then execute:

```bash
bundle install
```

## Quick Start

### 1. Run the installation generator

```bash
rails generate mobbie:install
```

This will:
- Create all necessary migrations
- Add an initializer for configuration
- Mount the engine routes at `/` (which provides `/api/*` endpoints)

### 2. Configure JWT secret (Optional)

By default, Mobbie Rails uses your Rails application's `secret_key_base` for JWT signing.

You can optionally override this by adding to your Rails credentials (`rails credentials:edit`):

```yaml
mobbie:
  jwt_secret_key: [your-secret-key-here]
```

Or set an environment variable:

```bash
MOBBIE_JWT_SECRET_KEY=your-secret-key-here
```

### 3. Run migrations

```bash
rails db:migrate
```

### 4. (Optional) Generate sample data

```bash
rails generate mobbie:sample_data
```

## API Documentation

All endpoints return JSON responses and expect JSON request bodies where applicable.

### Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

### Base Response Format

All responses follow a consistent format:

```json
{
  "success": true|false,
  "data": { /* response data */ },
  "error": "error message if success=false",
  "error_code": "specific_error_code"
}
```

### API Endpoints

#### Authentication

##### POST `/api/auth/anonymous`
Create an anonymous user session.

**Request:**
```json
{
  "device_id": "unique-device-identifier"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJ0eXAi...",
  "user": {
    "id": 1,
    "device_id": "unique-device-identifier",
    "is_anonymous": true,
    "email": null,
    "name": null
  },
  "permissions": {},
  "expires_at": "2024-01-01T12:00:00.000Z"
}
```

##### POST `/api/auth/refresh`
Refresh an existing JWT token.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "token": "eyJ0eXAi...",
  "user": { /* user object */ },
  "permissions": {},
  "expires_at": "2024-01-01T12:00:00.000Z"
}
```

#### User Management

##### PATCH `/api/users/link_apple_account`
Link an Apple account to the current user.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "apple_user_id": "001234.5678...",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "id": 1,
  "apple_user_id": "001234.5678...",
  "email": "user@example.com",
  "name": "John Doe",
  "is_anonymous": false
}
```

##### GET `/api/user/subscription_status`
Get the current user's subscription and feature status.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "tier": "premium",
  "premium": true,
  "subscription": {
    "plan_id": "com.yourapp.premium.weekly",
    "plan_name": "Weekly Premium",
    "status": "active",
    "billing_period": "week",
    "expires_at": "2024-01-08T12:00:00Z",
    "renews_at": "2024-01-08T12:00:00Z",
    "cancelled_at": null
  },
  "features": {
    "unlimited_stamps": true,
    "advanced_ai_analysis": true,
    "ebay_pricing": true,
    "listing_generator": true
  },
  "usage_limits": {
    "daily_limit": 10,
    "monthly_limit": 100,
    "used_today": 3,
    "used_this_month": 45,
    "remaining_today": 7,
    "remaining_this_month": 55,
    "resets_at": "2024-01-02T00:00:00Z"
  }
}
```

#### Subscriptions

##### GET `/api/subscription_plans`
Get available subscription plans.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
[
  {
    "product_id": "com.yourapp.premium.weekly",
    "name": "Weekly Premium",
    "tier": "premium",
    "billing_period": "week",
    "price": "$12.99",
    "features": ["Unlimited stamps", "Advanced AI", "eBay pricing"],
    "display_order": 1,
    "is_popular": true
  },
  {
    "product_id": "com.yourapp.premium.yearly",
    "name": "Yearly Premium",
    "tier": "premium",
    "billing_period": "year",
    "price": "$29.99",
    "features": ["Unlimited stamps", "Advanced AI", "eBay pricing"],
    "display_order": 2,
    "is_popular": false
  }
]
```

##### POST `/api/subscriptions`
Process a subscription purchase.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "product_id": "com.yourapp.premium.weekly",
  "jws_token": "eyJ0eXAi..."
}
```

**Response:**
```json
{
  "success": true,
  "subscription": {
    "plan_id": "com.yourapp.premium.weekly",
    "plan_name": "Weekly Premium",
    "status": "active",
    "billing_period": "week",
    "expires_at": "2024-01-08T12:00:00Z",
    "renews_at": "2024-01-08T12:00:00Z",
    "cancelled_at": null
  },
  "message": "Subscription activated successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "error_code": "validation_failed",
  "error": "Receipt validation failed"
}
```

Error codes:
- `validation_failed` - Apple receipt validation failed
- `product_mismatch` - Product ID doesn't match receipt
- `environment_mismatch` - Sandbox/production mismatch
- `missing_expiry` - No expiry date in receipt
- `database_error` - Failed to save subscription

##### GET `/api/subscriptions`
Get user's subscription history.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "subscriptions": [
    {
      "id": 123,
      "plan_id": "com.yourapp.premium.weekly",
      "plan_name": "Weekly Premium",
      "status": "active",
      "billing_period": "week",
      "expires_at": "2024-01-08T12:00:00Z",
      "renews_at": "2024-01-08T12:00:00Z",
      "cancelled_at": null,
      "days_remaining": 5
    }
  ]
}
```

##### GET `/api/subscriptions/current`
Get the user's current active subscription.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "subscription": { /* subscription object or null */ }
}
```

#### Purchases (Credit Packs)

##### POST `/api/purchases`
Process a credit pack purchase.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "product_id": "credit_pack_medium",
  "jws_token": "eyJ0eXAi..."
}
```

**Response:**
```json
{
  "success": true,
  "credits_added": 500,
  "total_credits": 650,
  "message": "Purchase successful",
  "data": {
    "purchase_id": 456,
    "credits_added": 500,
    "total_credits": 650,
    "transaction_id": "1000000123456789"
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error_code": "invalid_product",
  "error": "Unknown product ID"
}
```

Error codes:
- `missing_product_id` - Product ID not provided
- `missing_jws_token` - JWS token not provided
- `invalid_product` - Unknown product ID
- `product_mismatch` - Product ID doesn't match receipt
- `environment_mismatch` - Sandbox/production mismatch
- `duplicate_transaction` - Transaction already processed
- `validation_failed` - Apple receipt validation failed
- `database_error` - Failed to save purchase

Supported credit packs (with fallback values):
- `credit_pack_small`: 100 credits
- `credit_pack_medium`: 500 credits
- `credit_pack_large`: 1000 credits
- `credit_pack_xl`: 2500 credits

#### Paywall Configuration

##### GET `/api/paywall_config`
Get paywall configuration for the app.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "offerings": [
    {
      "id": 1,
      "product_id": "com.yourapp.premium.weekly",
      "name": "Weekly Premium",
      "tagline": "Best value for regular users",
      "pricing_text": "$12.99/week",
      "is_highlighted": true,
      "display_order": 1,
      "visible_on_launch": true,
      "visible_post_trial": true
    }
  ],
  "features": [
    {
      "id": 1,
      "icon": "sparkles",
      "title": "Unlimited Stamps",
      "description": "Scan as many stamps as you want",
      "is_premium": true,
      "display_order": 1
    }
  ],
  "display_settings": {
    "welcome_title": "Welcome to StampBrain",
    "welcome_message": "Get instant stamp valuations powered by AI",
    "skip_button_text": "Continue with limited access",
    "skip_button_enabled": true,
    "restore_button_enabled": true
  }
}
```

#### Smart Restore

##### POST `/api/smart_restore`
Restore previous purchases from Apple.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "transactions": [
    {
      "jws_token": "eyJ0eXAi...",
      "product_id": "com.yourapp.premium.weekly"
    },
    {
      "jws_token": "eyJ0eXAi...",
      "product_id": "credit_pack_medium"
    }
  ]
}
```

**Response:**
```json
{
  "restored_count": 2,
  "skipped_count": 0,
  "message": "Restored 2 subscription(s)",
  "subscription_status": {
    "tier": "premium",
    "premium": true,
    "subscription": { /* current subscription */ },
    "features": { /* enabled features */ },
    "usage_limits": null
  }
}
```

#### Support Requests

##### POST `/api/support_requests`
Submit a support request.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "message": "I'm having trouble with...",
  "app_version": "1.0.0",
  "device_info": {
    "model": "iPhone 15 Pro",
    "os_version": "17.2",
    "locale": "en_US"
  },
  "platform": "ios"
}
```

**Response:**
```json
{
  "support_ticket": {
    "id": 789,
    "name": "John Doe",
    "email": "john@example.com",
    "message": "I'm having trouble with...",
    "status": "open",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

### Error Handling

All endpoints use consistent error handling:

#### 400 Bad Request
```json
{
  "error": "Parameter 'device_id' is required"
}
```

#### 401 Unauthorized
```json
{
  "error": "Authentication required"
}
```

#### 404 Not Found
```json
{
  "error": "Record not found"
}
```

#### 422 Unprocessable Entity
```json
{
  "error": "Validation failed",
  "errors": ["Email is invalid", "Name is too short"]
}
```

#### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Configuration

Configure the engine in `config/initializers/mobbie.rb`:

```ruby
Mobbie::Rails.configure do |config|
  # JWT settings
  config.jwt_expiration = 24.hours
  config.jwt_refresh_expiration = 30.days
  
  # Apple IAP settings (optional - defaults shown)
  config.apple_production_url = "https://buy.itunes.apple.com/verifyReceipt"
  config.apple_sandbox_url = "https://sandbox.itunes.apple.com/verifyReceipt"
  
  # Credit pack definitions (optional - defaults shown)
  config.credit_packs = {
    'credit_pack_small' => 100,
    'credit_pack_medium' => 500,
    'credit_pack_large' => 1000,
    'credit_pack_xl' => 2500
  }
  
  # Subscription product definitions (optional - defaults shown)
  config.subscription_products = {
    'com.yourapp.premium.weekly' => {
      name: 'Weekly Premium',
      billing_period: 'week',
      price: '$12.99'
    },
    'com.yourapp.premium.yearly' => {
      name: 'Yearly Premium',
      billing_period: 'year',
      price: '$29.99'
    }
  }
end
```

## Models

### Core Models

#### Mobbie::User
Handles both anonymous and registered users.

```ruby
user = Mobbie::User.create!(device_id: "unique-device-id", is_anonymous: true)
user.link_apple_account(apple_user_id: "...", email: "...", name: "...")
user.active_subscription # => current subscription or nil
user.credits # => current credit balance
```

#### Mobbie::Subscription
Manages user subscriptions.

```ruby
subscription = user.subscriptions.create!(
  apple_product_id: "com.yourapp.premium.weekly",
  expires_at: 1.week.from_now,
  status: "active"
)
subscription.active? # => true
subscription.expired? # => false
subscription.days_remaining # => 7
```

#### Mobbie::Purchase
Tracks credit pack purchases.

```ruby
purchase = user.purchases.create!(
  apple_product_id: "credit_pack_medium",
  credits: 500,
  apple_transaction_id: "1000000123456789"
)
```

### Paywall Configuration Models

#### Mobbie::PaywallOffering
Product offerings displayed in the paywall.

#### Mobbie::PaywallFeature
Feature list shown in the paywall.

#### Mobbie::PaywallDisplaySettings
Customizable paywall UI text and settings.

### Support Models

#### Mobbie::SupportTicket
User support requests with device information.

## Extending Mobbie

### Custom User Model

```ruby
# app/models/user.rb
class User < Mobbie::User
  has_many :stamps
  has_many :collections
  
  def can_scan_stamps?
    active_subscription? || credits > 0
  end
end
```

### Custom Controllers

```ruby
# app/controllers/mobbie/api/custom_controller.rb
module Mobbie
  module Api
    class CustomController < Mobbie::ApplicationController
      def my_action
        # Access current_user, jwt methods, etc.
      end
    end
  end
end
```

### Adding Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Mobbie::Rails::Engine => "/"
  
  # Add custom routes within the Mobbie namespace
  namespace :api do
    namespace :mobbie do
      resources :custom_resources
    end
  end
end
```

## Testing

### Running Tests

```bash
cd path/to/mobbie-rails
bundle exec rspec
```

### Testing with Your App

Include test helpers in your specs:

```ruby
# spec/rails_helper.rb
require 'mobbie/rails/spec_helper'

RSpec.configure do |config|
  config.include Mobbie::Rails::AuthHelper, type: :request
end
```

Use the auth helper in tests:

```ruby
RSpec.describe "My API", type: :request do
  let(:user) { create(:mobbie_user) }
  let(:headers) { auth_headers_for(user) }
  
  it "requires authentication" do
    get "/api/protected", headers: headers
    expect(response).to have_http_status(:success)
  end
end
```

## Security Considerations

1. **JWT Secret**: Always use a strong, unique secret key for JWT signing
2. **HTTPS**: Always use HTTPS in production
3. **Apple IAP Validation**: The engine validates all receipts with Apple's servers
4. **Rate Limiting**: Implement rate limiting in your Rails app
5. **CORS**: Configure CORS appropriately for your iOS app

## Troubleshooting

### JWT Errors

If you see JWT-related errors, ensure:
1. Your secret key is configured correctly
2. The token hasn't expired
3. The Authorization header format is correct: `Bearer <token>`

### Apple IAP Validation Errors

Common issues:
1. **Environment mismatch**: Ensure your app uses sandbox receipts in development
2. **Invalid receipt**: Check that the JWS token is complete and unmodified
3. **Network issues**: The server needs to reach Apple's validation endpoints

### Database Errors

Run migrations if you see missing table/column errors:
```bash
rails db:migrate
```

## iOS Integration

Configure your Mobbie iOS app to use your Rails backend:

```swift
import Mobbie

Mobbie.configure(with: MobbieConfiguration(
    baseURL: URL(string: "https://your-app.com")!,
    enableLogging: true
))

// The iOS SDK will automatically handle:
// - Anonymous authentication on first launch
// - Token refresh when needed
// - Subscription and purchase processing
// - Paywall configuration fetching
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).