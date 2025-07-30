require 'rails/generators'

module Mobbie
  module Generators
    class SampleDataGenerator < ::Rails::Generators::Base
      desc "Creates sample paywall data for testing"
      
      def create_sample_data
        say "Creating sample paywall config...", :green
        create_paywall_config
        
        say "Creating sample subscription plans...", :green
        create_subscription_plans
        
        say "Creating sample paywall offerings...", :green
        create_offerings
        
        say "Creating sample paywall features...", :green
        create_features
        
        say "Creating display settings...", :green
        create_display_settings
        
        say "\nSample data created successfully!", :green
      end
      
      private
      
      def create_paywall_config
        @paywall_config = Mobbie::PaywallConfig.find_or_create_by!(active: true) do |config|
          config.title = "Unlock Premium Features"
          config.subtitle = "Get unlimited access to all features"
          config.welcome_title = "Welcome to Premium!"
          config.welcome_subtitle = "Start your journey with exclusive benefits"
          config.show_skip_button = true
          config.skip_button_text = "Maybe Later"
          config.display_order = 1
        end
      end
      
      def create_subscription_plans
        plans = [
          {
            product_id: "com.mobbie.premium.weekly",
            name: "Weekly Premium",
            description: "Premium access for 7 days",
            tier: "premium",
            billing_period: "week",
            price_cents: 1299,
            currency: "USD",
            features: {
              unlimited_access: true,
              premium_templates: true,
              priority_support: true,
              advanced_analytics: true
            },
            display_order: 1,
            active: true
          },
          {
            product_id: "com.mobbie.premium.yearly",
            name: "Yearly Premium",
            description: "Premium access for 365 days - Best Value!",
            tier: "premium",
            billing_period: "year",
            price_cents: 2999,
            currency: "USD",
            features: {
              unlimited_access: true,
              premium_templates: true,
              priority_support: true,
              advanced_analytics: true,
              exclusive_content: true
            },
            display_order: 2,
            active: true
          }
        ]
        
        plans.each do |plan_attrs|
          Mobbie::SubscriptionPlan.find_or_create_by!(product_id: plan_attrs[:product_id]) do |plan|
            plan.assign_attributes(plan_attrs)
          end
        end
      end
      
      def create_offerings
        offerings = [
          {
            product_id: "com.mobbie.premium.weekly",
            display_name: "Weekly Premium",
            description: "$12.99 per week",
            cartoon_count: nil,
            is_welcome_offer: true,
            is_featured: false,
            display_order: 1,
            badge_text: "TRY IT OUT",
            paywall_config_id: @paywall_config.id
          },
          {
            product_id: "com.mobbie.premium.yearly",
            display_name: "Yearly Premium",
            description: "$29.99 per year",
            cartoon_count: nil,
            is_welcome_offer: false,
            is_featured: true,
            display_order: 2,
            badge_text: "SAVE 77%",
            paywall_config_id: @paywall_config.id
          }
        ]
        
        offerings.each do |offering_attrs|
          Mobbie::PaywallOffering.find_or_create_by!(
            product_id: offering_attrs[:product_id],
            paywall_config_id: offering_attrs[:paywall_config_id]
          ) do |offering|
            offering.assign_attributes(offering_attrs)
          end
        end
      end
      
      def create_features
        features = [
          {
            title: "Unlimited Access",
            icon: "infinity.circle.fill",
            description: "Create unlimited content without restrictions",
            display_order: 1
          },
          {
            title: "Premium Templates",
            icon: "sparkles",
            description: "Access exclusive professional templates",
            display_order: 2
          },
          {
            title: "Priority Support",
            icon: "headphones.circle.fill",
            description: "Get help from our team within 24 hours",
            display_order: 3
          },
          {
            title: "Advanced Analytics",
            icon: "chart.line.uptrend.xyaxis",
            description: "Track your progress with detailed insights",
            display_order: 4
          }
        ]
        
        features.each do |feature_attrs|
          Mobbie::PaywallFeature.find_or_create_by!(
            title: feature_attrs[:title],
            paywall_config_id: @paywall_config.id
          ) do |feature|
            feature.assign_attributes(feature_attrs.merge(paywall_config_id: @paywall_config.id))
          end
        end
      end
      
      def create_display_settings
        Mobbie::PaywallDisplaySettings.find_or_create_by!(is_active: true) do |settings|
          settings.title = "Unlock Premium Features"
          settings.subtitle = "Get unlimited access to all features"
          settings.welcome_title = "Welcome to Premium!"
          settings.welcome_subtitle = "Start your journey with exclusive benefits"
          settings.show_skip_button = true
          settings.skip_button_text = "Maybe Later"
        end
      end
    end
  end
end