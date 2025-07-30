# Testing Mobbie Rails

This guide covers the test suite for the Mobbie Rails engine.

## Running Tests

### Run all tests
```bash
bundle exec rspec
```

### Run specific test files
```bash
bundle exec rspec spec/models/mobbie/subscription_spec.rb
bundle exec rspec spec/controllers/mobbie/api/subscriptions_controller_spec.rb
```

### Run tests with coverage
```bash
COVERAGE=true bundle exec rspec
```

## Test Structure

### Model Tests (`spec/models/`)
- Subscription lifecycle and status management
- Purchase validation and credit tracking
- User authentication and subscription methods
- PaywallConfig and related models

### Controller Tests (`spec/controllers/`)
- API authentication and JWT handling
- Subscription purchase flow
- Credit purchase processing
- Paywall configuration API

### Service Tests (`spec/services/`)
- Apple IAP receipt validation
- JWS token parsing
- Environment validation

### Integration Tests (`spec/requests/`)
- Complete subscription purchase flow
- Subscription upgrades and downgrades
- Subscription restoration across devices
- Credit purchase and balance management

### Job Tests (`spec/jobs/`)
- Subscription expiry processing
- Batch processing of expired subscriptions

## Test Helpers

### JWT Test Helper
Provides methods for generating test JWT tokens and auth headers:
```ruby
auth_headers(user)  # Returns headers with valid JWT
generate_jwt_token(user)  # Returns JWT token string
```

### Apple IAP Test Helper
Mocks Apple receipt validation:
```ruby
mock_apple_validation_success(product_id: 'com.mobbie.premium.weekly')
mock_apple_validation_failure('Invalid receipt')
generate_mock_jws_token(product_id: 'com.mobbie.premium.weekly')
```

## Factories

The test suite uses FactoryBot for test data:

```ruby
# Users
create(:mobbie_user)
create(:mobbie_user, :anonymous)
create(:mobbie_user, :with_active_subscription)

# Subscriptions
create(:mobbie_subscription, :active)
create(:mobbie_subscription, :expired)
create(:mobbie_subscription, :yearly)

# Purchases
create(:mobbie_purchase, :large_pack)
create(:mobbie_purchase, :admin_granted)

# Paywall
create(:mobbie_paywall_config, :complete)
create(:mobbie_paywall_offering, :yearly)
create(:mobbie_paywall_feature, :premium_templates)
```

## Test Coverage Areas

### Authentication
- JWT token generation and validation
- Token expiration handling
- Anonymous user authentication
- Apple account linking

### Subscriptions
- Purchase validation with Apple
- Subscription creation and updates
- Expiry and grace period handling
- Cross-device restoration
- Upgrade/downgrade scenarios

### Credits
- Purchase processing
- Balance management
- Transaction tracking

### Paywalls
- Dynamic configuration
- Offering visibility rules
- Feature management

## Continuous Integration

Tests are automatically run on:
- Pull requests
- Commits to main branch
- Tagged releases

## Troubleshooting

### Database Issues
If you encounter database errors, reset the test database:
```bash
RAILS_ENV=test bundle exec rake db:reset
```

### Factory Errors
Ensure all factories are loaded:
```bash
bundle exec rake factory_bot:lint
```

### WebMock Errors
If external API calls fail, check that WebMock stubs are properly configured in test setup.