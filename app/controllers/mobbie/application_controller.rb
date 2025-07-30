module Mobbie
  class ApplicationController < ActionController::API
    include Mobbie::JwtAuthenticatable
    
    # Disable automatic parameter wrapping for API controllers
    wrap_parameters false
    
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    
    private
    
    def render_not_found
      render json: { error: "Record not found" }, status: :not_found
    end
    
    def render_unprocessable_entity(exception)
      render json: { 
        error: "Validation failed", 
        errors: exception.record.errors.full_messages 
      }, status: :unprocessable_entity
    end
    
    def render_bad_request(exception)
      render json: { 
        error: exception.message 
      }, status: :bad_request
    end
  end
end