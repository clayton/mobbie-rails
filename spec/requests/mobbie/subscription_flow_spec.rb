require 'rails_helper'

RSpec.describe 'Subscription Flow', type: :request do
  include AppleIapTestHelper
  
  let(:user) { create(:mobbie_user) }
  let(:headers) { auth_headers(user) }

  describe 'complete subscription purchase flow' do
    it 'handles the full subscription lifecycle' do
      # 1. Check initial state - no subscription
      get '/api/subscriptions/current', headers: headers
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['subscription']).to be_nil
      expect(json['message']).to eq('No active subscription')
      
      # 2. Purchase weekly subscription
      mock_apple_validation_success(
        product_id: 'com.mobbie.premium.weekly',
        expires_date: 1.week.from_now
      )
      mock_apple_production_environment(false)
      
      purchase_params = {
        product_id: 'com.mobbie.premium.weekly',
        jws_token: generate_mock_jws_token(product_id: 'com.mobbie.premium.weekly')
      }
      
      post '/api/subscriptions', params: purchase_params.to_json, headers: headers
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['subscription']).to include(
        'plan_id' => 'com.mobbie.premium.weekly',
        'plan_name' => 'Weekly Premium',
        'status' => 'active',
        'billing_period' => 'week'
      )
      
      # 3. Verify subscription is now active
      get '/api/subscriptions/current', headers: headers
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      expect(json['subscription']['status']).to eq('active')
      expect(json['subscription']['days_remaining']).to be_between(6, 7)
      
      # 4. Check user has premium access
      user.reload
      expect(user.premium?).to be true
      expect(user.subscription_tier).to eq('premium')
    end
  end

  describe 'subscription upgrade flow' do
    let!(:weekly_sub) do
      create(:mobbie_subscription,
        user: user,
        product_id: 'com.mobbie.premium.weekly',
        status: 'active',
        expires_at: 5.days.from_now
      )
    end

    it 'upgrades from weekly to yearly subscription' do
      # 1. Confirm current weekly subscription
      get '/api/subscriptions/current', headers: headers
      json = JSON.parse(response.body)
      expect(json['subscription']['plan_id']).to eq('com.mobbie.premium.weekly')
      
      # 2. Purchase yearly subscription
      mock_apple_validation_success(
        product_id: 'com.mobbie.premium.yearly',
        original_transaction_id: 'yearly_123',
        expires_date: 1.year.from_now
      )
      mock_apple_production_environment(false)
      
      upgrade_params = {
        product_id: 'com.mobbie.premium.yearly',
        jws_token: generate_mock_jws_token(
          product_id: 'com.mobbie.premium.yearly',
          original_transaction_id: 'yearly_123'
        )
      }
      
      post '/api/subscriptions', params: upgrade_params.to_json, headers: headers
      expect(response).to have_http_status(:success)
      
      # 3. Verify upgrade successful
      get '/api/subscriptions/current', headers: headers
      json = JSON.parse(response.body)
      
      expect(json['subscription']['plan_id']).to eq('com.mobbie.premium.yearly')
      expect(json['subscription']['billing_period']).to eq('year')
      expect(json['subscription']['days_remaining']).to be > 360
    end
  end

  describe 'subscription restoration' do
    let(:other_device_user) { create(:mobbie_user) }
    let!(:existing_subscription) do
      create(:mobbie_subscription,
        user: other_device_user,
        original_transaction_id: 'restore_123',
        product_id: 'com.mobbie.premium.yearly',
        status: 'active',
        expires_at: 6.months.from_now
      )
    end

    it 'restores subscription on new device' do
      # User signs in on new device and restores purchase
      mock_apple_validation_success(
        original_transaction_id: 'restore_123',
        product_id: 'com.mobbie.premium.yearly',
        expires_date: 6.months.from_now
      )
      mock_apple_production_environment(false)
      
      restore_params = {
        product_id: 'com.mobbie.premium.yearly',
        jws_token: generate_mock_jws_token(
          original_transaction_id: 'restore_123',
          product_id: 'com.mobbie.premium.yearly'
        )
      }
      
      # Restore purchase
      post '/api/subscriptions', params: restore_params.to_json, headers: headers
      expect(response).to have_http_status(:success)
      
      # Verify subscription transferred to current user
      existing_subscription.reload
      expect(existing_subscription.user_id).to eq(user.id)
      
      # Verify user has premium access
      expect(user.reload.premium?).to be true
    end
  end

  describe 'subscription expiry handling' do
    let!(:expiring_subscription) do
      create(:mobbie_subscription,
        user: user,
        status: 'active',
        expires_at: 1.hour.from_now
      )
    end

    it 'handles subscription expiration' do
      # 1. Confirm subscription is active
      expect(user.premium?).to be true
      
      # 2. Fast forward past expiration
      travel_to 2.hours.from_now do
        # Run expiry job
        Mobbie::SubscriptionExpiryJob.perform_now
        
        # Check subscription status
        expiring_subscription.reload
        expect(expiring_subscription.status).to eq('expired')
        
        # Check user no longer has premium
        expect(user.reload.premium?).to be false
        
        # API should reflect expired status
        get '/api/subscriptions/current', headers: headers
        json = JSON.parse(response.body)
        expect(json['subscription']).to be_nil
        expect(json['message']).to eq('No active subscription')
      end
    end
  end

  describe 'multiple subscriptions handling' do
    let!(:expired_sub) { create(:mobbie_subscription, :expired, user: user) }
    let!(:active_sub) { create(:mobbie_subscription, :active, user: user) }
    let!(:cancelled_sub) { create(:mobbie_subscription, :cancelled, user: user) }

    it 'lists all subscriptions ordered by expiry' do
      get '/api/subscriptions', headers: headers
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      expect(json['subscriptions'].length).to eq(3)
      
      # Should be ordered by expires_at desc
      statuses = json['subscriptions'].map { |s| s['status'] }
      expect(statuses).to eq(['active', 'cancelled', 'expired'])
    end

    it 'identifies only active subscription as current' do
      get '/api/subscriptions/current', headers: headers
      
      json = JSON.parse(response.body)
      expect(json['subscription']['id']).to eq(active_sub.id)
    end
  end

  describe 'purchase credits flow' do
    it 'handles credit purchase and balance update' do
      initial_balance = user.credit_balance
      
      # Purchase credit pack
      mock_apple_validation_success(
        product_id: 'credit_pack_large',
        expires_date: nil # Consumable has no expiry
      )
      mock_apple_production_environment(false)
      
      purchase_params = {
        product_id: 'credit_pack_large',
        jws_token: generate_mock_jws_token(product_id: 'credit_pack_large', expires_date: nil)
      }
      
      post '/api/purchases', params: purchase_params.to_json, headers: headers
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['credits_added']).to eq(1000)
      expect(json['data']['total_credits']).to eq(initial_balance + 1000)
      
      # Verify user balance updated
      expect(user.reload.credit_balance).to eq(initial_balance + 1000)
    end
  end
end