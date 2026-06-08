# frozen_string_literal: true

require 'rails_helper'

describe Invoices::FinalizeService do
  subject { described_class.call(invoice:) }

  let(:customer) { create(:customer) }
  let!(:customer_rate) { create(:customer_rate, customer:, rate: 100.00, effective_from: Date.new(2026, 1, 1)) }
  let(:invoice) do
    create(:invoice, customer:, status: 'draft',
                     period_start: Date.new(2026, 5, 1), period_end: Date.new(2026, 5, 31))
  end

  context 'with billable un-billed entries in range' do
    let(:task)   { create(:task, customer:) }
    let!(:entry) { create(:time_entry, task:, date: Date.new(2026, 5, 10), hours: 4.0) }

    it 'succeeds and snapshots total_hours and total_amount onto the invoice' do
      expect(subject.success?).to be(true)

      reloaded = invoice.reload
      expect(reloaded.total_hours).to eq(4.0)
      expect(reloaded.total_amount).to eq(400.00)
    end

    it 'stamps the entry with the invoice id' do
      subject
      expect(entry.reload.invoice_id).to eq(invoice.id)
    end

    it 'transitions status to ready and sets wizard_current_step to 6' do
      subject
      reloaded = invoice.reload
      expect(reloaded.status).to eq('ready')
      expect(reloaded.wizard_current_step).to eq(6)
    end
  end

  context 'with entries outside the billable un-billed scope' do
    let(:task)                { create(:task, customer:) }
    let(:other_customer_task) { create(:task, customer: create(:customer)) }
    let(:non_billable_task)   { create(:task, customer:, billable: false) }
    let(:sent_invoice)        { create(:invoice, customer:, status: 'sent', sent_at: Time.current) }

    let!(:out_of_range)   { create(:time_entry, task:, date: Date.new(2026, 6, 1), hours: 2.0) }
    let!(:other_customer) { create(:time_entry, task: other_customer_task, date: Date.new(2026, 5, 10), hours: 2.0) }
    let!(:non_billable)   { create(:time_entry, task: non_billable_task, date: Date.new(2026, 5, 10), hours: 2.0) }
    let!(:already_billed) do
      create(:time_entry, task:, date: Date.new(2026, 5, 12), hours: 2.0, invoice: sent_invoice)
    end

    it 'excludes them from the snapshot and leaves them unstamped' do
      subject

      expect(invoice.reload.total_hours).to eq(0)
      expect(out_of_range.reload.invoice_id).to be_nil
      expect(other_customer.reload.invoice_id).to be_nil
      expect(non_billable.reload.invoice_id).to be_nil
      expect(already_billed.reload.invoice_id).to eq(sent_invoice.id)
    end
  end

  context 'when the customer requires project codes and a billable task lacks one' do
    let(:customer) { create(:customer, requires_project_codes: true) }
    let(:task)     { create(:task, customer:, project_code: nil) }
    let!(:entry)   { create(:time_entry, task:, date: Date.new(2026, 5, 10), hours: 4.0) }

    it 'fails with a clear error and leaves the invoice and entries unchanged' do
      expect(subject.success?).to be(false)
      expect(subject.errors).to be_present

      expect(invoice.reload.status).to eq('draft')
      expect(entry.reload.invoice_id).to be_nil
    end
  end

  context 'when the customer does not require project codes and tasks are unassigned' do
    let(:task)   { create(:task, customer:, project_code: nil) }
    let!(:entry) { create(:time_entry, task:, date: Date.new(2026, 5, 10), hours: 4.0) }

    it 'succeeds and stamps the entry' do
      expect(subject.success?).to be(true)
      expect(entry.reload.invoice_id).to eq(invoice.id)
    end
  end
end
