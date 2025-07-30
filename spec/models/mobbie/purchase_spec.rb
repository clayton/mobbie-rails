require_relative '../../simple_spec_helper'

RSpec.describe Mobbie::Purchase, type: :model do
  let(:user) { create(:mobbie_user) }
  let(:purchase) { create(:mobbie_purchase, user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).class_name('Mobbie::User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:original_transaction_id) }
    it { is_expected.to validate_presence_of(:transaction_id) }
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:credits_granted) }
    it { is_expected.to validate_presence_of(:purchase_date) }
    it { is_expected.to validate_presence_of(:platform) }
    
    it { is_expected.to validate_numericality_of(:credits_granted).is_greater_than(0) }
    
    it 'validates uniqueness of original_transaction_id' do
      purchase
      duplicate = build(:mobbie_purchase, original_transaction_id: purchase.original_transaction_id)
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
  end

  describe 'credit packs' do
    it 'creates small credit pack' do
      purchase = create(:mobbie_purchase, :small_pack)
      expect(purchase.product_id).to eq('credit_pack_small')
      expect(purchase.credits_granted).to eq(100)
    end

    it 'creates medium credit pack' do
      purchase = create(:mobbie_purchase)
      expect(purchase.product_id).to eq('credit_pack_medium')
      expect(purchase.credits_granted).to eq(500)
    end

    it 'creates large credit pack' do
      purchase = create(:mobbie_purchase, :large_pack)
      expect(purchase.product_id).to eq('credit_pack_large')
      expect(purchase.credits_granted).to eq(1000)
    end

    it 'creates xl credit pack' do
      purchase = create(:mobbie_purchase, :xl_pack)
      expect(purchase.product_id).to eq('credit_pack_xl')
      expect(purchase.credits_granted).to eq(2500)
    end
  end

  describe 'platform tracking' do
    it 'tracks iOS purchases' do
      purchase = create(:mobbie_purchase, platform: 'ios')
      expect(purchase.platform).to eq('ios')
    end

    it 'tracks Android purchases' do
      purchase = create(:mobbie_purchase, :android)
      expect(purchase.platform).to eq('android')
    end

    it 'tracks admin granted credits' do
      purchase = create(:mobbie_purchase, :admin_granted)
      expect(purchase.platform).to eq('admin')
    end

    it 'tracks system granted credits' do
      purchase = create(:mobbie_purchase, :system_granted)
      expect(purchase.platform).to eq('system')
    end
  end

  describe 'user association' do
    it 'belongs to a user' do
      expect(purchase.user).to eq(user)
    end

    it 'is included in user purchases' do
      expect(user.purchases).to include(purchase)
    end
  end
end