# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require 'combustion'

Combustion.path = 'spec/internal'
Combustion.initialize! :active_record, :active_job, :action_controller do
  config.active_record.migration_error = false
end

require 'mobbie/rails'

require 'rspec/rails'
require 'factory_bot_rails'
require 'faker'
require 'webmock/rspec'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

# Load factories
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Database cleaner setup
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Include route helpers after engine is loaded
  config.before(:suite) do
    Rails.application.routes.draw do
      mount Mobbie::Engine => "/api"
    end
  end

  # JWT test helpers
  config.include JwtTestHelper, type: :controller
  config.include JwtTestHelper, type: :request
end

# Disable WebMock by default
WebMock.disable_net_connect!(allow_localhost: true)

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end