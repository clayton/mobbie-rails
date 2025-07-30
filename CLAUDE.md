# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
```bash
# Run all tests
bundle exec rspec

# Run tests with detailed output
bundle exec rspec -fd

# Run a specific test file
bundle exec rspec spec/path/to/spec.rb

# Run tests matching a pattern
bundle exec rspec spec/models/
```

### Linting
```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a
```

### Default Task (runs tests and linting)
```bash
bundle exec rake
```

## Architecture

### Engine Structure
This is a Rails mountable engine (isolate_namespace Mobbie) that provides backend APIs for the Mobbie iOS framework. Key architectural decisions:

1. **Namespace Isolation**: All models, controllers, and routes are namespaced under `Mobbie::` to avoid conflicts with host applications.

2. **JWT Authentication**: Uses JWT tokens with configurable expiration. Authentication is handled by the `Mobbie::JwtAuthenticatable` concern included in all API controllers.

3. **API Controllers**: Located in `app/controllers/mobbie/api/`, all inherit from `Mobbie::ApplicationController`.

### Key Components

**Authentication Flow**:
- Anonymous auth via device ID creates temporary users
- Users can link Apple accounts to persist data
- JWT tokens handle session management with refresh capability

**Models**:
- `Mobbie::User`: Core user model supporting anonymous and registered states
- `Mobbie::Subscription` & `Mobbie::Purchase`: Handle in-app purchases
- `Mobbie::PaywallConfig` and related models: Dynamic paywall configuration system
- All models inherit from `Mobbie::ApplicationRecord`

**Services**:
- `Mobbie::AppleIapService`: Validates Apple in-app purchase receipts with Apple's servers

**Testing Strategy**:
- Uses RSpec with FactoryBot for test data
- `spec/simple_spec_helper.rb`: Lightweight spec helper for unit tests without Rails
- `spec/rails_helper.rb`: Full Rails testing environment with Combustion
- WebMock for external API mocking

### Configuration
JWT settings default to using the Rails app's secret_key_base, with optional overrides:
- Priority: `ENV['MOBBIE_JWT_SECRET_KEY']` → `credentials.mobbie[:jwt_secret_key]` → `credentials.secret_key_base` → `Rails.application.secret_key_base`
- Configuration options in `config/initializers/mobbie.rb` (generated on install)