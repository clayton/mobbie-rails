module Mobbie
  class SubscriptionPlan < Mobbie::ApplicationRecord
    self.table_name = "mobbie_subscription_plans"
    
    has_many :subscriptions, class_name: "Mobbie::Subscription"
    
    validates :product_id, presence: true, uniqueness: true
    validates :name, presence: true
    validates :tier, presence: true, inclusion: { in: %w[free premium] }
    validates :billing_period, presence: true, inclusion: { in: %w[month year] }
    
    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:display_order, :tier, :billing_period) }
    scope :premium, -> { where(tier: 'premium') }
    scope :free, -> { where(tier: 'free') }
    
    def monthly?
      billing_period == 'month'
    end
    
    def annual?
      billing_period == 'year'
    end
    
    def premium?
      tier == 'premium'
    end
    
    def free?
      tier == 'free'
    end
    
    def feature_enabled?(feature)
      features&.dig(feature.to_s) == true
    end
    
    def display_price
      return "Free" if free?
      "$#{'%.2f' % (price_cents / 100.0)}/#{billing_period}"
    end
  end
end