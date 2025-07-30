require_relative '../../simple_spec_helper'

RSpec.describe Mobbie::Subscription, type: :model do
  let(:user) { create(:mobbie_user) }
  let(:subscription) { create(:mobbie_subscription, user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).class_name('Mobbie::User') }
    it { is_expected.to belong_to(:subscription_plan).class_name('Mobbie::SubscriptionPlan').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:original_transaction_id) }
    it { is_expected.to validate_presence_of(:transaction_id) }
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:purchase_date) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_presence_of(:platform) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:tier) }
    
    it 'validates uniqueness of original_transaction_id' do
      subscription
      duplicate = build(:mobbie_subscription, original_transaction_id: subscription.original_transaction_id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:original_transaction_id]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it 'defines platform enum' do
      expect(described_class.platforms).to eq({
        'ios' => 'ios',
        'android' => 'android',
        'system' => 'system',
        'admin' => 'admin'
      })
    end

    it 'defines status enum' do
      expect(described_class.statuses).to eq({
        'active' => 'active',
        'expired' => 'expired',
        'cancelled' => 'cancelled',
        'grace_period' => 'grace_period',
        'refunded' => 'refunded'
      })
    end
  end

  describe 'scopes' do
    let!(:active_sub) { create(:mobbie_subscription, :active) }
    let!(:expired_sub) { create(:mobbie_subscription, :expired) }
    let!(:future_expired) { create(:mobbie_subscription, status: 'active', expires_at: 1.day.ago) }

    describe '.active' do
      it 'returns subscriptions with active status and future expiry' do
        results = described_class.active
        expect(results).to include(active_sub)
        expect(results).not_to include(expired_sub, future_expired)
      end
    end

    describe '.expired' do
      it 'returns subscriptions with expired status or past expiry' do
        results = described_class.expired
        expect(results).to include(expired_sub, future_expired)
        expect(results).not_to include(active_sub)
      end
    end
  end

  describe '#active?' do
    context 'when status is active and not expired' do
      let(:subscription) { build(:mobbie_subscription, :active) }
      
      it 'returns true' do
        expect(subscription.active?).to be true
      end
    end

    context 'when status is active but expired' do
      let(:subscription) { build(:mobbie_subscription, status: 'active', expires_at: 1.day.ago) }
      
      it 'returns false' do
        expect(subscription.active?).to be false
      end
    end

    context 'when status is not active' do
      let(:subscription) { build(:mobbie_subscription, :expired) }
      
      it 'returns false' do
        expect(subscription.active?).to be false
      end
    end
  end

  describe '#expired?' do
    context 'when status is expired' do
      let(:subscription) { build(:mobbie_subscription, :expired) }
      
      it 'returns true' do
        expect(subscription.expired?).to be true
      end
    end

    context 'when expires_at is in the past' do
      let(:subscription) { build(:mobbie_subscription, expires_at: 1.day.ago) }
      
      it 'returns true' do
        expect(subscription.expired?).to be true
      end
    end

    context 'when active and not expired' do
      let(:subscription) { build(:mobbie_subscription, :active) }
      
      it 'returns false' do
        expect(subscription.expired?).to be false
      end
    end
  end

  describe '#in_grace_period?' do
    context 'when status is grace_period' do
      let(:subscription) { build(:mobbie_subscription, :grace_period) }
      
      it 'returns true' do
        expect(subscription.in_grace_period?).to be true
      end
    end

    context 'when status is not grace_period' do
      let(:subscription) { build(:mobbie_subscription, :active) }
      
      it 'returns false' do
        expect(subscription.in_grace_period?).to be false
      end
    end
  end

  describe '#days_remaining' do
    context 'when expires_at is in the future' do
      let(:subscription) { build(:mobbie_subscription, expires_at: 10.days.from_now) }
      
      it 'returns the number of days' do
        expect(subscription.days_remaining).to eq(10)
      end
    end

    context 'when expires_at is in the past' do
      let(:subscription) { build(:mobbie_subscription, expires_at: 5.days.ago) }
      
      it 'returns 0' do
        expect(subscription.days_remaining).to eq(0)
      end
    end

    context 'when expires_at is nil' do
      let(:subscription) { build(:mobbie_subscription, expires_at: nil) }
      
      it 'returns nil' do
        expect(subscription.days_remaining).to be_nil
      end
    end
  end

  describe '#tier_from_product_id' do
    context 'when product_id contains premium' do
      let(:subscription) { build(:mobbie_subscription, product_id: 'com.mobbie.premium.weekly') }
      
      it 'returns premium' do
        expect(subscription.tier_from_product_id).to eq('premium')
      end
    end

    context 'when product_id does not contain premium' do
      let(:subscription) { build(:mobbie_subscription, product_id: 'com.mobbie.basic') }
      
      it 'returns free' do
        expect(subscription.tier_from_product_id).to eq('free')
      end
    end
  end

  describe 'subscription lifecycle' do
    let(:subscription) { create(:mobbie_subscription, :active) }

    it 'handles transition from active to grace_period' do
      subscription.update!(status: 'grace_period')
      expect(subscription.reload.status).to eq('grace_period')
    end

    it 'handles transition from grace_period to expired' do
      subscription.update!(status: 'grace_period')
      subscription.update!(status: 'expired')
      expect(subscription.reload.status).to eq('expired')
    end

    it 'handles refund' do
      subscription.update!(status: 'refunded')
      expect(subscription.reload.status).to eq('refunded')
    end
  end
end