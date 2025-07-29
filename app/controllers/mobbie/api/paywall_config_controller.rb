module Mobbie
  module Api
    class PaywallConfigController < Mobbie::ApplicationController
      before_action :authenticate_user!
      
      def show
        # Try to use PaywallConfig if available, otherwise fall back to individual models
        if paywall_config = Mobbie::PaywallConfig.current
          render json: paywall_config.to_api_json
        else
          render json: {
            offerings: offerings_json,
            features: features_json,
            display_settings: display_settings_json
          }
        end
      end
      
      private
      
      def offerings_json
        Mobbie::PaywallOffering.visible.ordered.map(&:as_json)
      end
      
      def features_json
        Mobbie::PaywallFeature.visible.ordered.map(&:as_json)
      end
      
      def display_settings_json
        Mobbie::PaywallDisplaySettings.current.as_json
      end
    end
  end
end