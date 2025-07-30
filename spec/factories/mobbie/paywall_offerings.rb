FactoryBot.define do
  factory :mobbie_paywall_offering, class: 'Mobbie::PaywallOffering' do
    association :paywall_config, factory: :mobbie_paywall_config
    product_id { "com.mobbie.premium.weekly" }
    display_name { "Weekly Premium" }
    description { "$12.99 per week" }
    cartoon_count { nil }
    is_welcome_offer { true }
    is_featured { false }
    display_order { 1 }
    badge_text { "TRY IT OUT" }
    is_visible { true }
    is_visible_for_onboarding { true }
    
    trait :yearly do
      product_id { "com.mobbie.premium.yearly" }
      display_name { "Yearly Premium" }
      description { "$29.99 per year" }
      is_welcome_offer { false }
      is_featured { true }
      display_order { 2 }
      badge_text { "SAVE 77%" }
    end
    
    trait :hidden do
      is_visible { false }
      is_visible_for_onboarding { false }
    end
    
    trait :onboarding_only do
      is_visible { false }
      is_visible_for_onboarding { true }
    end
  end
end