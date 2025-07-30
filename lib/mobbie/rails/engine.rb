require 'rails/engine'

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
      config.mobbie.jwt_secret_key = ENV['MOBBIE_JWT_SECRET_KEY'] || ::Rails.application.credentials.mobbie[:jwt_secret_key] rescue nil
      config.mobbie.jwt_expiration = 24.hours
      config.mobbie.jwt_refresh_expiration = 30.days
      
      initializer "mobbie.configure_rails_settings" do
        ActiveSupport.on_load(:action_controller) do
          include Mobbie::JwtAuthenticatable
        end
      end
    end
  end
end