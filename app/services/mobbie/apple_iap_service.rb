require 'base64'
require 'json'
require 'net/http'
require 'jwt'

module Mobbie
  class AppleIapService
    APPLE_PUBLIC_KEY_URL = 'https://appleid.apple.com/auth/keys'.freeze
    PRODUCTION_API_URL = 'https://api.storekit.itunes.apple.com'.freeze
    SANDBOX_API_URL = 'https://api.storekit-sandbox.itunes.apple.com'.freeze
    
    class << self
      def validate_jws_token(jws_token)
        # Handle if jws_token is actually JSON data
        if jws_token.is_a?(String) && jws_token.start_with?('{')
          begin
            # Parse as JSON and extract the actual token
            parsed = JSON.parse(jws_token)
            jws_token = parsed['jws'] || parsed['token'] || parsed['transaction'] || jws_token
          rescue JSON::ParserError
            # Not JSON, use as is
          end
        end
        
        # JWS token has format: header.payload.signature
        parts = jws_token.split('.')
        raise ValidationError, "Invalid JWS token: Not enough or too many segments (found #{parts.length})" unless parts.length == 3
        
        begin
          # Decode the payload (middle part) - JWS uses Base64 URL encoding
          payload_data = Base64.urlsafe_decode64(parts[1])
          jws_payload = JSON.parse(payload_data).with_indifferent_access
          
          # Extract transaction ID for API validation
          transaction_id = jws_payload['transactionId']
          
          # For StoreKit Configuration test transactions, skip Apple API validation
          if jws_payload['environment'] == 'Xcode' || jws_payload['environment'] == 'StoreKit Testing'
            return extract_transaction_data(jws_payload)
          end
          
          # For real transactions, validate with Apple's Server API if configured
          if app_store_credentials_configured?
            validate_with_apple_api(transaction_id)
          end
          
          # Return the extracted data
          extract_transaction_data(jws_payload)
        rescue => e
          Rails.logger.error "Failed to decode JWS token: #{e.message}"
          raise ValidationError, "Invalid JWS token: #{e.message}"
        end
      end
      
      def validate_production_environment?(environment)
        # For development/test, accept Xcode, Sandbox, or StoreKit Testing environments
        # For production, only accept Production environment
        if Rails.env.production?
          environment == 'Production'
        else
          ['Sandbox', 'Xcode', 'StoreKit Testing'].include?(environment)
        end
      end
      
      private
      
      def extract_transaction_data(payload)
        {
          transaction_id: payload['transactionId'],
          original_transaction_id: payload['originalTransactionId'],
          product_id: payload['productId'],
          purchase_date: Time.at(payload['purchaseDate'].to_i / 1000.0),
          expires_date: payload['expiresDate'] ? Time.at(payload['expiresDate'].to_i / 1000.0) : nil,
          environment: payload['environment'],
          quantity: payload['quantity'] || 1,
          type: payload['type']
        }
      end
      
      def app_store_credentials_configured?
        config = Mobbie::Rails.configuration
        config.apple_issuer_id.present? && 
          config.apple_key_id.present? && 
          config.apple_private_key.present? &&
          config.apple_bundle_id.present?
      end
      
      def validate_with_apple_api(transaction_id)
        # Try production first
        result = call_apple_server_api(PRODUCTION_API_URL, transaction_id)
        
        # If not found in production, try sandbox
        if result[:status] == 404 || result[:status] == 401
          Rails.logger.info "Transaction not found in production, trying sandbox"
          sandbox_result = call_apple_server_api(SANDBOX_API_URL, transaction_id)
          return sandbox_result if sandbox_result[:valid]
        end
        
        raise ValidationError, "Transaction validation failed with Apple" unless result[:valid]
        result
      end
      
      def call_apple_server_api(base_url, transaction_id)
        uri = URI("#{base_url}/inApps/v1/transactions/#{transaction_id}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        jwt_token = generate_app_store_connect_token
        return { valid: false, status: 401 } unless jwt_token
        
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{jwt_token}"
        request['Accept'] = 'application/json'
        
        begin
          response = http.request(request)
          
          case response.code.to_i
          when 200
            { valid: true, status: 200 }
          else
            { valid: false, status: response.code.to_i }
          end
        rescue => e
          Rails.logger.error "Error calling Apple Server API: #{e.message}"
          { valid: false, status: -1 }
        end
      end
      
      def generate_app_store_connect_token
        config = Mobbie::Rails.configuration
        now = Time.now.to_i
        
        payload = {
          iss: config.apple_issuer_id,
          iat: now,
          exp: now + 1200, # 20 minutes
          aud: 'appstoreconnect-v1',
          bid: config.apple_bundle_id
        }
        
        header = {
          alg: 'ES256',
          kid: config.apple_key_id,
          typ: 'JWT'
        }
        
        # Get private key and handle literal \n
        key_content = config.apple_private_key
        return nil unless key_content
        
        key_content = key_content.gsub('\\n', "\n") if key_content.include?('\\n')
        
        private_key = OpenSSL::PKey.read(key_content)
        JWT.encode(payload, private_key, 'ES256', header)
      rescue => e
        Rails.logger.error "Failed to generate App Store Connect token: #{e.message}"
        nil
      end
    end

    class ValidationError < StandardError; end
  end
end