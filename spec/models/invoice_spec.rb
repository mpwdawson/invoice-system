# frozen_string_literal: true

require 'rails_helper'

describe Invoice do
  subject { build(:invoice) }

  describe 'associations' do
    it { is_expected.to belong_to(:customer).optional }
    it { is_expected.to have_many(:invoice_lines) }
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 'draft', ready: 'ready', sent: 'sent', paid: 'paid').backed_by_column_of_type(:string) }

    it 'defaults status to draft' do
      expect(described_class.new.status).to eq('draft')
    end
  end

  describe '#invoice_number' do
    it 'derives "PREFIX-0316" when the customer has an invoice_prefix' do
      customer = build_stubbed(:customer, invoice_prefix: 'ARGEN')
      invoice  = build_stubbed(:invoice, customer:, sequence_number: 316)

      expect(invoice.invoice_number).to eq('ARGEN-0316')
    end

    it 'derives "0316" when the customer has no invoice_prefix' do
      customer = build_stubbed(:customer, invoice_prefix: nil)
      invoice  = build_stubbed(:invoice, customer:, sequence_number: 316)

      expect(invoice.invoice_number).to eq('0316')
    end
  end

  describe '#hours_subtotal' do
    it 'returns total_hours * rate' do
      invoice = build_stubbed(:invoice, total_hours: 120, rate: 100.00)
      expect(invoice.hours_subtotal).to eq(BigDecimal("12000"))
    end

    it 'returns 0 when total_hours or rate is nil' do
      invoice = build_stubbed(:invoice, total_hours: nil, rate: nil)
      expect(invoice.hours_subtotal).to eq(0)
    end
  end

  describe '#period_label' do
    it 'formats the date range' do
      invoice = build_stubbed(:invoice, period_start: Date.new(2026, 6, 1), period_end: Date.new(2026, 6, 30))
      expect(invoice.period_label).to eq("June 1 to June 30, 2026")
    end

    it 'returns empty string when dates are nil' do
      invoice = build_stubbed(:invoice, period_start: nil, period_end: nil)
      expect(invoice.period_label).to eq("")
    end
  end

  describe '#invoice_date' do
    it 'uses period_end when present' do
      invoice = build_stubbed(:invoice, period_end: Date.new(2026, 6, 30))
      expect(invoice.invoice_date).to eq("June 30, 2026")
    end

    it 'falls back to created_at' do
      invoice = build_stubbed(:invoice, period_end: nil, created_at: Time.new(2026, 7, 1))
      expect(invoice.invoice_date).to eq("July 1, 2026")
    end
  end

  describe '.next_sequence_number' do
    it 'returns the seed value when no invoices exist' do
      expect(described_class.next_sequence_number).to eq(316)
    end

    it 'returns one more than the current highest sequence_number' do
      create(:invoice, sequence_number: 320)

      expect(described_class.next_sequence_number).to eq(321)
    end

    it 'assigns distinct sequence_numbers to successively created invoices' do
      first  = create(:invoice)
      second = create(:invoice)

      expect(second.sequence_number).to eq(first.sequence_number + 1)
    end
  end

  describe 'rate auto-population' do
    let(:customer) { create(:customer) }

    it 'stamps the rate effective for the period start when saved' do
      create(:customer_rate, customer:, rate: 95.00, effective_from: Date.new(2026, 1, 1))

      invoice = create(:invoice, customer:, period_start: Date.new(2026, 5, 1))

      expect(invoice.rate).to eq(95.00)
    end

    it 'leaves the rate blank when no CustomerRate is effective yet' do
      invoice = create(:invoice, customer:, period_start: Date.new(2020, 1, 1))

      expect(invoice.rate).to be_nil
    end

    it 'leaves the rate blank without a period_start' do
      invoice = create(:invoice, customer:)

      expect(invoice.rate).to be_nil
    end

    it 'recomputes the rate when the period start changes' do
      create(:customer_rate, customer:, rate: 80.00, effective_from: Date.new(2026, 1, 1))
      create(:customer_rate, customer:, rate: 100.00, effective_from: Date.new(2026, 6, 1))
      invoice = create(:invoice, customer:, period_start: Date.new(2026, 3, 1))

      invoice.update!(period_start: Date.new(2026, 7, 1))

      expect(invoice.rate).to eq(100.00)
    end

    it 'recomputes the rate when the customer changes' do
      create(:customer_rate, customer:, rate: 80.00, effective_from: Date.new(2026, 1, 1))
      other_customer = create(:customer)
      create(:customer_rate, customer: other_customer, rate: 120.00, effective_from: Date.new(2026, 1, 1))
      invoice = create(:invoice, customer:, period_start: Date.new(2026, 3, 1))

      invoice.update!(customer: other_customer)

      expect(invoice.rate).to eq(120.00)
    end
  end

  describe 'status transitions' do
    it 'allows draft to ready' do
      invoice = create(:invoice, status: 'draft')

      expect(invoice.update(status: 'ready')).to be(true)
    end

    it 'allows ready to sent' do
      invoice = create(:invoice, status: 'ready')

      expect(invoice.update(status: 'sent')).to be(true)
    end

    it 'allows sent to paid' do
      invoice = create(:invoice, status: 'sent')

      expect(invoice.update(status: 'paid')).to be(true)
    end

    it 'rejects draft to sent' do
      invoice = create(:invoice, status: 'draft')

      expect(invoice.update(status: 'sent')).to be(false)
      expect(invoice.errors[:status]).to be_present
    end

    it 'rejects ready to paid' do
      invoice = create(:invoice, status: 'ready')

      expect(invoice.update(status: 'paid')).to be(false)
      expect(invoice.errors[:status]).to be_present
    end

    it 'rejects backwards transitions' do
      invoice = create(:invoice, status: 'ready')

      expect(invoice.update(status: 'draft')).to be(false)
      expect(invoice.errors[:status]).to be_present
    end
  end
end
