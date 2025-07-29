module Mobbie
  class SubscriptionExpiryJob < ApplicationJob
    queue_as :default

    def perform
      # Find all active subscriptions that have expired
      expired_subscriptions = Mobbie::Subscription.where(status: 'active')
                                                  .where('expires_at <= ?', Time.current)

      expired_count = 0
      
      expired_subscriptions.find_each do |subscription|
        subscription.update!(status: 'expired')
        expired_count += 1
      end

      Rails.logger.info "Mobbie::SubscriptionExpiryJob: Marked #{expired_count} subscriptions as expired"
      
      expired_count
    end
  end
end