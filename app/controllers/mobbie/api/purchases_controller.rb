module Mobbie
  module Api
    class PurchasesController < Mobbie::ApplicationController
      before_action :authenticate_user!
      # Fallback credit amounts if no paywall config is active
      FALLBACK_CREDIT_PRODUCTS = {
        'credit_pack_small' => 100,
        'credit_pack_medium' => 500,
        'credit_pack_large' => 1000,
        'credit_pack_xl' => 2500
      }.freeze

      def create
        product_id = params[:product_id]
        jws_token = params[:jws_token]

        return render_error('missing_product_id', 'Product ID is required', :bad_request) if product_id.blank?
        return render_error('missing_jws_token', 'JWS token is required', :bad_request) if jws_token.blank?

        # Get credits to grant from paywall config or fallback
        credits_to_grant = get_credits_for_product(product_id)
        return render_error('invalid_product', "Invalid product ID: #{product_id}", :bad_request) unless credits_to_grant&.positive?

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

          # Check for duplicate transaction
          if Mobbie::Purchase.exists?(original_transaction_id: transaction_data[:original_transaction_id])
            return render_error('duplicate_transaction', 'This purchase has already been processed', :conflict)
          end

          # Create purchase record
          ActiveRecord::Base.transaction do
            purchase = current_user.purchases.create!(
              original_transaction_id: transaction_data[:original_transaction_id],
              transaction_id: transaction_data[:transaction_id],
              product_id: product_id,
              credits_granted: credits_to_grant,
              purchase_date: transaction_data[:purchase_date],
              platform: 'ios'
            )

            # Grant credits to user
            current_user.add_credits(credits_to_grant, source: "purchase:#{purchase.id}")

            render_success(
              purchase_id: purchase.id,
              credits_added: credits_to_grant,
              total_credits: current_user.credit_balance,
              transaction_id: transaction_data[:transaction_id]
            )
          end

        rescue Mobbie::AppleIapService::ValidationError => e
          render_error('validation_failed', "Apple IAP validation failed: #{e.message}", :unprocessable_entity)
        rescue ActiveRecord::RecordInvalid => e
          render_error('database_error', e.message, :unprocessable_entity)
        end
      end

      private

      def render_error(code, message, status)
        render json: { 
          success: false,
          error_code: code,
          error: message 
        }, status: status
      end

      def render_success(data)
        # iOS expects credits_added and total_credits at root level
        render json: { 
          success: true,
          credits_added: data[:credits_added],
          total_credits: data[:total_credits],
          message: "Purchase successful",
          data: data 
        }
      end

      def get_credits_for_product(product_id)
        # First try to get from active paywall config
        paywall_config = Mobbie::PaywallConfig.current
        if paywall_config
          offering = paywall_config.paywall_offerings.find_by(product_id: product_id)
          return offering.cartoon_count if offering
        end
        
        # Fallback to hardcoded values
        FALLBACK_CREDIT_PRODUCTS[product_id]
      end
    end
  end
end