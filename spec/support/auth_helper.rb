module AuthHelper
  def authenticate_device(device_id = "test-device-#{SecureRandom.hex(4)}")
    # Create anonymous user and get JWT token
    user = Mobbie::User.create!(
      device_id: device_id,
      is_anonymous: true
    )
    
    # Generate JWT token using the same method as the controller
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }
    
    secret_key = Mobbie::Rails.jwt_secret_key || Rails.application.secret_key_base
    @auth_token = JWT.encode(payload, secret_key, 'HS256')
    @current_user = user
    @auth_headers = { 'Authorization' => "Bearer #{@auth_token}" }
    
    # Return the token for convenience
    @auth_token
  end
  
  def auth_headers
    @auth_headers || {}
  end
  
  def current_user
    @current_user
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
  config.include AuthHelper, type: :controller
end