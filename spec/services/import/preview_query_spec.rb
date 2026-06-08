# frozen_string_literal: true

require 'rails_helper'

describe Import::PreviewQuery do
  subject { described_class.call(customer:, text:) }

  let(:customer) { create(:customer) }
  let(:date_str) { '6/1/2026' }
  let(:notes)    { '' }
  let(:text)     { "#{date_str}\t11\t#{notes}" }

  context 'when an item matches an existing task by ticket ref' do
    let!(:task)             { create(:task, customer:, title: 'Old Title') }
    let!(:ticket_reference) { create(:ticket_reference, task:, prefix: 'AW', number: 6522) }
    let(:notes)             { 'AW-6522 New Description (5)' }

    it 'matches the existing task regardless of title drift' do
      expect(subject.days.first.rows.first.matched_task).to eq(task)
    end

    it 'proposes no new task' do
      expect(subject.new_tasks).to be_empty
    end
  end

  context 'when an item matches an existing task by title (no ticket ref)' do
    let!(:task) { create(:task, customer:, title: 'QA Support') }
    let(:notes) { 'qa support (0.5)' }

    it 'matches case-insensitively' do
      expect(subject.days.first.rows.first.matched_task).to eq(task)
    end
  end

  context 'when ticket refs are present but unmatched, even if the title matches an existing task' do
    let!(:task) { create(:task, customer:, title: 'QA Support') }
    let(:notes) { 'AW-9999 QA Support (1)' }

    it 'proposes a new task rather than falling back to a title match' do
      expect(subject.days.first.rows.first.matched_task).to be_nil
    end
  end

  context 'when a matching title belongs to a different customer' do
    let!(:other_customer_task) { create(:task, title: 'QA Support') }
    let(:notes)                { 'QA Support (0.5)' }

    it 'does not match across customers' do
      expect(subject.days.first.rows.first.matched_task).to be_nil
    end
  end

  context 'when no existing task matches' do
    let(:notes) { 'Brand New Work Item (2)' }

    it 'proposes a new task with the parsed title' do
      expect(subject.days.first.rows.first.matched_task).to be_nil
      expect(subject.new_tasks.map(&:title)).to eq(['Brand New Work Item'])
    end

    it 'links the row to the new task by key' do
      row = subject.days.first.rows.first
      expect(row.new_task_key).to eq(subject.new_tasks.first.key)
    end
  end

  context 'when the same untracked title appears across multiple days' do
    let(:text) do
      [
        "6/1/2026\t8\tQA Support (0.5)",
        "6/2/2026\t8\tQA Support (1)"
      ].join("\n")
    end

    it 'collapses them into a single new-task proposal' do
      expect(subject.new_tasks.size).to eq(1)
    end

    it 'links both rows to the same new-task key' do
      keys = subject.days.flat_map { |day| day.rows.map(&:new_task_key) }
      expect(keys.uniq.size).to eq(1)
    end
  end

  context 'when the same untracked ticket ref appears across multiple days' do
    let(:text) do
      [
        "6/1/2026\t8\tAW-9001 New Feature (1)",
        "6/2/2026\t8\tAW-9001 New Feature (1.5)"
      ].join("\n")
    end

    it 'collapses them into a single new-task proposal keyed by the ticket ref' do
      expect(subject.new_tasks.size).to eq(1)
      expect(subject.new_tasks.first.key).to eq('AW-9001')
    end
  end

  context 'when a TimeEntry already exists for the matched task and date' do
    let!(:task)       { create(:task, customer:, title: 'QA Support') }
    let!(:time_entry) { create(:time_entry, task:, date: Date.new(2026, 6, 1)) }
    let(:notes)       { 'QA Support (0.5)' }

    it 'flags the row as a duplicate' do
      expect(subject.days.first.rows.first.duplicate).to be(true)
    end
  end

  context 'when no existing TimeEntry exists for the matched task and date' do
    let!(:task) { create(:task, customer:, title: 'QA Support') }
    let(:notes) { 'QA Support (0.5)' }

    it 'does not flag the row as a duplicate' do
      expect(subject.days.first.rows.first.duplicate).to be(false)
    end
  end

  context 'when an item has no hours marker' do
    let(:notes) { 'Open-ended planning discussion' }

    it 'passes the missing hours through as nil' do
      expect(subject.days.first.rows.first.hours).to be_nil
    end
  end

  context 'with a day carrying multiple items' do
    let(:notes) { 'Meetings (2), QA Support (0.5)' }

    it 'sums parsed item hours for the day' do
      expect(subject.days.first.parsed_hours).to eq(2.5)
    end

    it 'captures the stated hours from the Time column' do
      expect(subject.days.first.stated_hours).to eq(11.0)
    end
  end
end
