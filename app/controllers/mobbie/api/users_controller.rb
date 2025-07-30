module Mobbie
  module Api
    class UsersController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      def link_apple_account
        current_user.link_apple_account!(
          apple_user_id: params.require(:apple_user_id),
          email: params[:email],
          name: params[:name]
        )
        
        render json: current_user.as_json
      end
      
      def subscription_status
        subscription = current_user.active_subscription
        
        response = {
          tier: current_user.subscription_tier,
          premium: current_user.premium?,
          subscription: nil,
          features: {
            unlimited_stamps: current_user.premium?,
            advanced_ai_analysis: current_user.premium?,
            ebay_pricing: current_user.premium?,
            listing_generator: current_user.premium?
          },
          usage_limits: nil
        }
        
        if subscription
          response[:subscription] = {
            plan_id: subscription.product_id,
            plan_name: subscription.product_id.include?('weekly') ? 'Weekly Premium' : 'Yearly Premium',
            status: subscription.status,
            billing_period: subscription.product_id.include?('weekly') ? 'week' : 'year',
            expires_at: subscription.expires_at.iso8601(3),
            renews_at: subscription.expires_at.iso8601(3),
            cancelled_at: nil
          }
        end
        
        # Add usage limits for free tier
        unless current_user.premium?
          response[:usage_limits] = {
            daily_limit: 10,
            monthly_limit: 100,
            used_today: 0, # TODO: Track actual usage
            used_this_month: 0, # TODO: Track actual usage
            remaining_today: 10,
            remaining_this_month: 100,
            resets_at: nil
          }
        end
        
        render json: response
      end
    end
  end
end