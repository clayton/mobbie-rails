module Mobbie
  module Api
    class UsersController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      def link_apple_account
        current_user.link_apple_account!(
          apple_user_id: params.require(:apple_user_id),
          email: params[:email],
          name: params[:name]
        )
        
        render json: current_user.as_json
      end
    end
  end
end