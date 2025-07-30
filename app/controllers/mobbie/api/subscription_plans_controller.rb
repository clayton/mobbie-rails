module Mobbie
  module Api
    class SubscriptionPlansController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      def index
        plans = Mobbie::SubscriptionPlan.active.ordered
        
        render json: plans.map { |plan|
          {
            product_id: plan.product_id,
            name: plan.name,
            tier: plan.tier,
            billing_period: plan.billing_period,
            price: format_price(plan.price_cents),
            features: plan.features || [],
            display_order: plan.display_order,
            is_popular: plan.is_popular
          }
        }
      end
      
      private
      
      def format_price(cents)
        return nil unless cents
        "$#{cents / 100.0}"
      end
    end
  end
end