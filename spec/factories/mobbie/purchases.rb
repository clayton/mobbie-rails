FactoryBot.define do
  factory :mobbie_purchase, class: 'Mobbie::Purchase' do
    association :user, factory: :mobbie_user
    sequence(:original_transaction_id) { |n| "purchase_#{n}_#{SecureRandom.hex(8)}" }
    sequence(:transaction_id) { |n| "trans_#{n}_#{SecureRandom.hex(8)}" }
    product_id { "credit_pack_medium" }
    credits_granted { 500 }
    purchase_date { Time.current }
    platform { "ios" }
    
    trait :small_pack do
      product_id { "credit_pack_small" }
      credits_granted { 100 }
    end
    
    trait :large_pack do
      product_id { "credit_pack_large" }
      credits_granted { 1000 }
    end
    
    trait :xl_pack do
      product_id { "credit_pack_xl" }
      credits_granted { 2500 }
    end
    
    trait :android do
      platform { "android" }
    end
    
    trait :admin_granted do
      platform { "admin" }
      product_id { "admin_grant" }
    end
    
    trait :system_granted do
      platform { "system" }
      product_id { "system_grant" }
    end
  end
end