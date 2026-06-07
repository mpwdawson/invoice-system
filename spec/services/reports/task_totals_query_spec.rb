# frozen_string_literal: true

require 'rails_helper'

describe Reports::TaskTotalsQuery do
  subject { described_class.call(customer:, from:, to:, project_code: nil, status: nil, billable: nil) }

  let(:customer) { create(:customer) }
  let(:from)     { Date.current.beginning_of_month }
  let(:to)       { Date.current.end_of_month }

  context 'with no entries' do
    it 'returns no rows and zero total' do
      expect(subject.rows).to be_empty
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with entries logged against a task' do
    let(:task) { create(:task, customer:, title: 'Build feature') }
    let!(:entry) { create(:time_entry, task:, date: from, hours: 3.0) }

    it 'includes the task with its summed hours' do
      row = subject.rows.find { |r| r.task == task }
      expect(row.hours).to eq(3.0)
    end

    it 'includes it in total_hours' do
      expect(subject.total_hours).to eq(3.0)
    end
  end

  context 'filtering by project_code' do
    subject { described_class.call(customer:, from:, to:, project_code: pc_a, status: nil, billable: nil) }

    let(:pc_a) { create(:project_code, customer:) }
    let(:pc_b) { create(:project_code, customer:) }
    let(:task_a) { create(:task, customer:, project_code: pc_a) }
    let(:task_b) { create(:task, customer:, project_code: pc_b) }

    before do
      create(:time_entry, task: task_a, date: from, hours: 1.0)
      create(:time_entry, task: task_b, date: from, hours: 2.0)
    end

    it 'only includes tasks under that project code' do
      expect(subject.rows.map(&:task)).to eq([task_a])
    end
  end

  context 'filtering by status' do
    subject { described_class.call(customer:, from:, to:, project_code: nil, status: 'archived', billable: nil) }

    let(:active_task)   { create(:task, customer:, status: 'active') }
    let(:archived_task) { create(:task, customer:, status: 'archived') }

    before do
      create(:time_entry, task: active_task, date: from, hours: 1.0)
      create(:time_entry, task: archived_task, date: from, hours: 1.0)
    end

    it 'only includes tasks with that status' do
      expect(subject.rows.map(&:task)).to eq([archived_task])
    end
  end

  context 'filtering by billable' do
    subject { described_class.call(customer:, from:, to:, project_code: nil, status: nil, billable: false) }

    let(:billable_task)     { create(:task, customer:, billable: true) }
    let(:non_billable_task) { create(:task, customer:, billable: false) }

    before do
      create(:time_entry, task: billable_task, date: from, hours: 1.0)
      create(:time_entry, task: non_billable_task, date: from, hours: 1.0)
    end

    it 'only includes tasks matching the billable flag' do
      expect(subject.rows.map(&:task)).to eq([non_billable_task])
    end
  end

  context 'with an entry outside the date range' do
    let!(:entry) { create(:time_entry, task: create(:task, customer:), date: from - 1, hours: 2.0) }

    it 'excludes the task' do
      expect(subject.rows).to be_empty
    end
  end
end
