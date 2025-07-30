# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in mobbie-rails.gemspec
gemspec

gem "irb"
gem "rake", "~> 13.0"

# Testing
group :development, :test do
  gem "rspec", "~> 3.0"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "webmock"
  gem "database_cleaner-active_record"
  gem "sqlite3"
  gem "jwt"
  gem "timecop"
end

gem "rubocop", "~> 1.21"

gem "claude-on-rails", "~> 0.2.0", group: :development
