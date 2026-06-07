# frozen_string_literal: true

require 'rails_helper'

describe Reports::DailyLogQuery do
  subject { described_class.call(customer:, from:, to:) }

  let(:customer) { create(:customer) }
  let(:from)     { Date.current.beginning_of_month }
  let(:to)       { Date.current.end_of_month }

  context 'with no entries' do
    it 'returns no days and zero total' do
      expect(subject.days).to be_empty
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with entries on multiple dates' do
    let(:task) { create(:task, customer:) }
    let!(:earlier) { create(:time_entry, task:, date: from, hours: 2.0) }
    let!(:later)   { create(:time_entry, task:, date: from + 1, hours: 1.5) }

    it 'groups entries by date in date order' do
      expect(subject.days.map(&:date)).to eq([earlier.date, later.date])
    end

    it 'sums hours per day' do
      expect(subject.days.first.hours).to eq(2.0)
    end

    it 'sums total_hours across all days' do
      expect(subject.total_hours).to eq(3.5)
    end
  end

  context 'with a billed and an unbilled entry' do
    let!(:billed)   { create(:time_entry, task: create(:task, customer:), date: from, invoice_id: 99) }
    let!(:unbilled) { create(:time_entry, task: create(:task, customer:), date: from) }

    it 'flags each entry billed status' do
      flags = subject.days.first.time_entries.to_h { |entry| [entry.task, entry.billed] }
      expect(flags[billed.task]).to be(true)
      expect(flags[unbilled.task]).to be(false)
    end
  end

  context 'with an entry outside the date range' do
    let!(:entry) { create(:time_entry, task: create(:task, customer:), date: from - 1, hours: 2.0) }

    it 'excludes it' do
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with an entry for a different customer' do
    let!(:entry) { create(:time_entry, task: create(:task, customer: create(:customer)), date: from, hours: 2.0) }

    it 'excludes it' do
      expect(subject.total_hours).to eq(0)
    end
  end
end
