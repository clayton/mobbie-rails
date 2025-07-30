FactoryBot.define do
  factory :mobbie_subscription, class: 'Mobbie::Subscription' do
    association :user, factory: :mobbie_user
    sequence(:original_transaction_id) { |n| "original_#{n}_#{SecureRandom.hex(8)}" }
    sequence(:transaction_id) { |n| "transaction_#{n}_#{SecureRandom.hex(8)}" }
    product_id { "com.mobbie.premium.weekly" }
    purchase_date { Time.current }
    expires_at { 1.week.from_now }
    platform { "ios" }
    status { "active" }
    tier { "premium" }
    
    trait :active do
      status { "active" }
      expires_at { 1.week.from_now }
    end
    
    trait :expired do
      status { "expired" }
      expires_at { 1.week.ago }
    end
    
    trait :cancelled do
      status { "cancelled" }
    end
    
    trait :grace_period do
      status { "grace_period" }
      expires_at { 2.days.ago }
    end
    
    trait :refunded do
      status { "refunded" }
    end
    
    trait :yearly do
      product_id { "com.mobbie.premium.yearly" }
      expires_at { 1.year.from_now }
    end
    
    trait :with_plan do
      association :subscription_plan, factory: :mobbie_subscription_plan
    end
  end
end