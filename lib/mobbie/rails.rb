# frozen_string_literal: true

require "jwt"
require "bcrypt"
require_relative "rails/version"
require_relative "rails/engine" if defined?(Rails::Engine)

module Mobbie
  module Rails
    class Error < StandardError; end
    
    # JWT Configuration
    mattr_accessor :jwt_secret_key
    mattr_accessor :jwt_expiration
    mattr_accessor :jwt_refresh_expiration
    
    # Apple IAP Configuration
    mattr_accessor :apple_issuer_id
    mattr_accessor :apple_key_id
    mattr_accessor :apple_private_key
    mattr_accessor :apple_bundle_id
    
    # Subscription Configuration
    mattr_accessor :subscription_products
    
    def self.configure
      yield self
    end
    
    def self.configuration
      self
    end
  end
end
