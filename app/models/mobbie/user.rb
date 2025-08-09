module Mobbie
  class User < Mobbie::ApplicationRecord
    self.table_name = "mobbie_users"

    # Map prefixed field names to actual database columns
    alias_attribute :mobbie_device_id, :device_id
    alias_attribute :mobbie_is_anonymous, :is_anonymous
    alias_attribute :mobbie_oauth_provider, :oauth_provider
    alias_attribute :mobbie_oauth_uid, :oauth_uid
    alias_attribute :mobbie_username, :username
    alias_attribute :mobbie_credit_balance, :credit_balance

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
      super(options.merge(
        only: %i[id email username device_id created_at is_anonymous oauth_provider oauth_uid name],
        methods: [:permissions]
      ))
    end
  end
end
