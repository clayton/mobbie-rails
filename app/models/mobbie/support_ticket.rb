module Mobbie
  class SupportTicket < Mobbie::ApplicationRecord
    self.table_name = "mobbie_support_tickets"
    
    # Associations
    belongs_to_mobbie_user :user, optional: true
    
    # Validations
    validates :name, presence: true
    validates :message, presence: true
    validates :status, inclusion: { in: %w[open in_progress resolved closed] }
    validates :platform, inclusion: { in: %w[ios android web] }
    
    # Scopes
    scope :open_tickets, -> { where(status: 'open') }
    scope :by_platform, ->(platform) { where(platform: platform) }
    scope :recent, -> { order(created_at: :desc) }
    
    # Callbacks
    before_validation :set_defaults
    
    def resolve!
      update!(status: 'resolved')
    end
    
    def close!
      update!(status: 'closed')
    end
    
    def reopen!
      update!(status: 'open')
    end
    
    def device_info_hash
      JSON.parse(device_info || '{}')
    rescue JSON::ParserError
      {}
    end
    
    def as_json(options = {})
      super(options.merge(
        only: [:id, :name, :email, :message, :status, :created_at, :app_version, :device_info, :platform]
      ))
    end
    
    private
    
    def set_defaults
      self.status ||= 'open'
      self.platform ||= 'ios'
    end
  end
end