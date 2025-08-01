module Mobbie
  module Api
    class AuthController < Mobbie::ApplicationController
      skip_before_action :authenticate_user!, only: [:anonymous]
      
      def anonymous
        user = find_or_create_anonymous_user
        
        token = generate_jwt_token(user)
        expires_at = jwt_expiration.from_now
        
        render json: {
          success: true,
          token: token,
          user: user_json(user),
          permissions: user_permissions(user),
          expires_at: expires_at.iso8601(3) # iOS expects fractional seconds
        }
      end
      
      def refresh
        authenticate_user!
        
        token = generate_jwt_token(current_user)
        expires_at = jwt_expiration.from_now
        
        render json: {
          success: true,
          token: token,
          user: user_json(current_user),
          permissions: user_permissions(current_user),
          expires_at: expires_at.iso8601(3) # iOS expects fractional seconds
        }
      end
      
      private
      
      def find_or_create_anonymous_user
        device_id = params.require(:device_id)
        
        user_model.find_or_create_by!(mobbie_device_id: device_id) do |user|
          user.mobbie_is_anonymous = true
        end
      end
      
      def user_model
        Mobbie::Rails.user_model
      end
      
      def user_json(user)
        if user.respond_to?(:mobbie_as_json)
          user.mobbie_as_json
        else
          user.as_json
        end
      end
      
      def user_permissions(user)
        if user.respond_to?(:mobbie_permissions)
          user.mobbie_permissions
        else
          user.permissions
        end
      end
    end
  end
end