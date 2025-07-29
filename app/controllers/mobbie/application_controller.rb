module Mobbie
  class ApplicationController < ActionController::API
    include Mobbie::JwtAuthenticatable
    
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    
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
  end
end