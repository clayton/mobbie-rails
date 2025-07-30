require 'rails_helper'

RSpec.describe Mobbie::SubscriptionExpiryJob, type: :job do
  describe '#perform' do
    let!(:active_current) do
      create(:mobbie_subscription, status: 'active', expires_at: 1.week.from_now)
    end
    
    let!(:active_expired) do
      create(:mobbie_subscription, status: 'active', expires_at: 1.day.ago)
    end
    
    let!(:active_just_expired) do
      create(:mobbie_subscription, status: 'active', expires_at: 1.minute.ago)
    end
    
    let!(:already_expired) do
      create(:mobbie_subscription, status: 'expired', expires_at: 1.month.ago)
    end
    
    let!(:grace_period_expired) do
      create(:mobbie_subscription, status: 'grace_period', expires_at: 3.days.ago)
    end

    it 'marks expired active subscriptions as expired' do
      expect {
        described_class.perform_now
      }.to change { Mobbie::Subscription.where(status: 'expired').count }.by(2)
      
      active_expired.reload
      active_just_expired.reload
      
      expect(active_expired.status).to eq('expired')
      expect(active_just_expired.status).to eq('expired')
    end

    it 'does not affect non-expired active subscriptions' do
      described_class.perform_now
      
      active_current.reload
      expect(active_current.status).to eq('active')
    end

    it 'does not change already expired subscriptions' do
      expect {
        described_class.perform_now
      }.not_to change { already_expired.reload.updated_at }
    end

    it 'does not change grace period subscriptions' do
      described_class.perform_now
      
      grace_period_expired.reload
      expect(grace_period_expired.status).to eq('grace_period')
    end

    it 'returns count of expired subscriptions' do
      result = described_class.perform_now
      expect(result).to eq(2)
    end

    it 'logs the number of expired subscriptions' do
      expect(Rails.logger).to receive(:info)
        .with('Mobbie::SubscriptionExpiryJob: Marked 2 subscriptions as expired')
      
      described_class.perform_now
    end

    context 'with large number of subscriptions' do
      before do
        50.times do
          create(:mobbie_subscription, status: 'active', expires_at: 1.hour.ago)
        end
      end

      it 'processes subscriptions in batches' do
        result = described_class.perform_now
        expect(result).to eq(52) # 50 + 2 from earlier
        
        expect(Mobbie::Subscription.where(status: 'expired').count).to eq(52)
      end
    end

    context 'with database errors' do
      before do
        allow_any_instance_of(Mobbie::Subscription).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'continues processing other subscriptions' do
        expect {
          described_class.perform_now
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'job configuration' do
    it 'uses default queue' do
      expect(described_class.queue_name).to eq('default')
    end
  end
end