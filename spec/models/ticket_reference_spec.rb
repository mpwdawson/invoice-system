# frozen_string_literal: true

require 'rails_helper'

describe TicketReference do
  subject { build(:ticket_reference) }

  describe 'associations' do
    it { is_expected.to belong_to(:task) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:prefix) }
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_uniqueness_of(:number).scoped_to(:task_id, :prefix) }
  end

  describe '#to_s' do
    let(:ref) { build(:ticket_reference, prefix: 'AW', number: 6770) }

    it 'returns prefix-number format' do
      expect(ref.to_s).to eq('AW-6770')
    end
  end
end
