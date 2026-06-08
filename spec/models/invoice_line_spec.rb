# frozen_string_literal: true

require 'rails_helper'

describe InvoiceLine do
  subject { build(:invoice_line) }

  describe 'associations' do
    it { is_expected.to belong_to(:invoice) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
  end

  describe '#normalize_task_ids' do
    it 'casts string ids to integers' do
      line = build(:invoice_line, task_ids: %w[3 7])

      line.valid?

      expect(line.task_ids).to eq([3, 7])
    end

    it 'drops blank and zero entries' do
      line = build(:invoice_line, task_ids: ['3', '', '0', nil])

      line.valid?

      expect(line.task_ids).to eq([3])
    end

    it 'leaves a blank task_ids alone' do
      line = build(:invoice_line, task_ids: nil)

      line.valid?

      expect(line.task_ids).to be_nil
    end
  end
end
