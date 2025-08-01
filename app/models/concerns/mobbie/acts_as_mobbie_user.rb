module Mobbie
  module ActsAsMobbieUser
    extend ActiveSupport::Concern

    included do
      # Associations
      has_many :mobbie_support_tickets, class_name: "Mobbie::SupportTicket", foreign_key: :user_id, dependent: :destroy
      has_many :mobbie_purchases, class_name: "Mobbie::Purchase", foreign_key: :user_id, dependent: :destroy
      has_many :mobbie_subscriptions, class_name: "Mobbie::Subscription", foreign_key: :user_id, dependent: :destroy
      
      # Validations
      validates :mobbie_device_id, presence: true, uniqueness: true, if: :mobbie_anonymous?
      validates :mobbie_oauth_uid, uniqueness: { scope: :mobbie_oauth_provider }, if: -> { mobbie_oauth_uid.present? }
      
      # Scopes
      scope :mobbie_anonymous, -> { where(mobbie_is_anonymous: true) }
      scope :mobbie_registered, -> { where(mobbie_is_anonymous: false) }
      
      # Callbacks
      before_validation :mobbie_normalize_email
      before_create :mobbie_set_username
    end

    class_methods do
      def acts_as_mobbie_user(options = {})
        # This method is already called by including the concern
        # but can be used for future configuration options
      end
    end

    # Instance methods
    def mobbie_anonymous?
      mobbie_is_anonymous
    end
    
    def mobbie_registered?
      !mobbie_anonymous?
    end
    
    def link_apple_account!(apple_user_id:, email: nil, name: nil)
      self.mobbie_oauth_provider = 'apple'
      self.mobbie_oauth_uid = apple_user_id
      self.email = email if email.present? && respond_to?(:email=)
      self.name = name if name.present? && respond_to?(:name=)
      self.mobbie_is_anonymous = false
      save!
    end
    
    def mobbie_display_name
      # Try to use host app's name/email fields first
      if respond_to?(:name) && name.present?
        name
      elsif respond_to?(:email) && email.present?
        email
      elsif mobbie_username.present?
        mobbie_username
      else
        "User #{id}"
      end
    end
    
    def mobbie_permissions
      # Override this method to implement custom permissions
      []
    end
    
    # Subscription methods
    def active_subscription
      mobbie_subscriptions.active.order(expires_at: :desc).first
    end
    
    def has_active_subscription?
      active_subscription.present?
    end
    
    def subscription_tier
      active_subscription&.tier || 'free'
    end
    
    def premium?
      subscription_tier == 'premium'
    end
    
    # Credit methods
    def add_credits(amount, source: nil)
      increment!(:mobbie_credit_balance, amount)
    end
    
    def spend_credits(amount, reason: nil)
      return false if mobbie_credit_balance < amount
      decrement!(:mobbie_credit_balance, amount)
      true
    end
    
    def has_credits?(amount = 1)
      mobbie_credit_balance >= amount
    end
    
    def mobbie_as_json(options = {})
      hash = {}
      
      # Include mobbie-specific fields
      hash['id'] = id.to_s
      hash['device_id'] = mobbie_device_id
      hash['is_anonymous'] = mobbie_is_anonymous
      hash['oauth_provider'] = mobbie_oauth_provider
      hash['oauth_uid'] = mobbie_oauth_uid
      hash['username'] = mobbie_username
      hash['created_at'] = created_at
      hash['permissions'] = mobbie_permissions
      
      # Include host app fields if they exist
      hash['email'] = email if respond_to?(:email)
      hash['name'] = name if respond_to?(:name)
      
      hash
    end
    
    private
    
    def mobbie_normalize_email
      if respond_to?(:email) && email.present?
        self.email = email.strip.downcase
      end
    end
    
    def mobbie_set_username
      return if mobbie_username.present?
      
      if respond_to?(:email) && email.present?
        base_username = email.split('@').first
        self.mobbie_username = mobbie_generate_unique_username(base_username)
      elsif mobbie_device_id.present?
        self.mobbie_username = "user_#{mobbie_device_id[0..7]}"
      else
        self.mobbie_username = "user_#{SecureRandom.hex(4)}"
      end
    end
    
    def mobbie_generate_unique_username(base)
      username = base
      counter = 1
      klass = self.class
      
      while klass.exists?(mobbie_username: username)
        username = "#{base}#{counter}"
        counter += 1
      end
      
      username
    end
  end
end