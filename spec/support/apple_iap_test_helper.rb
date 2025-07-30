module AppleIapTestHelper
  def generate_mock_jws_token(
    product_id: "com.mobbie.premium.weekly",
    transaction_id: "2000000123456789",
    original_transaction_id: "2000000123456789",
    expires_date: 1.month.from_now,
    purchase_date: Time.current,
    environment: "Sandbox"
  )
    payload = {
      transactionId: transaction_id,
      originalTransactionId: original_transaction_id,
      productId: product_id,
      purchaseDate: (purchase_date.to_f * 1000).to_i,
      expiresDate: expires_date ? (expires_date.to_f * 1000).to_i : nil,
      type: "Auto-Renewable Subscription",
      inAppOwnershipType: "PURCHASED",
      environment: environment
    }
    
    # Create a fake JWS token (header.payload.signature)
    header = Base64.urlsafe_encode64({ alg: 'ES256', typ: 'JWT' }.to_json, padding: false)
    payload_encoded = Base64.urlsafe_encode64(payload.to_json, padding: false)
    signature = Base64.urlsafe_encode64('fake_signature', padding: false)
    
    "#{header}.#{payload_encoded}.#{signature}"
  end

  def mock_apple_validation_success(transaction_data = {})
    default_data = {
      transaction_id: "2000000123456789",
      original_transaction_id: "2000000123456789",
      product_id: "com.mobbie.premium.weekly",
      purchase_date: Time.current,
      expires_date: 1.month.from_now,
      environment: "Sandbox",
      quantity: 1,
      type: "Auto-Renewable Subscription"
    }
    
    allow(Mobbie::AppleIapService).to receive(:validate_jws_token)
      .and_return(default_data.merge(transaction_data))
  end

  def mock_apple_validation_failure(error_message = "Invalid JWS token")
    allow(Mobbie::AppleIapService).to receive(:validate_jws_token)
      .and_raise(Mobbie::AppleIapService::ValidationError, error_message)
  end

  def mock_apple_production_environment(is_production = true)
    allow(Mobbie::AppleIapService).to receive(:validate_production_environment?)
      .and_return(is_production)
  end
end