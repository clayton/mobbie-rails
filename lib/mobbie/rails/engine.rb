require 'rails/engine'
require 'jwt'
require 'bcrypt'

module Mobbie
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Mobbie
      
      config.generators do |g|
        g.orm :active_record
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end
      
      # Configure JWT settings
      config.mobbie = ActiveSupport::OrderedOptions.new
      config.mobbie.jwt_secret_key = nil # Will be set in initializer
      config.mobbie.jwt_expiration = 24.hours
      config.mobbie.jwt_refresh_expiration = 30.days
      
      # Don't auto-include authentication in all controllers
      # This was causing authentication to be required for all routes, including health checks
      # The Mobbie controllers will include this concern themselves
      
      initializer "mobbie.configure_jwt_secret", after: :load_config_initializers do
        # Set JWT secret key with proper fallback chain
        Mobbie::Rails.jwt_secret_key ||= ENV['MOBBIE_JWT_SECRET_KEY']
        Mobbie::Rails.jwt_secret_key ||= ::Rails.application.credentials.dig(:mobbie, :jwt_secret_key)
        Mobbie::Rails.jwt_secret_key ||= ::Rails.application.credentials.secret_key_base
        Mobbie::Rails.jwt_secret_key ||= ::Rails.application.secret_key_base
        
        # Set other configurations
        Mobbie::Rails.jwt_expiration = config.mobbie.jwt_expiration
        Mobbie::Rails.jwt_refresh_expiration = config.mobbie.jwt_refresh_expiration
      end
    end
  end
end