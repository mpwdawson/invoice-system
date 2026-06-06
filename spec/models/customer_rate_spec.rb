# frozen_string_literal: true

require 'rails_helper'

describe CustomerRate do
  subject { build(:customer_rate) }

  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:rate) }
    it { is_expected.to validate_presence_of(:effective_from) }
    it { is_expected.to validate_numericality_of(:rate).is_greater_than(0) }
  end

  describe '.current_for' do
    let(:customer) { create(:customer) }

    context 'when no rates exist' do
      it 'returns nil' do
        expect(described_class.current_for(customer, Time.zone.today)).to be_nil
      end
    end

    context 'when rates exist' do
      let!(:old_rate)     { create(:customer_rate, customer: customer, effective_from: Date.new(2025, 1, 1), rate: 100) }
      let!(:recent_rate)  { create(:customer_rate, customer: customer, effective_from: Date.new(2026, 1, 1), rate: 150) }
      let!(:future_rate)  { create(:customer_rate, customer: customer, effective_from: Date.new(2027, 1, 1), rate: 200) }

      it 'returns the most recent rate on or before the given date' do
        result = described_class.current_for(customer, Date.new(2026, 6, 1))
        expect(result.rate).to eq(150)
      end

      it 'matches on the exact boundary date' do
        result = described_class.current_for(customer, Date.new(2026, 1, 1))
        expect(result.rate).to eq(150)
      end

      it 'returns nil when all rates are after the given date' do
        expect(described_class.current_for(customer, Date.new(2024, 12, 31))).to be_nil
      end

      it 'ignores rates with a future effective_from' do
        result = described_class.current_for(customer, Date.new(2026, 6, 1))
        expect(result.rate).not_to eq(200)
      end
    end
  end
end
