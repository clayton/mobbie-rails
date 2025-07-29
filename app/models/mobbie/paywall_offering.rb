module Mobbie
  class PaywallOffering < Mobbie::ApplicationRecord
    self.table_name = "mobbie_paywall_offerings"
    
    # Associations
    belongs_to :paywall_config, class_name: "Mobbie::PaywallConfig", optional: true
    
    # Validations
    validates :product_id, presence: true, uniqueness: { scope: :paywall_config_id }
    validates :display_name, presence: true
    validates :cartoon_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :display_order, numericality: { only_integer: true }
    
    # Scopes
    scope :visible, -> { where(is_visible: true) }
    scope :visible_for_onboarding, -> { visible.where(is_visible_for_onboarding: true) }
    scope :featured, -> { where(is_featured: true) }
    scope :welcome_offers, -> { where(is_welcome_offer: true) }
    scope :ordered, -> { order(:display_order, :id) }
    
    def as_json(options = {})
      super(options.merge(
        only: [:product_id, :display_name, :description, :cartoon_count, 
               :is_welcome_offer, :is_featured, :display_order, :badge_text,
               :is_visible, :is_visible_for_onboarding]
      ))
    end
    
    # Alias for compatibility
    def to_api_json
      as_json
    end
  end
end