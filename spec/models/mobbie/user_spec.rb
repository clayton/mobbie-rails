require 'rails_helper'

RSpec.describe Mobbie::User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:support_tickets).class_name('Mobbie::SupportTicket').dependent(:destroy) }
    it { is_expected.to have_many(:purchases).class_name('Mobbie::Purchase').dependent(:destroy) }
    it { is_expected.to have_many(:subscriptions).class_name('Mobbie::Subscription').dependent(:destroy) }
  end

  describe 'validations' do
    context 'for anonymous users' do
      subject { build(:mobbie_user, :anonymous) }
      
      it { is_expected.to validate_presence_of(:device_id) }
      it { is_expected.to validate_uniqueness_of(:device_id) }
    end

    context 'for registered users' do
      subject { build(:mobbie_user) }
      
      it { is_expected.to allow_value('user@example.com').for(:email) }
      it { is_expected.not_to allow_value('invalid').for(:email) }
      it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    end

    context 'for OAuth users' do
      let(:user) { create(:mobbie_user, :apple_linked) }
      let(:duplicate) { build(:mobbie_user, oauth_provider: user.oauth_provider, oauth_uid: user.oauth_uid) }
      
      it 'validates uniqueness of oauth_uid scoped to provider' do
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:oauth_uid]).to include('has already been taken')
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'normalizes email' do
        user = build(:mobbie_user, email: '  USER@EXAMPLE.COM  ')
        user.valid?
        expect(user.email).to eq('user@example.com')
      end
    end

    describe 'before_create' do
      it 'sets username from email' do
        user = create(:mobbie_user, email: 'john.doe@example.com', username: nil)
        expect(user.username).to eq('john.doe')
      end

      it 'sets username from device_id for anonymous users' do
        user = create(:mobbie_user, :anonymous, device_id: 'device123456789')
        expect(user.username).to start_with('user_device12')
      end

      it 'generates unique username on conflict' do
        existing = create(:mobbie_user, username: 'john.doe')
        user = create(:mobbie_user, email: 'john.doe@another.com', username: nil)
        expect(user.username).to eq('john.doe1')
      end
    end
  end

  describe '#anonymous?' do
    it 'returns true for anonymous users' do
      user = build(:mobbie_user, :anonymous)
      expect(user.anonymous?).to be true
    end

    it 'returns false for registered users' do
      user = build(:mobbie_user)
      expect(user.registered?).to be true
      expect(user.anonymous?).to be false
    end
  end

  describe '#link_apple_account!' do
    let(:user) { create(:mobbie_user, :anonymous) }
    
    it 'links Apple account successfully' do
      user.link_apple_account!(
        apple_user_id: 'apple123',
        email: 'apple@example.com',
        name: 'Apple User'
      )
      
      expect(user.reload).to have_attributes(
        oauth_provider: 'apple',
        oauth_uid: 'apple123',
        email: 'apple@example.com',
        name: 'Apple User',
        is_anonymous: false
      )
    end
  end

  describe '#display_name' do
    it 'returns name if present' do
      user = build(:mobbie_user, name: 'John Doe')
      expect(user.display_name).to eq('John Doe')
    end

    it 'returns username if name not present' do
      user = build(:mobbie_user, name: nil, username: 'johndoe')
      expect(user.display_name).to eq('johndoe')
    end

    it 'returns email if name and username not present' do
      user = build(:mobbie_user, name: nil, username: nil, email: 'john@example.com')
      expect(user.display_name).to eq('john@example.com')
    end

    it 'returns User ID if nothing else present' do
      user = create(:mobbie_user, name: nil, username: nil, email: nil)
      expect(user.display_name).to eq("User #{user.id}")
    end
  end

  describe 'subscription methods' do
    let(:user) { create(:mobbie_user) }
    
    describe '#active_subscription' do
      context 'with active subscription' do
        let!(:subscription) { create(:mobbie_subscription, :active, user: user) }
        
        it 'returns the active subscription' do
          expect(user.active_subscription).to eq(subscription)
        end
      end

      context 'with multiple subscriptions' do
        let!(:old_sub) { create(:mobbie_subscription, :active, user: user, expires_at: 1.week.from_now) }
        let!(:new_sub) { create(:mobbie_subscription, :active, user: user, expires_at: 1.month.from_now) }
        
        it 'returns the one expiring latest' do
          expect(user.active_subscription).to eq(new_sub)
        end
      end

      context 'without active subscription' do
        it 'returns nil' do
          expect(user.active_subscription).to be_nil
        end
      end
    end

    describe '#has_active_subscription?' do
      it 'returns true when active subscription exists' do
        create(:mobbie_subscription, :active, user: user)
        expect(user.has_active_subscription?).to be true
      end

      it 'returns false when no active subscription' do
        expect(user.has_active_subscription?).to be false
      end
    end

    describe '#subscription_tier' do
      it 'returns premium for active premium subscription' do
        create(:mobbie_subscription, :active, tier: 'premium', user: user)
        expect(user.subscription_tier).to eq('premium')
      end

      it 'returns free when no active subscription' do
        expect(user.subscription_tier).to eq('free')
      end
    end

    describe '#premium?' do
      it 'returns true for premium users' do
        create(:mobbie_subscription, :active, tier: 'premium', user: user)
        expect(user.premium?).to be true
      end

      it 'returns false for free users' do
        expect(user.premium?).to be false
      end
    end
  end

  describe 'credit methods' do
    let(:user) { create(:mobbie_user, credit_balance: 100) }
    
    describe '#add_credits' do
      it 'adds credits to balance' do
        user.add_credits(50)
        expect(user.reload.credit_balance).to eq(150)
      end

      it 'accepts source parameter' do
        expect { user.add_credits(25, source: 'purchase:123') }
          .to change { user.credit_balance }.by(25)
      end
    end

    describe '#spend_credits' do
      context 'with sufficient credits' do
        it 'deducts credits and returns true' do
          result = user.spend_credits(30)
          expect(result).to be true
          expect(user.reload.credit_balance).to eq(70)
        end
      end

      context 'with insufficient credits' do
        it 'does not deduct credits and returns false' do
          result = user.spend_credits(150)
          expect(result).to be false
          expect(user.reload.credit_balance).to eq(100)
        end
      end

      it 'accepts reason parameter' do
        expect(user.spend_credits(20, reason: 'stamp_analysis')).to be true
      end
    end

    describe '#has_credits?' do
      it 'returns true when has enough credits' do
        expect(user.has_credits?(50)).to be true
      end

      it 'returns false when not enough credits' do
        expect(user.has_credits?(150)).to be false
      end

      it 'defaults to checking for 1 credit' do
        user.update!(credit_balance: 0)
        expect(user.has_credits?).to be false
        
        user.update!(credit_balance: 1)
        expect(user.has_credits?).to be true
      end
    end
  end

  describe '#as_json' do
    let(:user) { create(:mobbie_user) }
    
    it 'includes only allowed attributes' do
      json = user.as_json
      expect(json.keys).to match_array(%w[
        id email username device_id created_at 
        is_anonymous oauth_provider oauth_uid name permissions
      ])
    end

    it 'includes permissions method' do
      json = user.as_json
      expect(json['permissions']).to eq([])
    end
  end
end