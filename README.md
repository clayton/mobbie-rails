# Mobbie Rails

A mountable Rails engine that provides all the backend APIs, models, and controllers needed to support the [Mobbie iOS framework](https://github.com/clayton/Mobbie). This gem makes it easy to add iOS app backend support to any Rails application.

## Features

- 🔐 **JWT-based Authentication** - Anonymous and user authentication with secure token management
- 💳 **Paywall Configuration** - Dynamic paywall offerings, features, and display settings
- 🎫 **Support Ticket System** - Handle user support requests with device information
- 🚀 **Easy Setup** - Rails generators for quick installation and configuration
- 📱 **iOS Optimized** - Designed specifically for the Mobbie iOS framework

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
- Mount the engine routes at `/api`

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

## API Endpoints

All endpoints are mounted under `/api` by default.

### Authentication

```
POST /api/auth/anonymous
Body: { "device_id": "unique-device-id" }

POST /api/auth/refresh
Headers: Authorization: Bearer [token]

PATCH /api/users/link_apple_account
Headers: Authorization: Bearer [token]
Body: { "apple_user_id": "...", "email": "...", "name": "..." }
```

### Paywall Configuration

```
GET /api/paywall_config
Headers: Authorization: Bearer [token]
```

### Support Tickets

```
POST /api/support_requests
Body: { "name": "...", "email": "...", "message": "...", "app_version": "...", "device_info": "{...}", "platform": "ios" }
```

## Configuration

Configure the engine in `config/initializers/mobbie.rb`:

```ruby
Mobbie::Rails.configure do |config|
  # JWT settings
  config.jwt_expiration = 24.hours
  config.jwt_refresh_expiration = 30.days
end
```

## Models

### Mobbie::User
- Handles both anonymous and registered users
- Supports Apple Sign In linking
- JWT token generation

### Mobbie::PaywallOffering
- Product offerings with pricing tiers
- Visibility controls for different contexts

### Mobbie::PaywallFeature
- Feature list for paywall display
- Icon and description support

### Mobbie::PaywallDisplaySettings
- Customizable paywall UI text
- Welcome messages and skip button configuration

### Mobbie::SupportTicket
- User support requests
- Device information tracking
- Status management

## Customization

### Extending Models

You can extend Mobbie models in your application:

```ruby
# app/models/user.rb
class User < Mobbie::User
  # Add your custom methods and associations
  has_many :purchases
  
  def premium?
    purchases.active.any?
  end
end
```

### Custom Controllers

Override engine controllers for custom behavior:

```ruby
# app/controllers/mobbie/api/auth_controller.rb
module Mobbie
  module Api
    class AuthController < Mobbie::Api::AuthController
      # Override methods as needed
      def anonymous
        # Custom logic
        super
      end
    end
  end
end
```

## iOS Integration

Point your Mobbie iOS app to your Rails backend:

```swift
Mobbie.configure(with: MobbieConfiguration(
    baseURL: URL(string: "https://your-app.com")!,
    // ... other config
))
```

## Testing

The gem includes RSpec tests. To run them:

```bash
cd mobbie-rails
bundle exec rspec
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).