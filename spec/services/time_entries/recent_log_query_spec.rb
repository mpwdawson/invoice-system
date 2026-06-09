# frozen_string_literal: true

require 'rails_helper'

describe TimeEntries::RecentLogQuery do
  subject { described_class.call(days: 14) }

  it 'returns 14 groups' do
    expect(subject.size).to eq 14
  end

  it 'orders groups descending (today first)' do
    expect(subject.map(&:date)).to eq(((Date.current - 13)..Date.current).to_a.reverse)
  end

  context 'with no entries' do
    it 'returns all empty groups' do
      expect(subject).to all(satisfy { |g| g.items.empty? && g.total_hours == 0 })
    end
  end

  context 'with entries in range' do
    let!(:task)  { create(:task) }
    let!(:entry) { create(:time_entry, task:, date: Date.current, hours: 2.5) }

    it 'places the entry in today\'s group' do
      expect(subject.first.items).to include(entry)
    end

    it 'sums total_hours for the group' do
      expect(subject.first.total_hours).to eq(2.5)
    end
  end

  context 'with an entry outside the 14-day window' do
    let!(:task) { create(:task) }
    let!(:old)  { create(:time_entry, task:, date: 20.days.ago, hours: 1) }

    it 'excludes the entry' do
      expect(subject.flat_map(&:items)).not_to include(old)
    end
  end

  context 'when customer_id is given' do
    subject { described_class.call(days: 14, customer_id: customer_a.id) }

    let!(:customer_a) { create(:customer) }
    let!(:customer_b) { create(:customer) }
    let!(:task_a)     { create(:task, customer: customer_a) }
    let!(:task_b)     { create(:task, customer: customer_b) }
    let!(:entry_a)    { create(:time_entry, task: task_a, date: Date.current, hours: 1) }
    let!(:entry_b)    { create(:time_entry, task: task_b, date: Date.current, hours: 2) }

    it 'returns only entries belonging to the given customer' do
      expect(subject.flat_map(&:items)).to include(entry_a)
    end

    it 'excludes entries from other customers' do
      expect(subject.flat_map(&:items)).not_to include(entry_b)
    end
  end
end
