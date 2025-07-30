FactoryBot.define do
  factory :mobbie_subscription_plan, class: 'Mobbie::SubscriptionPlan' do
    product_id { "com.mobbie.premium.weekly" }
    name { "Weekly Premium" }
    description { "Premium access for 7 days" }
    tier { "premium" }
    billing_period { "week" }
    price_cents { 1299 }
    currency { "USD" }
    features { { unlimited_access: true, premium_templates: true } }
    display_order { 1 }
    active { true }
    
    trait :yearly do
      product_id { "com.mobbie.premium.yearly" }
      name { "Yearly Premium" }
      description { "Premium access for 365 days - Best Value!" }
      billing_period { "year" }
      price_cents { 2999 }
      display_order { 2 }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :free do
      product_id { "com.mobbie.free" }
      name { "Free Plan" }
      description { "Basic access with limits" }
      tier { "free" }
      billing_period { "month" }
      price_cents { 0 }
      features { { limited_access: true } }
    end
  end
end