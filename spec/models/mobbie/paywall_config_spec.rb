require 'rails_helper'

RSpec.describe Mobbie::PaywallConfig, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:paywall_offerings).class_name('Mobbie::PaywallOffering').dependent(:destroy) }
    it { is_expected.to have_many(:paywall_features).class_name('Mobbie::PaywallFeature').dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:subtitle) }
    it { is_expected.to validate_presence_of(:welcome_title) }
    it { is_expected.to validate_presence_of(:welcome_subtitle) }
    it { is_expected.to validate_presence_of(:skip_button_text) }
    
    context 'active uniqueness' do
      let!(:active_config) { create(:mobbie_paywall_config, :active) }
      let(:another_active) { build(:mobbie_paywall_config, :active) }
      
      it 'allows only one active config' do
        expect(another_active).not_to be_valid
        expect(another_active.errors[:active]).to include('Only one config can be active at a time')
      end
      
      it 'allows multiple inactive configs' do
        inactive1 = create(:mobbie_paywall_config, active: false)
        inactive2 = build(:mobbie_paywall_config, active: false)
        expect(inactive2).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:active_config) { create(:mobbie_paywall_config, :active) }
    let!(:inactive_config) { create(:mobbie_paywall_config, active: false) }
    
    describe '.active' do
      it 'returns only active configs' do
        expect(described_class.active).to contain_exactly(active_config)
      end
    end
    
    describe '.ordered' do
      let!(:config1) { create(:mobbie_paywall_config, display_order: 2) }
      let!(:config2) { create(:mobbie_paywall_config, display_order: 1) }
      
      it 'orders by display_order then created_at' do
        results = described_class.ordered
        expect(results.first).to eq(config2)
        expect(results.second).to eq(config1)
      end
    end
  end

  describe '.current' do
    context 'with active config' do
      let!(:config) { create(:mobbie_paywall_config, :active) }
      
      it 'returns the active config' do
        expect(described_class.current).to eq(config)
      end
    end
    
    context 'without active config' do
      it 'returns nil' do
        expect(described_class.current).to be_nil
      end
    end
  end

  describe '#activate!' do
    let!(:old_active) { create(:mobbie_paywall_config, :active) }
    let(:new_config) { create(:mobbie_paywall_config, active: false) }
    
    it 'activates the config' do
      new_config.activate!
      expect(new_config.reload.active).to be true
    end
    
    it 'deactivates other configs' do
      new_config.activate!
      expect(old_active.reload.active).to be false
    end
    
    it 'uses a transaction' do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      new_config.activate!
    end
  end

  describe '#visible_offerings' do
    let(:config) { create(:mobbie_paywall_config) }
    let!(:visible1) { create(:mobbie_paywall_offering, paywall_config: config, is_visible: true, display_order: 2) }
    let!(:visible2) { create(:mobbie_paywall_offering, paywall_config: config, is_visible: true, display_order: 1) }
    let!(:hidden) { create(:mobbie_paywall_offering, paywall_config: config, is_visible: false) }
    
    it 'returns only visible offerings ordered by display_order' do
      results = config.visible_offerings
      expect(results).to eq([visible2, visible1])
    end
  end

  describe '#visible_features' do
    let(:config) { create(:mobbie_paywall_config) }
    let!(:visible1) { create(:mobbie_paywall_feature, paywall_config: config, is_visible: true, display_order: 2) }
    let!(:visible2) { create(:mobbie_paywall_feature, paywall_config: config, is_visible: true, display_order: 1) }
    let!(:hidden) { create(:mobbie_paywall_feature, paywall_config: config, is_visible: false) }
    
    it 'returns only visible features ordered by display_order' do
      results = config.visible_features
      expect(results).to eq([visible2, visible1])
    end
  end

  describe '#onboarding_offerings' do
    let(:config) { create(:mobbie_paywall_config) }
    let!(:onboarding) { create(:mobbie_paywall_offering, paywall_config: config, is_visible_for_onboarding: true) }
    let!(:not_onboarding) { create(:mobbie_paywall_offering, paywall_config: config, is_visible_for_onboarding: false) }
    
    it 'returns only onboarding visible offerings' do
      expect(config.onboarding_offerings).to contain_exactly(onboarding)
    end
  end

  describe '#to_api_json' do
    let(:config) { create(:mobbie_paywall_config, :complete) }
    
    it 'returns formatted JSON structure' do
      json = config.to_api_json
      
      expect(json).to include(
        :offerings,
        :features,
        :display_settings
      )
      
      expect(json[:display_settings]).to include(
        title: config.title,
        subtitle: config.subtitle,
        welcome_title: config.welcome_title,
        welcome_subtitle: config.welcome_subtitle,
        show_skip_button: config.show_skip_button,
        skip_button_text: config.skip_button_text
      )
      
      expect(json[:offerings]).to be_an(Array)
      expect(json[:features]).to be_an(Array)
    end
    
    it 'includes only visible items' do
      hidden_offering = create(:mobbie_paywall_offering, :hidden, paywall_config: config)
      hidden_feature = create(:mobbie_paywall_feature, :hidden, paywall_config: config)
      
      json = config.to_api_json
      
      offering_ids = json[:offerings].map { |o| o[:product_id] }
      feature_titles = json[:features].map { |f| f[:title] }
      
      expect(offering_ids).not_to include(hidden_offering.product_id)
      expect(feature_titles).not_to include(hidden_feature.title)
    end
  end
end