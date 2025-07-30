require 'rails_helper'

RSpec.describe Mobbie::Api::PurchasesController, type: :controller do
  include AppleIapTestHelper
  
  let(:user) { create(:mobbie_user, credit_balance: 50) }
  let(:valid_product_id) { 'credit_pack_medium' }
  let(:valid_jws_token) { generate_mock_jws_token(product_id: valid_product_id) }
  
  before do
    @request.headers.merge!(auth_headers(user))
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      before do
        mock_apple_validation_success(product_id: valid_product_id)
        mock_apple_production_environment(false)
      end

      it 'creates a new purchase' do
        expect {
          post :create, params: {
            product_id: valid_product_id,
            jws_token: valid_jws_token
          }
        }.to change { user.purchases.count }.by(1)
        
        expect(response).to have_http_status(:success)
      end

      it 'grants credits to user' do
        expect {
          post :create, params: {
            product_id: valid_product_id,
            jws_token: valid_jws_token
          }
        }.to change { user.reload.credit_balance }.by(500)
      end

      it 'returns purchase details' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to include(
          'credits_added' => 500,
          'total_credits' => 550
        )
        expect(json['data']['purchase_id']).to be_present
        expect(json['data']['transaction_id']).to be_present
      end

      it 'creates purchase with correct attributes' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        purchase = user.purchases.last
        expect(purchase).to have_attributes(
          product_id: valid_product_id,
          credits_granted: 500,
          platform: 'ios',
          original_transaction_id: '2000000123456789',
          transaction_id: '2000000123456789'
        )
      end
    end

    context 'with paywall config offering' do
      let!(:paywall_config) { create(:mobbie_paywall_config, :active) }
      let!(:offering) do
        create(:mobbie_paywall_offering,
          paywall_config: paywall_config,
          product_id: 'custom_pack',
          cartoon_count: 750
        )
      end

      before do
        mock_apple_validation_success(product_id: 'custom_pack')
        mock_apple_production_environment(false)
      end

      it 'uses credits from paywall offering' do
        expect {
          post :create, params: {
            product_id: 'custom_pack',
            jws_token: generate_mock_jws_token(product_id: 'custom_pack')
          }
        }.to change { user.reload.credit_balance }.by(750)
      end
    end

    context 'with duplicate transaction' do
      let!(:existing_purchase) do
        create(:mobbie_purchase,
          user: user,
          original_transaction_id: '2000000123456789'
        )
      end

      before do
        mock_apple_validation_success
        mock_apple_production_environment(false)
      end

      it 'rejects duplicate transaction' do
        expect {
          post :create, params: {
            product_id: valid_product_id,
            jws_token: valid_jws_token
          }
        }.not_to change { user.purchases.count }
        
        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to include('already been processed')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when product_id is missing' do
        post :create, params: { jws_token: valid_jws_token }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Product ID is required')
      end

      it 'returns error when jws_token is missing' do
        post :create, params: { product_id: valid_product_id }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('JWS token is required')
      end

      it 'returns error for invalid product_id' do
        post :create, params: {
          product_id: 'invalid_product',
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Invalid product ID')
      end
    end

    context 'when product mismatch' do
      before do
        mock_apple_validation_success(product_id: 'different_product')
        mock_apple_production_environment(false)
      end

      it 'returns product mismatch error' do
        post :create, params: {
          product_id: valid_product_id,
          jws_token: valid_jws_token
        }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Product ID in receipt does not match')
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
        expect(json['error']).to include('Apple IAP validation failed')
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

    describe 'credit pack products' do
      before do
        mock_apple_production_environment(false)
      end

      it 'grants 100 credits for small pack' do
        mock_apple_validation_success(product_id: 'credit_pack_small')
        
        expect {
          post :create, params: {
            product_id: 'credit_pack_small',
            jws_token: generate_mock_jws_token(product_id: 'credit_pack_small')
          }
        }.to change { user.reload.credit_balance }.by(100)
      end

      it 'grants 1000 credits for large pack' do
        mock_apple_validation_success(product_id: 'credit_pack_large')
        
        expect {
          post :create, params: {
            product_id: 'credit_pack_large',
            jws_token: generate_mock_jws_token(product_id: 'credit_pack_large')
          }
        }.to change { user.reload.credit_balance }.by(1000)
      end

      it 'grants 2500 credits for xl pack' do
        mock_apple_validation_success(product_id: 'credit_pack_xl')
        
        expect {
          post :create, params: {
            product_id: 'credit_pack_xl',
            jws_token: generate_mock_jws_token(product_id: 'credit_pack_xl')
          }
        }.to change { user.reload.credit_balance }.by(2500)
      end
    end
  end
end