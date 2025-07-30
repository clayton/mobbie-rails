require 'rails_helper'

RSpec.describe Mobbie::Api::SubscriptionsController, type: :controller do
  include AppleIapTestHelper
  
  let(:user) { create(:mobbie_user) }
  let(:valid_product_id) { 'com.mobbie.premium.weekly' }
  let(:valid_jws_token) { generate_mock_jws_token }
  
  before do
    @request.headers.merge!(auth_headers(user))
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      before do
        mock_apple_validation_success
        mock_apple_production_environment(false) # Sandbox for tests
      end

      it 'creates a new subscription' do
        expect {
          post :create, params: {
            product_id: valid_product_id,
            jws_token: valid_jws_token
          }
        }.to change { user.subscriptions.count }.by(1)
        
        expect(response).to have_http_status(:success)
      end

      it 'returns subscription details' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['subscription']).to include(
          'plan_id' => valid_product_id,
          'plan_name' => 'Weekly Premium',
          'status' => 'active',
          'billing_period' => 'week'
        )
        expect(json['message']).to eq('Subscription activated successfully')
      end

      it 'sets correct subscription attributes' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        subscription = user.subscriptions.last
        expect(subscription).to have_attributes(
          product_id: valid_product_id,
          status: 'active',
          tier: 'premium',
          platform: 'ios'
        )
        expect(subscription.expires_at).to be > Time.current
      end
    end

    context 'when subscription already exists' do
      let!(:existing_subscription) do
        create(:mobbie_subscription,
          user: user,
          original_transaction_id: '2000000123456789',
          status: 'active'
        )
      end

      before do
        mock_apple_validation_success
        mock_apple_production_environment(false)
      end

      it 'updates existing subscription instead of creating new one' do
        expect {
          post :create, params: {
            product_id: valid_product_id,
            jws_token: valid_jws_token
          }
        }.not_to change { user.subscriptions.count }
        
        expect(response).to have_http_status(:success)
        
        existing_subscription.reload
        expect(existing_subscription.status).to eq('active')
      end
    end

    context 'when subscription exists for different user' do
      let!(:other_user) { create(:mobbie_user) }
      let!(:other_subscription) do
        create(:mobbie_subscription,
          user: other_user,
          original_transaction_id: '2000000123456789'
        )
      end

      before do
        mock_apple_validation_success
        mock_apple_production_environment(false)
      end

      it 'transfers subscription to current user' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:success)
        
        other_subscription.reload
        expect(other_subscription.user_id).to eq(user.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when product_id is missing' do
        post :create, params: { jws_token: valid_jws_token }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('Product ID is required')
      end

      it 'returns error when jws_token is missing' do
        post :create, params: { product_id: valid_product_id }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('JWS token is required')
      end

      it 'returns error for invalid product_id' do
        post :create, params: {
          product_id: 'invalid.product',
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Invalid subscription product ID')
      end
    end

    context 'when Apple validation fails' do
      before do
        mock_apple_validation_failure('Invalid receipt')
      end

      it 'returns validation error' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('Apple IAP validation failed')
      end
    end

    context 'when environment mismatch' do
      before do
        mock_apple_validation_success
        mock_apple_production_environment(false) # Will fail in our mock
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      it 'returns environment error' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Transaction environment does not match')
      end
    end

    context 'without authentication' do
      before { @request.headers['Authorization'] = nil }

      it 'returns unauthorized' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #index' do
    let!(:active_sub) { create(:mobbie_subscription, :active, user: user) }
    let!(:expired_sub) { create(:mobbie_subscription, :expired, user: user) }
    let!(:other_user_sub) { create(:mobbie_subscription) }

    it 'returns user subscriptions' do
      get :index
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['subscriptions'].length).to eq(2)
      
      subscription_ids = json['subscriptions'].map { |s| s['id'] }
      expect(subscription_ids).to include(active_sub.id, expired_sub.id)
      expect(subscription_ids).not_to include(other_user_sub.id)
    end

    it 'orders by expires_at descending' do
      get :index
      
      json = JSON.parse(response.body)
      subscriptions = json['subscriptions']
      
      expect(subscriptions.first['id']).to eq(active_sub.id)
      expect(subscriptions.last['id']).to eq(expired_sub.id)
    end
  end

  describe 'GET #current' do
    context 'with active subscription' do
      let!(:subscription) { create(:mobbie_subscription, :active, user: user) }

      it 'returns current subscription' do
        get :current
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json['success']).to be true
        expect(json['subscription']).to include(
          'id' => subscription.id,
          'plan_id' => subscription.product_id,
          'status' => 'active'
        )
      end
    end

    context 'without active subscription' do
      it 'returns null subscription' do
        get :current
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        
        expect(json['success']).to be true
        expect(json['subscription']).to be_nil
        expect(json['message']).to eq('No active subscription')
      end
    end
  end
end