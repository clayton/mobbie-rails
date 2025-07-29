module Mobbie
  class User < Mobbie::ApplicationRecord
    self.table_name = "mobbie_users"
    
    # Associations
    has_many :support_tickets, class_name: "Mobbie::SupportTicket", dependent: :destroy
    has_many :purchases, class_name: "Mobbie::Purchase", dependent: :destroy
    has_many :subscriptions, class_name: "Mobbie::Subscription", dependent: :destroy
    
    # Validations
    validates :device_id, presence: true, uniqueness: true, if: :anonymous?
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates :email, uniqueness: { case_sensitive: false }, if: -> { email.present? }
    validates :oauth_uid, uniqueness: { scope: :oauth_provider }, if: -> { oauth_uid.present? }
    
    # Scopes
    scope :anonymous, -> { where(is_anonymous: true) }
    scope :registered, -> { where(is_anonymous: false) }
    
    # Callbacks
    before_validation :normalize_email
    before_create :set_username
    
    def anonymous?
      is_anonymous
    end
    
    def registered?
      !anonymous?
    end
    
    def link_apple_account!(apple_user_id:, email: nil, name: nil)
      self.oauth_provider = 'apple'
      self.oauth_uid = apple_user_id
      self.email = email if email.present?
      self.name = name if name.present?
      self.is_anonymous = false
      save!
    end
    
    def display_name
      name.presence || username.presence || email.presence || "User #{id}"
    end
    
    def permissions
      # Override this method to implement custom permissions
      []
    end
    
    # Subscription methods
    def active_subscription
      subscriptions.active.order(expires_at: :desc).first
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
    
    # Credit methods - override these in your app if needed
    def add_credits(amount, source: nil)
      increment!(:credit_balance, amount)
    end
    
    def spend_credits(amount, reason: nil)
      return false if credit_balance < amount
      decrement!(:credit_balance, amount)
      true
    end
    
    def has_credits?(amount = 1)
      credit_balance >= amount
    end
    
    def as_json(options = {})
      super(options.merge(
        only: [:id, :email, :username, :device_id, :created_at, :is_anonymous, :oauth_provider, :oauth_uid, :name],
        methods: [:permissions]
      ))
    end
    
    private
    
    def normalize_email
      self.email = email&.strip&.downcase
    end
    
    def set_username
      return if username.present?
      
      if email.present?
        base_username = email.split('@').first
        self.username = generate_unique_username(base_username)
      elsif device_id.present?
        self.username = "user_#{device_id[0..7]}"
      else
        self.username = "user_#{SecureRandom.hex(4)}"
      end
    end
    
    def generate_unique_username(base)
      username = base
      counter = 1
      
      while User.exists?(username: username)
        username = "#{base}#{counter}"
        counter += 1
      end
      
      username
    end
  end
end