FactoryBot.define do
  factory :mobbie_paywall_config, class: 'Mobbie::PaywallConfig' do
    title { "Unlock Premium Features" }
    subtitle { "Get unlimited access to all features" }
    welcome_title { "Welcome to Premium!" }
    welcome_subtitle { "Start your journey with exclusive benefits" }
    show_skip_button { true }
    skip_button_text { "Maybe Later" }
    active { false }
    display_order { 1 }
    
    trait :active do
      active { true }
    end
    
    trait :with_offerings do
      after(:create) do |config|
        create(:mobbie_paywall_offering, paywall_config: config)
        create(:mobbie_paywall_offering, :yearly, paywall_config: config)
      end
    end
    
    trait :with_features do
      after(:create) do |config|
        create_list(:mobbie_paywall_feature, 4, paywall_config: config)
      end
    end
    
    trait :complete do
      with_offerings
      with_features
    end
  end
end