FactoryBot.define do
  factory :mobbie_user, class: 'Mobbie::User' do
    sequence(:device_id) { |n| "device_#{n}_#{SecureRandom.hex(8)}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    is_anonymous { false }
    credit_balance { 0 }
    
    trait :anonymous do
      is_anonymous { true }
      email { nil }
    end
    
    trait :with_credits do
      credit_balance { 100 }
    end
    
    trait :apple_linked do
      oauth_provider { 'apple' }
      oauth_uid { SecureRandom.hex(16) }
      name { Faker::Name.name }
    end
    
    trait :with_active_subscription do
      after(:create) do |user|
        create(:mobbie_subscription, :active, user: user)
      end
    end
    
    trait :with_expired_subscription do
      after(:create) do |user|
        create(:mobbie_subscription, :expired, user: user)
      end
    end
  end
end