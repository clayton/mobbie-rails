module Mobbie
  module Api
    class SupportRequestsController < Mobbie::ApplicationController
      def create
        support_ticket = build_support_ticket
        support_ticket.save!
        
        render json: {
          support_ticket: support_ticket.as_json
        }, status: :created
      end
      
      private
      
      def build_support_ticket
        ticket = Mobbie::SupportTicket.new(support_ticket_params)
        ticket.user = current_user
        ticket
      end
      
      def support_ticket_params
        params.permit(:name, :email, :message, :app_version, :device_info, :platform)
      end
    end
  end
end