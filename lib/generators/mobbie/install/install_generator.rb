require 'rails/generators'
require 'rails/generators/migration'

module Mobbie
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      
      source_root File.expand_path('templates', __dir__)
      
      class_option :use_existing_user_model, 
                   type: :boolean, 
                   default: false,
                   desc: "Use your existing User model instead of creating Mobbie::User"
      
      def self.next_migration_number(dir)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
      
      def create_migrations
        if options[:use_existing_user_model]
          say "Skipping Mobbie::User table creation (using existing User model)", :yellow
          # Generate migration to add mobbie fields to existing users table
          generate "mobbie:user_migration", "User"
        else
          migration_template 'create_mobbie_users.rb.tt', 'db/migrate/create_mobbie_users.rb'
          sleep 1 # Ensure unique timestamps
          migration_template 'add_credit_balance_to_mobbie_users.rb.tt', 'db/migrate/add_credit_balance_to_mobbie_users.rb'
          sleep 1
        end
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
        @use_existing_user = options[:use_existing_user_model]
        template 'mobbie.rb', 'config/initializers/mobbie.rb'
      end
      
      def mount_engine
        route "mount Mobbie::Rails::Engine => '/', as: 'mobbie'"
      end
      
      def add_credentials_example
        say "\nJWT Configuration:", :yellow
        say "The gem will use your Rails app's secret_key_base by default."
        say "You can optionally override it by adding to credentials (rails credentials:edit):", :yellow
        say <<~CREDENTIALS
          mobbie:
            jwt_secret_key: #{SecureRandom.hex(32)}
        CREDENTIALS
        say "Or set the MOBBIE_JWT_SECRET_KEY environment variable."
      end
      
      def display_post_install_message
        say "\nMobbie Rails has been successfully installed!", :green
        say "\nNext steps:", :yellow
        say "1. Run 'rails db:migrate' to create the database tables"
        
        if options[:use_existing_user_model]
          say "2. Add 'include Mobbie::ActsAsMobbieUser' to your User model"
          say "3. Ensure config.user_class = 'User' is set in config/initializers/mobbie.rb"
        end
        
        say "#{options[:use_existing_user_model] ? '4' : '2'}. (Optional) Configure custom JWT secret key if needed"
        say "#{options[:use_existing_user_model] ? '5' : '3'}. (Optional) Run 'rails generate mobbie:sample_data' to create sample paywall data"
        say "#{options[:use_existing_user_model] ? '6' : '4'}. Configure your iOS app to point to: #{root_url}api"
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