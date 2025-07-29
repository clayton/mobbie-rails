module Mobbie
  class PaywallFeature < Mobbie::ApplicationRecord
    self.table_name = "mobbie_paywall_features"
    
    # Associations
    belongs_to :paywall_config, class_name: "Mobbie::PaywallConfig", optional: true
    
    # Validations
    validates :title, presence: true
    validates :icon, presence: true
    validates :description, presence: true
    validates :display_order, numericality: { only_integer: true }
    
    # Scopes
    scope :visible, -> { where(is_visible: true) }
    scope :ordered, -> { order(:display_order, :id) }
    
    def as_json(options = {})
      super(options.merge(
        only: [:title, :icon, :description, :display_order, :is_visible]
      ))
    end
    
    # Alias for compatibility
    def to_api_json
      as_json
    end
  end
end