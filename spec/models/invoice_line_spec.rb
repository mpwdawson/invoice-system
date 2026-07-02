# frozen_string_literal: true

require 'rails_helper'

describe InvoiceLine do
  subject { build(:invoice_line) }

  describe 'associations' do
    it { is_expected.to belong_to(:invoice) }
    it { is_expected.to belong_to(:task).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_inclusion_of(:line_type).in_array(%w[task expense]) }

    it { is_expected.to validate_numericality_of(:quantity).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0).allow_nil }

    context 'when line_type is expense' do
      subject { build(:invoice_line, :expense) }

      it { is_expected.to validate_presence_of(:quantity) }
      it { is_expected.to validate_presence_of(:unit_price) }
    end

    context 'when line_type is task' do
      subject { build(:invoice_line, line_type: "task") }

      it { is_expected.not_to validate_presence_of(:quantity) }
      it { is_expected.not_to validate_presence_of(:unit_price) }
    end
  end

  describe 'scopes' do
    let(:invoice) { create(:invoice) }
    let!(:task_line) { create(:invoice_line, invoice:, line_type: "task") }
    let!(:expense_line) { create(:invoice_line, :expense, invoice:, description: "Internet") }

    it 'filters task lines' do
      expect(described_class.tasks).to contain_exactly(task_line)
    end

    it 'filters expense lines' do
      expect(described_class.expenses).to contain_exactly(expense_line)
    end
  end

  describe '#expense?' do
    it 'returns true for expense lines' do
      expect(build(:invoice_line, :expense)).to be_expense
    end

    it 'returns false for task lines' do
      expect(build(:invoice_line, line_type: "task")).not_to be_expense
    end
  end

  describe '#display_quantity' do
    it 'returns quantity when positive' do
      line = build(:invoice_line, quantity: 4.0)
      expect(line.display_quantity).to eq(4.0)
    end

    it 'returns nil when quantity is zero' do
      line = build(:invoice_line, quantity: 0)
      expect(line.display_quantity).to be_nil
    end

    it 'returns nil when quantity is nil' do
      line = build(:invoice_line, quantity: nil)
      expect(line.display_quantity).to be_nil
    end
  end

  describe '#line_total' do
    it 'returns quantity * unit_price' do
      line = build(:invoice_line, :expense, quantity: 2, unit_price: 25.00)
      expect(line.line_total).to eq(BigDecimal("50"))
    end

    it 'returns 0 when fields are nil' do
      line = build(:invoice_line)
      expect(line.line_total).to eq(0)
    end
  end
end
