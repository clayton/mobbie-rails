module Mobbie
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    
    # Helper method for defining user associations that work with configurable user class
    def self.belongs_to_mobbie_user(association_name = :user, **options)
      belongs_to association_name, -> { where(nil) }, **options.merge(
        class_name: -> { Mobbie::Rails.user_class }
      )
    end
  end
end