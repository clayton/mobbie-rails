require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
require 'active_job/railtie'

module Internal
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    
    # Configure Mobbie
    config.before_initialize do
      Mobbie::Rails.configure do |config|
        config.jwt_secret_key = 'test_secret_key_for_specs'
        config.jwt_expiration = 24.hours
        config.jwt_refresh_expiration = 30.days
      end
    end
  end
end