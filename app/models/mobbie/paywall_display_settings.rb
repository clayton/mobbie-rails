module Mobbie
  class PaywallDisplaySettings < Mobbie::ApplicationRecord
    self.table_name = "mobbie_paywall_display_settings"
    
    # Validations
    validates :title, presence: true
    validates :subtitle, presence: true
    
    # Ensure only one active settings record
    validates :is_active, uniqueness: true, if: :is_active?
    
    # Scopes
    scope :active, -> { where(is_active: true) }
    
    # Class methods
    def self.current
      active.first || create_default
    end
    
    def self.create_default
      create!(
        title: "Unlock Premium Features",
        subtitle: "Get unlimited access to all features",
        show_skip_button: true,
        skip_button_text: "Skip",
        is_active: true
      )
    rescue ActiveRecord::RecordInvalid
      active.first
    end
    
    def as_json(options = {})
      super(options.merge(
        only: [:title, :subtitle, :welcome_title, :welcome_subtitle, 
               :show_skip_button, :skip_button_text]
      ))
    end
    
    private
    
    def is_active?
      is_active == true
    end
  end
end