module Mobbie
  class Subscription < Mobbie::ApplicationRecord
    self.table_name = "mobbie_subscriptions"
    
    belongs_to :user, class_name: "Mobbie::User"
    belongs_to :subscription_plan, class_name: "Mobbie::SubscriptionPlan", optional: true

    validates :original_transaction_id, presence: true, uniqueness: true
    validates :transaction_id, presence: true
    validates :product_id, presence: true
    validates :purchase_date, presence: true
    validates :expires_at, presence: true
    validates :platform, presence: true
    validates :status, presence: true
    validates :tier, presence: true

    enum :platform, { 
      ios: 'ios',
      android: 'android', 
      system: 'system',
      admin: 'admin'
    }, validate: true

    enum :status, {
      active: 'active',
      expired: 'expired',
      cancelled: 'cancelled',
      grace_period: 'grace_period',
      refunded: 'refunded'
    }, validate: true

    scope :active, -> { where(status: 'active').where('expires_at > ?', Time.current) }
    scope :expired, -> { where(status: 'expired').or(where('expires_at <= ?', Time.current)) }

    def active?
      status == 'active' && expires_at && expires_at > Time.current
    end

    def expired?
      status == 'expired' || (expires_at && expires_at <= Time.current)
    end

    def in_grace_period?
      status == 'grace_period'
    end

    def days_remaining
      return nil if expires_at.nil?
      days = ((expires_at - Time.current) / 1.day).ceil
      days > 0 ? days : 0
    end

    def tier_from_product_id
      case product_id
      when /premium/
        'premium'
      else
        'free'
      end
    end
  end
end