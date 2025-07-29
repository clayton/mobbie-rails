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
          user: user.as_json,
          permissions: user.permissions,
          expires_at: expires_at.iso8601
        }
      end
      
      def refresh
        authenticate_user!
        
        token = generate_jwt_token(current_user)
        expires_at = jwt_expiration.from_now
        
        render json: {
          success: true,
          token: token,
          user: current_user.as_json,
          permissions: current_user.permissions,
          expires_at: expires_at.iso8601
        }
      end
      
      private
      
      def find_or_create_anonymous_user
        device_id = params.require(:device_id)
        
        Mobbie::User.find_or_create_by!(device_id: device_id) do |user|
          user.is_anonymous = true
        end
      end
    end
  end
end