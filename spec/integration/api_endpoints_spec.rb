require 'rails_helper'

RSpec.describe "Mobbie API Endpoints", type: :request do
  let(:device_id) { "test-device-#{SecureRandom.hex(8)}" }
  let(:auth_headers) { {} }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }
  
  describe "Authentication Flow" do
    describe "POST /api/auth/anonymous" do
      it "creates anonymous user with valid device_id" do
        post "/api/auth/anonymous", 
             params: { device_id: device_id }.to_json,
             headers: json_headers
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['device_id']).to eq(device_id)
        expect(json['user']['is_anonymous']).to be true
        expect(json['expires_at']).to be_present
      end
      
      it "returns error without device_id" do
        post "/api/auth/anonymous", 
             params: {}.to_json,
             headers: json_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_present
      end
      
      it "returns same user for same device_id" do
        # First request
        post "/api/auth/anonymous", 
             params: { device_id: device_id }.to_json,
             headers: json_headers
        
        first_user_id = JSON.parse(response.body)['user']['id']
        
        # Second request with same device_id
        post "/api/auth/anonymous", 
             params: { device_id: device_id }.to_json,
             headers: json_headers
        
        second_user_id = JSON.parse(response.body)['user']['id']
        
        expect(second_user_id).to eq(first_user_id)
      end
    end
    
    describe "POST /api/auth/refresh" do
      let(:user) { create(:mobbie_user, :anonymous) }
      let(:token) { generate_jwt_for(user) }
      let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
      
      it "refreshes valid token" do
        post "/api/auth/refresh", headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['token']).not_to eq(token) # New token
        expect(json['user']['id']).to eq(user.id)
      end
      
      it "returns error without token" do
        post "/api/auth/refresh", headers: json_headers
        
        expect(response).to have_http_status(:unauthorized)
      end
      
      it "returns error with invalid token" do
        headers = { 'Authorization' => "Bearer invalid-token" }.merge(json_headers)
        post "/api/auth/refresh", headers: headers
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "Paywall Configuration" do
    let(:user) { create(:mobbie_user, :anonymous) }
    let(:token) { generate_jwt_for(user) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
    
    before do
      # Create paywall configuration
      paywall_config = create(:mobbie_paywall_config)
      create_list(:mobbie_paywall_offering, 2, paywall_config: paywall_config)
      create_list(:mobbie_paywall_feature, 4, paywall_config: paywall_config)
    end
    
    describe "GET /api/paywall_config" do
      it "requires authentication" do
        get "/api/paywall_config", headers: json_headers
        
        expect(response).to have_http_status(:unauthorized)
      end
      
      it "returns paywall configuration when authenticated" do
        get "/api/paywall_config", headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['offerings']).to be_an(Array)
        expect(json['offerings'].size).to eq(2)
        expect(json['features']).to be_an(Array)
        expect(json['features'].size).to eq(4)
        expect(json['title']).to be_present
      end
    end
  end
  
  describe "User Management" do
    let(:user) { create(:mobbie_user, :anonymous) }
    let(:token) { generate_jwt_for(user) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
    
    describe "PATCH /api/users/link_apple_account" do
      let(:apple_data) do
        {
          apple_user_id: "apple-#{SecureRandom.hex(8)}",
          email: "test@example.com",
          name: "Test User"
        }
      end
      
      it "links Apple account to anonymous user" do
        patch "/api/users/link_apple_account",
              params: apple_data.to_json,
              headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq(apple_data[:email])
        expect(json['user']['name']).to eq(apple_data[:name])
        expect(json['user']['oauth_provider']).to eq('apple')
        expect(json['user']['oauth_uid']).to eq(apple_data[:apple_user_id])
        expect(json['user']['is_anonymous']).to be false
      end
      
      it "requires authentication" do
        patch "/api/users/link_apple_account",
              params: apple_data.to_json,
              headers: json_headers
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "Support Tickets" do
    describe "POST /api/support_requests" do
      let(:support_data) do
        {
          name: "Test User",
          email: "support@example.com",
          message: "I need help with the app",
          app_version: "1.0.0",
          device_info: { model: "iPhone 15", os_version: "17.0" }.to_json,
          platform: "ios"
        }
      end
      
      it "creates support ticket without authentication" do
        post "/api/support_requests",
             params: support_data.to_json,
             headers: json_headers
        
        expect(response).to have_http_status(:created)
        
        json = JSON.parse(response.body)
        expect(json['id']).to be_present
        expect(json['email']).to eq(support_data[:email])
        expect(json['message']).to eq(support_data[:message])
        expect(json['status']).to eq('open')
      end
      
      it "validates required fields" do
        post "/api/support_requests",
             params: {}.to_json,
             headers: json_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "Purchases" do
    let(:user) { create(:mobbie_user, :anonymous) }
    let(:token) { generate_jwt_for(user) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
    
    describe "POST /api/purchases" do
      let(:purchase_data) do
        {
          product_id: "com.mobbie.premium.weekly",
          transaction_id: "txn_#{SecureRandom.hex(8)}",
          receipt_data: Base64.encode64("fake-receipt-data"),
          price_cents: 1299,
          currency: "USD",
          platform: "ios"
        }
      end
      
      before do
        # Mock Apple IAP verification
        allow_any_instance_of(Mobbie::AppleIapService).to receive(:verify_receipt).and_return({
          status: 0,
          receipt: {
            in_app: [{
              product_id: purchase_data[:product_id],
              transaction_id: purchase_data[:transaction_id],
              purchase_date_ms: Time.current.to_i * 1000
            }]
          }
        })
      end
      
      it "requires authentication" do
        post "/api/purchases",
             params: purchase_data.to_json,
             headers: json_headers
        
        expect(response).to have_http_status(:unauthorized)
      end
      
      it "creates purchase when authenticated" do
        post "/api/purchases",
             params: purchase_data.to_json,
             headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:created)
        
        json = JSON.parse(response.body)
        expect(json['product_id']).to eq(purchase_data[:product_id])
        expect(json['transaction_id']).to eq(purchase_data[:transaction_id])
        expect(json['user_id']).to eq(user.id)
      end
    end
  end
  
  describe "Subscriptions" do
    let(:user) { create(:mobbie_user, :anonymous) }
    let(:token) { generate_jwt_for(user) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
    let!(:subscription_plan) { create(:mobbie_subscription_plan) }
    
    describe "POST /api/subscriptions" do
      let(:subscription_data) do
        {
          product_id: subscription_plan.product_id,
          transaction_id: "sub_#{SecureRandom.hex(8)}",
          receipt_data: Base64.encode64("fake-subscription-receipt"),
          platform: "ios"
        }
      end
      
      before do
        # Mock Apple IAP verification
        allow_any_instance_of(Mobbie::AppleIapService).to receive(:verify_receipt).and_return({
          status: 0,
          latest_receipt_info: [{
            product_id: subscription_data[:product_id],
            transaction_id: subscription_data[:transaction_id],
            purchase_date_ms: Time.current.to_i * 1000,
            expires_date_ms: 7.days.from_now.to_i * 1000
          }]
        })
      end
      
      it "creates subscription when authenticated" do
        post "/api/subscriptions",
             params: subscription_data.to_json,
             headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:created)
        
        json = JSON.parse(response.body)
        expect(json['product_id']).to eq(subscription_data[:product_id])
        expect(json['status']).to eq('active')
        expect(json['expires_at']).to be_present
      end
    end
    
    describe "GET /api/subscriptions" do
      it "lists user subscriptions" do
        create_list(:mobbie_subscription, 2, user: user)
        
        get "/api/subscriptions", headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['subscriptions']).to be_an(Array)
        expect(json['subscriptions'].size).to eq(2)
      end
    end
    
    describe "GET /api/subscriptions/current" do
      it "returns current active subscription" do
        subscription = create(:mobbie_subscription, :active, user: user)
        
        get "/api/subscriptions/current", headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['subscription']['id']).to eq(subscription.id)
        expect(json['subscription']['status']).to eq('active')
      end
      
      it "returns null when no active subscription" do
        get "/api/subscriptions/current", headers: auth_headers.merge(json_headers)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['subscription']).to be_nil
      end
    end
  end
  
  describe "Error Handling" do
    it "returns consistent error format" do
      post "/api/auth/anonymous", 
           params: {}.to_json,
           headers: json_headers
      
      json = JSON.parse(response.body)
      expect(json).to have_key('error')
      expect(json['error']).to be_a(String)
    end
  end
end