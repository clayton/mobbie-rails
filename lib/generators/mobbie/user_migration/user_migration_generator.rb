require 'rails/generators'
require 'rails/generators/active_record'

module Mobbie
  module Generators
    class UserMigrationGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Generates a migration to add Mobbie fields to an existing users table"
      
      argument :name, type: :string, default: 'User', 
               desc: "The name of the existing user model (default: User)"
      
      def create_migration_file
        migration_template "add_mobbie_fields_to_users.rb.erb",
                          "db/migrate/add_mobbie_fields_to_#{table_name}.rb",
                          migration_version: migration_version
      end
      
      def show_next_steps
        say "\nNext steps:", :green
        say "1. Run 'rails db:migrate' to add the Mobbie fields to your #{name} model"
        say "2. Add 'include Mobbie::ActsAsMobbieUser' to your #{name} model"
        say "3. Configure Mobbie to use your user model in config/initializers/mobbie.rb:"
        say "   config.user_class = '#{name}'"
      end
      
      private
      
      def table_name
        name.tableize
      end
      
      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end