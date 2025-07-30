FactoryBot.define do
  factory :mobbie_paywall_feature, class: 'Mobbie::PaywallFeature' do
    association :paywall_config, factory: :mobbie_paywall_config
    sequence(:title) { |n| "Feature #{n}" }
    icon { ["infinity.circle.fill", "sparkles", "headphones.circle.fill", "chart.line.uptrend.xyaxis"].sample }
    sequence(:description) { |n| "Amazing feature description #{n}" }
    sequence(:display_order) { |n| n }
    is_visible { true }
    
    trait :hidden do
      is_visible { false }
    end
    
    trait :unlimited_access do
      title { "Unlimited Access" }
      icon { "infinity.circle.fill" }
      description { "Create unlimited content without restrictions" }
    end
    
    trait :premium_templates do
      title { "Premium Templates" }
      icon { "sparkles" }
      description { "Access exclusive professional templates" }
    end
    
    trait :priority_support do
      title { "Priority Support" }
      icon { "headphones.circle.fill" }
      description { "Get help from our team within 24 hours" }
    end
    
    trait :advanced_analytics do
      title { "Advanced Analytics" }
      icon { "chart.line.uptrend.xyaxis" }
      description { "Track your progress with detailed insights" }
    end
  end
end