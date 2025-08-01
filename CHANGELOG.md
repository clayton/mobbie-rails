## [Unreleased]

## [0.4.0] - 2025-08-01

### Added
- New `Mobbie::ActsAsMobbieUser` concern for integrating with existing User models
- Migration generator for adding Mobbie fields to existing users table
- Configurable user class support via `config.user_class`
- Installation option `--use-existing-user-model` for apps with existing User models
- All Mobbie fields are now prefixed with `mobbie_` to avoid conflicts
- Dynamic association handling for configurable user models
- Comprehensive documentation for migrating between user model approaches

### Changed
- Controllers now use configurable user model instead of hardcoded `Mobbie::User`
- `Mobbie::User` now uses the shared concern for backward compatibility
- Updated installation generator to support both user model patterns
- Improved documentation with detailed integration instructions

### Fixed
- User model collision issues in host Rails applications
- Association definitions now work with any configured user model

## [0.3.0] - 2025-07-30

### Added
- Support for credit packs and consumable purchases
- Smart restore functionality for recovering purchases
- Subscription plan management
- Enhanced paywall configuration

## [0.2.0] - 2025-07-25

### Added
- Paywall configuration system
- Support ticket management
- Apple In-App Purchase integration

## [0.1.0] - 2025-07-18

- Initial release
