module Mobbie
  module Api
    class SmartRestoreController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      def create
        transactions = params[:transactions] || []
        restored_count = 0
        skipped_count = 0
        
        transactions.each do |transaction|
          begin
            # Validate the JWS token
            transaction_data = Mobbie::AppleIapService.validate_jws_token(transaction['jws_token'])
            
            # Check if subscription already exists
            existing_subscription = Mobbie::Subscription.find_by(
              original_transaction_id: transaction_data[:original_transaction_id]
            )
            
            if existing_subscription
              # Transfer to current user if owned by different user
              if existing_subscription.user_id != current_user.id
                existing_subscription.update!(user_id: current_user.id)
                restored_count += 1
              else
                skipped_count += 1
              end
            else
              # Create new subscription
              current_user.subscriptions.create!(
                original_transaction_id: transaction_data[:original_transaction_id],
                transaction_id: transaction_data[:transaction_id],
                product_id: transaction['product_id'],
                purchase_date: transaction_data[:purchase_date],
                expires_at: transaction_data[:expires_date],
                platform: 'ios',
                status: transaction_data[:expires_date] > Time.current ? 'active' : 'expired',
                tier: 'premium'
              )
              restored_count += 1
            end
          rescue => e
            Rails.logger.error "Smart restore error for transaction: #{e.message}"
            skipped_count += 1
          end
        end
        
        # Get current subscription status
        subscription = current_user.active_subscription
        subscription_status = if subscription
          {
            tier: 'premium',
            premium: true,
            subscription: {
              plan_id: subscription.product_id,
              plan_name: subscription.product_id.include?('weekly') ? 'Weekly Premium' : 'Yearly Premium',
              status: subscription.status,
              billing_period: subscription.product_id.include?('weekly') ? 'week' : 'year',
              expires_at: subscription.expires_at.iso8601(3),
              renews_at: subscription.expires_at.iso8601(3),
              cancelled_at: nil
            },
            features: {
              unlimited_stamps: true,
              advanced_ai_analysis: true,
              ebay_pricing: true,
              listing_generator: true
            },
            usage_limits: nil
          }
        else
          nil
        end
        
        render json: {
          restored_count: restored_count,
          skipped_count: skipped_count,
          message: "Restored #{restored_count} subscription(s)",
          subscription_status: subscription_status
        }
      end
    end
  end
end