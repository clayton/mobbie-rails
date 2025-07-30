# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

# Load Rails first
require 'rails'
require 'active_record'
require 'action_controller'
require 'active_job'

# Create minimal Rails app
module TestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'test_secret'
  end
end

# Initialize Rails
Rails.application.initialize! unless Rails.application.initialized?

# Load the engine
require 'mobbie/rails'

# Setup database
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Load schema
ActiveRecord::Schema.define do
  create_table "mobbie_users", force: :cascade do |t|
    t.string "device_id"
    t.string "email"
    t.string "username"
    t.boolean "is_anonymous", default: true
    t.string "oauth_provider"
    t.string "oauth_uid"
    t.string "name"
    t.integer "credit_balance", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_mobbie_users_on_device_id", unique: true
    t.index ["email"], name: "index_mobbie_users_on_email"
  end

  create_table "mobbie_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_plan_id"
    t.string "original_transaction_id", null: false
    t.string "transaction_id", null: false
    t.string "product_id", null: false
    t.datetime "purchase_date", null: false
    t.datetime "expires_at", null: false
    t.string "platform", null: false
    t.string "status", null: false
    t.string "tier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "original_transaction_id", null: false
    t.string "transaction_id", null: false
    t.string "product_id", null: false
    t.integer "credits_granted", null: false
    t.datetime "purchase_date", null: false
    t.string "platform", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_support_tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject", null: false
    t.text "message", null: false
    t.string "category", default: "general"
    t.string "status", default: "open"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_paywall_configs", force: :cascade do |t|
    t.string "title", null: false
    t.string "subtitle", null: false
    t.string "welcome_title", null: false
    t.string "welcome_subtitle", null: false
    t.boolean "show_skip_button", default: true
    t.string "skip_button_text", null: false, default: "Skip"
    t.boolean "active", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_paywall_offerings", force: :cascade do |t|
    t.string "product_id", null: false
    t.string "display_name", null: false
    t.text "description"
    t.integer "cartoon_count"
    t.boolean "is_welcome_offer", default: false
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.string "badge_text"
    t.boolean "is_visible", default: true
    t.boolean "is_visible_for_onboarding", default: true
    t.bigint "paywall_config_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_paywall_features", force: :cascade do |t|
    t.string "title", null: false
    t.string "icon", null: false
    t.text "description", null: false
    t.integer "display_order", default: 0
    t.boolean "is_visible", default: true
    t.bigint "paywall_config_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_subscription_plans", force: :cascade do |t|
    t.string "product_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "tier", null: false
    t.string "billing_period", null: false
    t.integer "price_cents", default: 0
    t.string "currency", default: "USD"
    t.json "features", default: {}
    t.integer "display_order", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_paywall_display_settings", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "welcome_title"
    t.string "welcome_subtitle"
    t.boolean "show_skip_button", default: true
    t.string "skip_button_text", default: "Skip"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end

# Load test support files
require 'rspec/rails'
require 'factory_bot_rails'
require 'shoulda-matchers'
require 'faker'
require 'timecop'
require 'webmock/rspec'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Load support files
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

# Configure Mobbie
Mobbie::Rails.configure do |config|
  config.jwt_secret_key = 'test_secret_key'
  config.jwt_expiration = 24.hours
end

# Configure RSpec
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  
  config.include FactoryBot::Syntax::Methods
  config.include JwtTestHelper
  config.include AppleIapTestHelper
  
  # Clean database between tests
  config.before(:each) do
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == 'schema_migrations'
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
  end
end

# Load factories
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload