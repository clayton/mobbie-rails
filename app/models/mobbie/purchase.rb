module Mobbie
  class Purchase < Mobbie::ApplicationRecord
    self.table_name = "mobbie_purchases"
    
    belongs_to :user, class_name: "Mobbie::User"

    validates :original_transaction_id, presence: true, uniqueness: true
    validates :transaction_id, presence: true
    validates :product_id, presence: true
    validates :credits_granted, presence: true, numericality: { greater_than: 0 }
    validates :purchase_date, presence: true
    validates :platform, presence: true

    enum :platform, { 
      ios: 'ios',
      android: 'android', 
      system: 'system',
      admin: 'admin'
    }, validate: true
  end
end