require 'rails/generators'
require 'rails/generators/migration'

module Mobbie
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      
      source_root File.expand_path('templates', __dir__)
      
      def self.next_migration_number(dir)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
      
      def create_migrations
        migration_template 'create_mobbie_users.rb.tt', 'db/migrate/create_mobbie_users.rb'
        sleep 1 # Ensure unique timestamps
        migration_template 'add_credit_balance_to_mobbie_users.rb.tt', 'db/migrate/add_credit_balance_to_mobbie_users.rb'
        sleep 1
        migration_template 'create_mobbie_support_tickets.rb.tt', 'db/migrate/create_mobbie_support_tickets.rb'
        sleep 1
        migration_template 'create_mobbie_paywall_configs.rb.tt', 'db/migrate/create_mobbie_paywall_configs.rb'
        sleep 1
        migration_template 'create_mobbie_paywall_offerings.rb.tt', 'db/migrate/create_mobbie_paywall_offerings.rb'
        sleep 1
        migration_template 'create_mobbie_paywall_features.rb.tt', 'db/migrate/create_mobbie_paywall_features.rb'
        sleep 1
        migration_template 'create_mobbie_paywall_display_settings.rb.tt', 'db/migrate/create_mobbie_paywall_display_settings.rb'
        sleep 1
        migration_template 'add_paywall_config_to_paywall_models.rb.tt', 'db/migrate/add_paywall_config_to_paywall_models.rb'
        sleep 1
        migration_template 'create_mobbie_subscription_plans.rb.tt', 'db/migrate/create_mobbie_subscription_plans.rb'
        sleep 1
        migration_template 'create_mobbie_subscriptions.rb.tt', 'db/migrate/create_mobbie_subscriptions.rb'
        sleep 1
        migration_template 'create_mobbie_purchases.rb.tt', 'db/migrate/create_mobbie_purchases.rb'
      end
      
      def create_initializer
        template 'mobbie.rb', 'config/initializers/mobbie.rb'
      end
      
      def mount_engine
        route "mount Mobbie::Engine => '/api', as: 'mobbie'"
      end
      
      def add_credentials_example
        say "\nAdd the following to your Rails credentials (rails credentials:edit):", :yellow
        say <<~CREDENTIALS
          mobbie:
            jwt_secret_key: #{SecureRandom.hex(32)}
        CREDENTIALS
      end
      
      def display_post_install_message
        say "\nMobbie Rails has been successfully installed!", :green
        say "\nNext steps:", :yellow
        say "1. Run 'rails db:migrate' to create the database tables"
        say "2. Configure your JWT secret key in credentials or environment variables"
        say "3. Optionally run 'rails generate mobbie:sample_data' to create sample paywall data"
        say "4. Configure your iOS app to point to: #{root_url}api"
      end
      
      private
      
      def root_url
        Rails.application.routes.default_url_options[:host] || "http://localhost:3000/"
      rescue
        "http://localhost:3000/"
      end
    end
  end
end