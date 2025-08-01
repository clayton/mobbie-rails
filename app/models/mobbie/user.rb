module Mobbie
  class User < Mobbie::ApplicationRecord
    self.table_name = "mobbie_users"
    
    # Map old field names to new prefixed names for backward compatibility
    alias_attribute :device_id, :mobbie_device_id
    alias_attribute :is_anonymous, :mobbie_is_anonymous
    alias_attribute :oauth_provider, :mobbie_oauth_provider
    alias_attribute :oauth_uid, :mobbie_oauth_uid
    alias_attribute :username, :mobbie_username
    alias_attribute :credit_balance, :mobbie_credit_balance
    
    # Include the shared functionality
    include Mobbie::ActsAsMobbieUser
    
    # Override associations to maintain backward compatibility
    has_many :support_tickets, class_name: "Mobbie::SupportTicket", 
             foreign_key: :user_id, dependent: :destroy
    has_many :purchases, class_name: "Mobbie::Purchase", 
             foreign_key: :user_id, dependent: :destroy
    has_many :subscriptions, class_name: "Mobbie::Subscription", 
             foreign_key: :user_id, dependent: :destroy
    
    # Override some methods to work with non-prefixed attributes
    def anonymous?
      is_anonymous
    end
    
    def permissions
      mobbie_permissions
    end
    
    def display_name
      mobbie_display_name
    end
    
    def as_json(options = {})
      # Use the original as_json format for backward compatibility
      hash = super(options.merge(
        only: [:email, :username, :device_id, :created_at, :is_anonymous, :oauth_provider, :oauth_uid, :name],
        methods: [:permissions]
      ))
      # iOS expects id as string
      hash['id'] = id.to_s
      hash
    end
  end
end