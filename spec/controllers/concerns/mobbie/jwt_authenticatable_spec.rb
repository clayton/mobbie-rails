require 'rails_helper'

RSpec.describe Mobbie::JwtAuthenticatable, type: :controller do
  controller(Mobbie::ApplicationController) do
    def index
      render json: { user_id: current_user.id }
    end
    
    def protected_action
      authenticate_user!
      render json: { success: true }
    end
    
    # Helper methods for testing protected methods
    def test_current_user
      current_user
    end
    
    def test_user_signed_in?
      user_signed_in?
    end
    
    def test_generate_jwt_token(user, expires_at: nil)
      generate_jwt_token(user, expires_at: expires_at)
    end
  end
  
  before do
    routes.draw do
      get 'index' => 'mobbie/application#index'
      get 'protected_action' => 'mobbie/application#protected_action'
    end
  end
  
  let(:user) { create(:mobbie_user) }
  let(:valid_token) { generate_jwt_token(user) }
  let(:expired_token) { generate_jwt_token(user, expires_at: 1.hour.ago) }
  let(:invalid_token) { 'invalid.jwt.token' }
  
  describe '#authenticate_user!' do
    context 'with valid token' do
      before { request.headers['Authorization'] = "Bearer #{valid_token}" }
      
      it 'allows access to protected action' do
        get :protected_action
        expect(response).to have_http_status(:success)
      end
      
      it 'sets current_user' do
        get :protected_action
        expect(controller.test_current_user).to eq(user)
      end
    end
    
    context 'with expired token' do
      before { request.headers['Authorization'] = "Bearer #{expired_token}" }
      
      it 'returns unauthorized' do
        get :protected_action
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns error message' do
        get :protected_action
        json = JSON.parse(response.body)
        expect(json['error']).to include('token has expired')
      end
    end
    
    context 'with invalid token' do
      before { request.headers['Authorization'] = "Bearer #{invalid_token}" }
      
      it 'returns unauthorized' do
        get :protected_action
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'without token' do
      it 'returns unauthorized' do
        get :protected_action
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns missing token error' do
        get :protected_action
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Missing authentication token')
      end
    end
  end
  
  describe '#current_user' do
    context 'with valid token' do
      before { request.headers['Authorization'] = "Bearer #{valid_token}" }
      
      it 'returns the authenticated user' do
        get :index
        expect(controller.test_current_user).to eq(user)
      end
      
      it 'caches the user lookup' do
        expect(Mobbie::User).to receive(:find_by).once.and_return(user)
        get :index
        controller.test_current_user # Second call should use cached value
      end
    end
    
    context 'without authentication' do
      it 'returns nil' do
        get :index
        expect(controller.test_current_user).to be_nil
      end
    end
  end
  
  describe '#user_signed_in?' do
    context 'with authenticated user' do
      before { request.headers['Authorization'] = "Bearer #{valid_token}" }
      
      it 'returns true' do
        get :index
        expect(controller.test_user_signed_in?).to be true
      end
    end
    
    context 'without authentication' do
      it 'returns false' do
        get :index
        expect(controller.test_user_signed_in?).to be false
      end
    end
  end
  
  describe '#generate_jwt_token' do
    it 'generates a valid JWT token' do
      token = controller.test_generate_jwt_token(user)
      decoded = JWT.decode(token, jwt_secret, true, algorithm: 'HS256').first
      
      expect(decoded['user_id']).to eq(user.id)
    end
    
    it 'sets expiration time' do
      token = controller.test_generate_jwt_token(user)
      decoded = JWT.decode(token, jwt_secret, true, algorithm: 'HS256').first
      
      expiration = Time.at(decoded['exp'])
      expect(expiration).to be_between(23.hours.from_now, 25.hours.from_now)
    end
  end
  
  describe 'token validation edge cases' do
    it 'handles malformed authorization header' do
      request.headers['Authorization'] = 'InvalidFormat'
      get :protected_action
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'handles token signed with wrong secret' do
      wrong_secret_token = JWT.encode(
        { user_id: user.id, exp: 1.hour.from_now.to_i },
        'wrong_secret',
        'HS256'
      )
      request.headers['Authorization'] = "Bearer #{wrong_secret_token}"
      
      get :protected_action
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'handles token for non-existent user' do
      token = generate_jwt_token(user)
      user.destroy
      
      request.headers['Authorization'] = "Bearer #{token}"
      get :protected_action
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  private
  
  def jwt_secret
    Mobbie::Rails.jwt_secret_key || 'test_secret'
  end
end