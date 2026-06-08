# frozen_string_literal: true

require 'rails_helper'

describe Invoices::UnbilledEntriesQuery do
  subject { described_class.call(customer:, from:, to:) }

  let(:customer) { create(:customer) }
  let(:from)     { Date.new(2026, 5, 1) }
  let(:to)       { Date.new(2026, 5, 31) }

  context 'with billable, un-billed entries in range' do
    let(:task)    { create(:task, customer:, title: 'Rewards Dashboard') }
    let!(:first)  { create(:time_entry, task:, date: Date.new(2026, 5, 5), hours: 3.0) }
    let!(:second) { create(:time_entry, task:, date: Date.new(2026, 5, 12), hours: 2.5) }

    it 'groups entries by task with summed hours' do
      expect(subject.task_groups.map(&:task)).to contain_exactly(task)
      expect(subject.task_groups.first.hours).to eq(5.5)
    end

    it 'sums all groups into total_hours' do
      expect(subject.total_hours).to eq(5.5)
    end
  end

  context 'with a non-billable task' do
    let(:task) { create(:task, customer:, billable: false) }

    before { create(:time_entry, task:, date: Date.new(2026, 5, 5), hours: 4.0) }

    it 'excludes it from task_groups' do
      expect(subject.task_groups).to be_empty
    end
  end

  context 'with an entry already stamped onto an invoice' do
    let(:task)    { create(:task, customer:) }
    let(:invoice) { create(:invoice, customer:) }

    before { create(:time_entry, task:, date: Date.new(2026, 5, 5), hours: 4.0, invoice:) }

    it 'excludes it from task_groups' do
      expect(subject.task_groups).to be_empty
    end
  end

  context 'with an entry outside the date range' do
    let(:task) { create(:task, customer:) }

    before { create(:time_entry, task:, date: Date.new(2026, 6, 1), hours: 4.0) }

    it 'excludes it from task_groups' do
      expect(subject.task_groups).to be_empty
    end
  end

  context 'with an entry for a different customer' do
    let(:other_task) { create(:task, customer: create(:customer)) }

    before { create(:time_entry, task: other_task, date: Date.new(2026, 5, 5), hours: 4.0) }

    it 'excludes it from task_groups' do
      expect(subject.task_groups).to be_empty
    end
  end

  describe 'already_billed_count' do
    let(:task) { create(:task, customer:) }

    context 'when an entry in range is on an invoice that has been sent' do
      let(:sent_invoice) { create(:invoice, customer:, status: 'sent', sent_at: Time.current) }

      before { create(:time_entry, task:, date: Date.new(2026, 5, 8), hours: 2.0, invoice: sent_invoice) }

      it 'counts it' do
        expect(subject.already_billed_count).to eq(1)
      end
    end

    context 'when an entry in range is on a draft invoice (not yet sent)' do
      let(:draft_invoice) { create(:invoice, customer:, status: 'draft') }

      before { create(:time_entry, task:, date: Date.new(2026, 5, 8), hours: 2.0, invoice: draft_invoice) }

      it 'does not count it' do
        expect(subject.already_billed_count).to eq(0)
      end
    end

    context 'when there are no entries already on a sent invoice' do
      before { create(:time_entry, task:, date: Date.new(2026, 5, 8), hours: 2.0) }

      it 'is zero' do
        expect(subject.already_billed_count).to eq(0)
      end
    end
  end
end
