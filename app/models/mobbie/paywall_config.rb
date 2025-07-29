module Mobbie
  class PaywallConfig < Mobbie::ApplicationRecord
    self.table_name = "mobbie_paywall_configs"
    
    # Associations
    has_many :paywall_offerings, class_name: "Mobbie::PaywallOffering", dependent: :destroy
    has_many :paywall_features, class_name: "Mobbie::PaywallFeature", dependent: :destroy

    # Validations
    validates :title, presence: true
    validates :subtitle, presence: true
    validates :welcome_title, presence: true
    validates :welcome_subtitle, presence: true
    validates :skip_button_text, presence: true
    validates :active, uniqueness: { if: :active?, message: "Only one config can be active at a time" }

    # Scopes
    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:display_order, :created_at) }

    # Singleton pattern - get the current active config
    def self.current
      active.first
    end

    # Make this config active (deactivates all others)
    def activate!
      ActiveRecord::Base.transaction do
        PaywallConfig.where(active: true).update_all(active: false)
        update!(active: true)
      end
    end

    # Get visible offerings ordered by display_order
    def visible_offerings
      paywall_offerings.where(is_visible: true).order(:display_order)
    end

    # Get visible features ordered by display_order
    def visible_features
      paywall_features.where(is_visible: true).order(:display_order)
    end

    # Get offerings visible for onboarding
    def onboarding_offerings
      paywall_offerings.where(is_visible_for_onboarding: true).order(:display_order)
    end

    # Convert to API JSON format
    def to_api_json
      {
        offerings: visible_offerings.map(&:to_api_json),
        features: visible_features.map(&:to_api_json),
        display_settings: {
          title: title,
          subtitle: subtitle,
          welcome_title: welcome_title,
          welcome_subtitle: welcome_subtitle,
          show_skip_button: show_skip_button,
          skip_button_text: skip_button_text
        }
      }
    end
  end
end