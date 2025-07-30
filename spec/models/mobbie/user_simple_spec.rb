require_relative '../../simple_spec_helper'

RSpec.describe Mobbie::User, type: :model do
  describe 'basic functionality' do
    it 'creates a user' do
      user = Mobbie::User.create!(
        device_id: 'test123',
        email: 'test@example.com',
        is_anonymous: false
      )
      
      expect(user).to be_persisted
      expect(user.device_id).to eq('test123')
      expect(user.email).to eq('test@example.com')
    end
    
    it 'validates device_id for anonymous users' do
      user = Mobbie::User.new(is_anonymous: true)
      expect(user).not_to be_valid
      expect(user.errors[:device_id]).to include("can't be blank")
    end
    
    it 'has credit balance' do
      user = Mobbie::User.create!(device_id: 'test456', is_anonymous: true)
      expect(user.credit_balance).to eq(0)
      
      user.add_credits(100)
      expect(user.reload.credit_balance).to eq(100)
    end
  end
  
  describe 'subscriptions' do
    let(:user) { Mobbie::User.create!(device_id: 'test789', is_anonymous: true) }
    
    it 'has no active subscription by default' do
      expect(user.active_subscription).to be_nil
      expect(user.premium?).to be false
    end
    
    it 'identifies premium users' do
      Mobbie::Subscription.create!(
        user: user,
        original_transaction_id: 'sub123',
        transaction_id: 'sub123',
        product_id: 'com.mobbie.premium.weekly',
        purchase_date: Time.current,
        expires_at: 1.week.from_now,
        platform: 'ios',
        status: 'active',
        tier: 'premium'
      )
      
      expect(user.premium?).to be true
      expect(user.subscription_tier).to eq('premium')
    end
  end
end