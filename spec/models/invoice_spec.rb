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
