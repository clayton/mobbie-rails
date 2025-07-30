module JwtTestHelper
  def generate_jwt_token(user, expires_at: 1.hour.from_now)
    payload = {
      user_id: user.id,
      device_id: user.device_id,
      exp: expires_at.to_i
    }
    JWT.encode(payload, jwt_secret, 'HS256')
  end

  def auth_headers(user)
    {
      'Authorization' => "Bearer #{generate_jwt_token(user)}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def jwt_secret
    Mobbie::Rails.jwt_secret_key || 'test_secret'
  end

  def decode_jwt_token(token)
    JWT.decode(token, jwt_secret, true, algorithm: 'HS256').first
  rescue JWT::DecodeError
    nil
  end
end