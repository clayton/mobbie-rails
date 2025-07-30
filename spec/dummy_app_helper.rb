# Create a minimal Rails application for testing
require 'rails'
require 'active_record'
require 'action_controller'
require 'active_job'

# Database setup
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Load schema
require_relative 'internal/db/schema'

# Configure Rails
Rails.application.configure do
  config.eager_load = false
  config.cache_classes = true
  config.secret_key_base = 'test_secret'
end

# Initialize Rails app
Rails.application.initialize!