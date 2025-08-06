module Mobbie
  module JwtAuthenticatable
    extend ActiveSupport::Concern
    
    included do
      before_action :set_default_headers
      before_action :authenticate_user!
    end
    
    protected
    
    def current_user
      @current_user ||= decode_jwt_user
    end
    
    def user_signed_in?
      current_user.present?
    end
    
    private
    
    def authenticate_user!
      return if current_user
      
      if jwt_token.nil? && request.headers['Authorization'].nil?
        error_message = "Missing authentication token"
      else
        error_message = @jwt_error || "Authentication required"
      end
      
      render_unauthorized(error_message)
    end
    
    def decode_jwt_user
      return nil unless jwt_token.present?
      
      begin
        payload = JWT.decode(
          jwt_token,
          jwt_secret_key,
          true,
          algorithm: 'HS256'
        ).first
        
        user_model.find_by(id: payload['user_id'])
      rescue JWT::ExpiredSignature
        @jwt_error = "token has expired"
        nil
      rescue JWT::DecodeError
        @jwt_error = "invalid token"
        nil
      end
    end
    
    def jwt_token
      @jwt_token ||= extract_jwt_token
    end
    
    def extract_jwt_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?
      
      auth_header.split(' ').last if auth_header.start_with?('Bearer ')
    end
    
    def generate_jwt_token(user, expires_at: nil)
      expires_at ||= jwt_expiration.from_now
      
      payload = {
        user_id: user.id,
        exp: expires_at.to_i,
        iat: Time.current.to_i
      }
      
      JWT.encode(payload, jwt_secret_key, 'HS256')
    end
    
    def jwt_secret_key
      Mobbie::Rails.jwt_secret_key || raise(Mobbie::Rails::Error, "JWT secret key not configured")
    end
    
    def jwt_expiration
      Mobbie::Rails.jwt_expiration || 24.hours
    end
    
    def jwt_refresh_expiration
      Mobbie::Rails.jwt_refresh_expiration || 30.days
    end
    
    def render_unauthorized(message = "Unauthorized")
      render json: { error: message }, status: :unauthorized
    end
    
    def render_forbidden(message = "Permission denied")
      render json: { error: message }, status: :forbidden
    end
    
    def set_default_headers
      response.headers['Content-Type'] = 'application/json'
    end
    
    def user_model
      Mobbie::Rails.user_model
    end
  end
end