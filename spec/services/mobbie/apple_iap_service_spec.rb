require_relative '../../simple_spec_helper'
require 'webmock/rspec'

RSpec.describe Mobbie::AppleIapService do
  describe '.validate_jws_token' do
    let(:valid_jws_token) do
      payload = {
        transactionId: '2000000123456789',
        originalTransactionId: '2000000123456789',
        productId: 'com.mobbie.premium.weekly',
        purchaseDate: (Time.current.to_f * 1000).to_i,
        expiresDate: (1.month.from_now.to_f * 1000).to_i,
        type: 'Auto-Renewable Subscription',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Sandbox'
      }
      
      header = Base64.urlsafe_encode64({ alg: 'ES256', typ: 'JWT' }.to_json, padding: false)
      payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
      signature = Base64.urlsafe_encode64('fake_signature', padding: false)
      
      "#{header}.#{payload_encoded}.#{signature}"
    end

    context 'with valid JWS token' do
      it 'extracts transaction data' do
        result = described_class.validate_jws_token(valid_jws_token)
        
        expect(result).to include(
          transaction_id: '2000000123456789',
          original_transaction_id: '2000000123456789',
          product_id: 'com.mobbie.premium.weekly',
          environment: 'Sandbox',
          quantity: 1,
          type: 'Auto-Renewable Subscription'
        )
        
        expect(result[:purchase_date]).to be_a(Time)
        expect(result[:expires_date]).to be_a(Time)
      end
    end

    context 'with JSON wrapped token' do
      it 'extracts token from JSON' do
        json_wrapped = { jws: valid_jws_token }.to_json
        result = described_class.validate_jws_token(json_wrapped)
        
        expect(result[:transaction_id]).to eq('2000000123456789')
      end

      it 'handles alternative JSON keys' do
        json_wrapped = { token: valid_jws_token }.to_json
        result = described_class.validate_jws_token(json_wrapped)
        
        expect(result[:transaction_id]).to eq('2000000123456789')
      end
    end

    context 'with invalid token format' do
      it 'raises validation error for malformed token' do
        expect {
          described_class.validate_jws_token('invalid.token')
        }.to raise_error(Mobbie::AppleIapService::ValidationError, /Invalid JWS token/)
      end

      it 'raises validation error for non-base64 payload' do
        invalid_token = 'header.invalid!payload.signature'
        
        expect {
          described_class.validate_jws_token(invalid_token)
        }.to raise_error(Mobbie::AppleIapService::ValidationError)
      end
    end

    context 'with StoreKit test environment' do
      let(:test_token) do
        payload = {
          transactionId: 'test123',
          originalTransactionId: 'test123',
          productId: 'com.test.product',
          purchaseDate: Time.current.to_i * 1000,
          environment: 'Xcode'
        }
        
        header = Base64.urlsafe_encode64({ alg: 'ES256' }.to_json, padding: false)
        payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
        signature = Base64.urlsafe_encode64('test', padding: false)
        
        "#{header}.#{payload_encoded}.#{signature}"
      end

      it 'skips Apple API validation for Xcode environment' do
        expect(described_class).not_to receive(:validate_with_apple_api)
        
        result = described_class.validate_jws_token(test_token)
        expect(result[:environment]).to eq('Xcode')
      end
    end

    context 'with configured Apple credentials' do
      before do
        allow(Mobbie::Rails.configuration).to receive(:apple_issuer_id).and_return('issuer123')
        allow(Mobbie::Rails.configuration).to receive(:apple_key_id).and_return('key123')
        allow(Mobbie::Rails.configuration).to receive(:apple_private_key).and_return('private_key')
        allow(Mobbie::Rails.configuration).to receive(:apple_bundle_id).and_return('com.test.app')
      end

      it 'attempts Apple API validation' do
        # Mock the API calls
        stub_request(:get, "https://api.storekit.itunes.apple.com/inApps/v1/transactions/2000000123456789")
          .with(headers: { 'Authorization' => 'Bearer jwt_token' })
          .to_return(status: 200, body: {}.to_json)
          
        stub_request(:get, "https://api.storekit-sandbox.itunes.apple.com/inApps/v1/transactions/2000000123456789")
          .with(headers: { 'Authorization' => 'Bearer jwt_token' })
          .to_return(status: 200, body: {}.to_json)
        
        allow(described_class).to receive(:generate_app_store_connect_token).and_return('jwt_token')
        
        result = described_class.validate_jws_token(valid_jws_token)
        expect(result).to be_present
      end
    end
  end

  describe '.validate_production_environment?' do
    context 'in production Rails environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'accepts only Production environment' do
        expect(described_class.validate_production_environment?('Production')).to be true
        expect(described_class.validate_production_environment?('Sandbox')).to be false
        expect(described_class.validate_production_environment?('Xcode')).to be false
      end
    end

    context 'in development/test Rails environment' do
      it 'accepts Sandbox environment' do
        expect(described_class.validate_production_environment?('Sandbox')).to be true
      end

      it 'accepts Xcode environment' do
        expect(described_class.validate_production_environment?('Xcode')).to be true
      end

      it 'accepts StoreKit Testing environment' do
        expect(described_class.validate_production_environment?('StoreKit Testing')).to be true
      end

      it 'rejects Production environment' do
        expect(described_class.validate_production_environment?('Production')).to be false
      end
    end
  end

  describe 'transaction data extraction' do
    let(:subscription_token) do
      payload = {
        transactionId: '123',
        originalTransactionId: '456',
        productId: 'com.mobbie.premium.yearly',
        purchaseDate: 1234567890000,
        expiresDate: 2234567890000,
        type: 'Auto-Renewable Subscription',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Sandbox',
        quantity: 1
      }
      
      header = Base64.urlsafe_encode64({ alg: 'ES256' }.to_json, padding: false)
      payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
      signature = Base64.urlsafe_encode64('sig', padding: false)
      
      "#{header}.#{payload_encoded}.#{signature}"
    end

    let(:consumable_token) do
      payload = {
        transactionId: '789',
        originalTransactionId: '789',
        productId: 'credit_pack_large',
        purchaseDate: 1234567890000,
        type: 'Consumable',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Sandbox',
        quantity: 1
      }
      
      header = Base64.urlsafe_encode64({ alg: 'ES256' }.to_json, padding: false)
      payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
      signature = Base64.urlsafe_encode64('sig', padding: false)
      
      "#{header}.#{payload_encoded}.#{signature}"
    end

    it 'extracts subscription data correctly' do
      result = described_class.validate_jws_token(subscription_token)
      
      expect(result[:transaction_id]).to eq('123')
      expect(result[:original_transaction_id]).to eq('456')
      expect(result[:product_id]).to eq('com.mobbie.premium.yearly')
      expect(result[:type]).to eq('Auto-Renewable Subscription')
      expect(result[:expires_date]).to be_a(Time)
      expect(result[:expires_date]).to be > result[:purchase_date]
    end

    it 'handles consumable purchases without expiry' do
      result = described_class.validate_jws_token(consumable_token)
      
      expect(result[:transaction_id]).to eq('789')
      expect(result[:product_id]).to eq('credit_pack_large')
      expect(result[:type]).to eq('Consumable')
      expect(result[:expires_date]).to be_nil
    end
  end

  describe 'family sharing' do
    let(:family_sharing_token) do
      payload = {
        transactionId: 'family123',
        originalTransactionId: 'family123',
        productId: 'com.mobbie.premium.family',
        purchaseDate: Time.current.to_i * 1000,
        expiresDate: 1.month.from_now.to_i * 1000,
        type: 'Auto-Renewable Subscription',
        inAppOwnershipType: 'FAMILY_SHARED',
        environment: 'Sandbox'
      }
      
      header = Base64.urlsafe_encode64({ alg: 'ES256' }.to_json, padding: false)
      payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
      signature = Base64.urlsafe_encode64('sig', padding: false)
      
      "#{header}.#{payload_encoded}.#{signature}"
    end

    it 'identifies family shared purchases' do
      result = described_class.validate_jws_token(family_sharing_token)
      
      expect(result[:transaction_id]).to eq('family123')
      expect(result[:type]).to eq('Auto-Renewable Subscription')
      # Note: inAppOwnershipType is not currently extracted, but could be added
    end
  end
end