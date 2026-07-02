# frozen_string_literal: true

require 'rails_helper'

describe Invoices::PeriodTasksQuery do
  subject { described_class.call(customer:, from:, to:) }

  let(:customer) { create(:customer) }
  let(:from)     { Date.new(2026, 6, 1) }
  let(:to)       { Date.new(2026, 6, 30) }

  context 'with billable tasks that have unbilled entries in the period' do
    let(:task_a) { create(:task, customer:, title: 'Design Work') }
    let(:task_b) { create(:task, customer:, title: 'Bug Fixes') }

    before do
      create(:time_entry, task: task_a, date: Date.new(2026, 6, 5), hours: 3.0)
      create(:time_entry, task: task_a, date: Date.new(2026, 6, 10), hours: 2.0)
      create(:time_entry, task: task_b, date: Date.new(2026, 6, 15), hours: 1.5)
    end

    it 'returns tasks with summed hours, ordered by title' do
      expect(subject.map(&:title)).to eq(['Bug Fixes', 'Design Work'])
      expect(subject.map(&:period_hours).map(&:to_d)).to eq([1.5, 5.0])
    end

    it 'sorts by hours descending' do
      result = described_class.call(customer:, from:, to:, sort: "hours_desc")

      expect(result.map(&:title)).to eq(['Design Work', 'Bug Fixes'])
    end

    it 'sorts by hours ascending' do
      result = described_class.call(customer:, from:, to:, sort: "hours_asc")

      expect(result.map(&:title)).to eq(['Bug Fixes', 'Design Work'])
    end

    it 'sorts by latest entry date descending' do
      result = described_class.call(customer:, from:, to:, sort: "date_desc")

      expect(result.map(&:title)).to eq(['Bug Fixes', 'Design Work'])
      expect(Date.parse(result.first.latest_date.to_s)).to eq(Date.new(2026, 6, 15))
    end

    it 'falls back to title asc for unknown sort values' do
      result = described_class.call(customer:, from:, to:, sort: "bogus")

      expect(result.map(&:title)).to eq(['Bug Fixes', 'Design Work'])
    end
  end

  context 'with entries outside the date range' do
    let(:task) { create(:task, customer:) }

    before { create(:time_entry, task:, date: Date.new(2026, 7, 1), hours: 4.0) }

    it 'excludes the task' do
      expect(subject).to be_empty
    end
  end

  context 'with entries already stamped on an invoice' do
    let(:task)    { create(:task, customer:) }
    let(:invoice) { create(:invoice, customer:) }

    before { create(:time_entry, task:, date: Date.new(2026, 6, 5), hours: 4.0, invoice:) }

    it 'excludes the task' do
      expect(subject).to be_empty
    end
  end

  context 'with a non-billable task' do
    let(:task) { create(:task, customer:, billable: false) }

    before { create(:time_entry, task:, date: Date.new(2026, 6, 5), hours: 4.0) }

    it 'excludes the task' do
      expect(subject).to be_empty
    end
  end

  context 'with a task from a different customer' do
    let(:other_customer) { create(:customer) }
    let(:task)           { create(:task, customer: other_customer) }

    before { create(:time_entry, task:, date: Date.new(2026, 6, 5), hours: 4.0) }

    it 'excludes the task' do
      expect(subject).to be_empty
    end
  end
end
