module Mobbie
  module Api
    class SubscriptionsController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      # Default subscription products - can be overridden in app config
      SUBSCRIPTION_PRODUCTS = {
        'com.mobbie.premium.weekly' => {
          name: 'Weekly Premium',
          price_cents: 1299,
          billing_period: 'week',
          tier: 'premium'
        },
        'com.mobbie.premium.yearly' => {
          name: 'Yearly Premium', 
          price_cents: 2999,
          billing_period: 'year',
          tier: 'premium'
        }
      }.freeze

      def create
        product_id = params[:product_id]
        jws_token = params[:jws_token]

        return render_error('missing_product_id', 'Product ID is required', :bad_request) if product_id.blank?
        return render_error('missing_jws_token', 'JWS token is required', :bad_request) if jws_token.blank?

        # Validate product exists
        unless valid_subscription_product?(product_id)
          return render_error('invalid_product', "Invalid subscription product ID: #{product_id}", :bad_request)
        end

        begin
          # Validate Apple IAP receipt
          transaction_data = Mobbie::AppleIapService.validate_jws_token(jws_token)

          # Verify product ID matches
          unless transaction_data[:product_id] == product_id
            return render_error('product_mismatch', 'Product ID in receipt does not match request', :bad_request)
          end

          # Verify environment
          unless Mobbie::AppleIapService.validate_production_environment?(transaction_data[:environment])
            return render_error('environment_mismatch', 'Transaction environment does not match app environment', :bad_request)
          end

          # Verify expires_date is present for subscriptions
          unless transaction_data[:expires_date]
            return render_error('missing_expiry', 'Subscription must have expiry date', :bad_request)
          end

          Rails.logger.info "Processing subscription for user #{current_user.id} with transaction data: #{transaction_data.inspect}"
          
          ActiveRecord::Base.transaction do
            # First check if subscription exists for current user
            subscription = current_user.subscriptions.find_by(
              original_transaction_id: transaction_data[:original_transaction_id]
            )

            # If not found for current user, check if it exists for ANY user
            # This handles account deletion/recreation scenarios
            if !subscription
              existing_subscription = Mobbie::Subscription.find_by(
                original_transaction_id: transaction_data[:original_transaction_id]
              )
              
              if existing_subscription
                Rails.logger.info "Found subscription for different user (#{existing_subscription.user_id}), transferring to current user (#{current_user.id}) based on Apple validation"
                # Transfer the subscription to current user since Apple validated ownership
                existing_subscription.update!(
                  user_id: current_user.id,
                  transaction_id: transaction_data[:transaction_id],
                  expires_at: transaction_data[:expires_date],
                  status: transaction_data[:expires_date] > Time.current ? 'active' : 'expired',
                  tier: 'premium'
                )
                subscription = existing_subscription
              end
            end

            if subscription
              # Update existing subscription
              subscription.update!(
                transaction_id: transaction_data[:transaction_id],
                expires_at: transaction_data[:expires_date],
                status: transaction_data[:expires_date] > Time.current ? 'active' : 'expired',
                tier: 'premium'
              )
            else
              # Create new subscription
              subscription = current_user.subscriptions.create!(
                original_transaction_id: transaction_data[:original_transaction_id],
                transaction_id: transaction_data[:transaction_id],
                product_id: product_id,
                purchase_date: transaction_data[:purchase_date],
                expires_at: transaction_data[:expires_date],
                platform: 'ios',
                status: transaction_data[:expires_date] > Time.current ? 'active' : 'expired',
                tier: 'premium'
              )
            end

            # Log the subscription details for debugging
            Rails.logger.info "Subscription created/updated: #{subscription.inspect}"
            
            # Return response with consistent formatting
            response_json = {
              success: true,
              subscription: {
                plan_id: subscription.product_id,
                plan_name: get_plan_name(subscription.product_id),
                status: subscription.status,
                billing_period: get_billing_period(subscription.product_id),
                expires_at: subscription.expires_at.iso8601,
                renews_at: subscription.expires_at.iso8601,
                cancelled_at: nil
              },
              message: 'Subscription activated successfully'
            }
            
            Rails.logger.info "Sending subscription response: #{response_json.to_json}"
            render json: response_json
          end

        rescue Mobbie::AppleIapService::ValidationError => e
          render_error('validation_failed', "Apple IAP validation failed: #{e.message}", :unprocessable_entity)
        rescue ActiveRecord::RecordInvalid => e
          render_error('database_error', e.message, :unprocessable_entity)
        end
      end

      def index
        subscriptions = current_user.subscriptions.order(expires_at: :desc)
        render json: {
          success: true,
          subscriptions: subscriptions.map { |s| subscription_json(s) }
        }
      end

      def current
        subscription = current_user.active_subscription
        if subscription
          render json: {
            success: true,
            subscription: subscription_json(subscription)
          }
        else
          render json: {
            success: true,
            subscription: nil,
            message: 'No active subscription'
          }
        end
      end

      private

      def valid_subscription_product?(product_id)
        # Check configured products first
        return true if configured_products.key?(product_id)
        
        # Check subscription plans in database
        Mobbie::SubscriptionPlan.active.exists?(product_id: product_id)
      end

      def configured_products
        # Allow apps to override via config
        Mobbie::Rails.configuration.subscription_products || SUBSCRIPTION_PRODUCTS
      end

      def get_plan_name(product_id)
        configured_products.dig(product_id, :name) || 
          Mobbie::SubscriptionPlan.find_by(product_id: product_id)&.name ||
          'Premium Subscription'
      end

      def get_billing_period(product_id)
        configured_products.dig(product_id, :billing_period) ||
          Mobbie::SubscriptionPlan.find_by(product_id: product_id)&.billing_period ||
          (product_id.include?('weekly') ? 'week' : 'year')
      end

      def subscription_json(subscription)
        {
          id: subscription.id,
          plan_id: subscription.product_id,
          plan_name: get_plan_name(subscription.product_id),
          status: subscription.status,
          billing_period: get_billing_period(subscription.product_id),
          expires_at: subscription.expires_at.iso8601,
          renews_at: subscription.expires_at.iso8601,
          cancelled_at: nil,
          days_remaining: subscription.days_remaining
        }
      end

      def render_error(code, message, status)
        render json: { 
          success: false,
          error_code: code,
          error: message 
        }, status: status
      end
    end
  end
end