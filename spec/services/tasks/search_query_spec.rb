# frozen_string_literal: true

require 'rails_helper'

describe Tasks::SearchQuery do
  subject do
    described_class.call(
      query:           query,
      customer_id:     customer_id,
      project_code_id: project_code_id,
      date_from:       date_from,
      status:          status,
      billable:        billable,
      sort:            sort,
      direction:       direction
    )
  end

  let(:customer)       { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:query)          { nil }
  let(:customer_id)    { nil }
  let(:project_code_id) { nil }
  let(:date_from)      { nil }
  let(:status)         { 'active' }
  let(:billable)       { nil }
  let(:sort)           { nil }
  let(:direction)      { nil }

  let!(:task_alpha)  { create(:task, title: 'Alpha task', customer: customer, status: 'active', billable: true) }
  let!(:task_beta)   { create(:task, title: 'Beta task',  customer: customer, status: 'active', billable: false) }
  let!(:task_arch)   { create(:task, title: 'Archived task', customer: customer, status: 'archived', billable: true) }
  let!(:task_other)  { create(:task, title: 'Other customer task', customer: other_customer, status: 'active') }

  context 'with no query' do
    it 'returns all active tasks' do
      expect(subject).to include(task_alpha, task_beta, task_other)
    end

    it 'excludes archived tasks by default' do
      expect(subject).not_to include(task_arch)
    end
  end

  context 'with a title query' do
    let(:query) { 'Alpha' }

    it 'returns tasks matching the title' do
      expect(subject).to include(task_alpha)
    end

    it 'excludes non-matching tasks' do
      expect(subject).not_to include(task_beta)
    end
  end

  context 'with a ticket ref query' do
    let(:query) { 'AW-6770' }

    before { create(:ticket_reference, task: task_alpha, prefix: 'AW', number: 6770) }

    it 'returns the task with that ticket ref' do
      expect(subject).to include(task_alpha)
    end

    it 'excludes tasks without that ref' do
      expect(subject).not_to include(task_beta)
    end
  end

  context 'with a lowercase ticket ref query' do
    let(:query) { 'aw-6770' }

    before { create(:ticket_reference, task: task_alpha, prefix: 'AW', number: 6770) }

    it 'matches case-insensitively' do
      expect(subject).to include(task_alpha)
    end
  end

  context 'with customer_id filter' do
    it 'narrows results to that customer' do
      result = described_class.call(query: nil, customer_id: customer.id, status: 'active')
      expect(result).to include(task_alpha, task_beta)
      expect(result).not_to include(task_other)
    end
  end

  context 'with status filter' do
    let(:status) { 'archived' }

    it 'returns archived tasks' do
      expect(subject).to include(task_arch)
    end

    it 'excludes active tasks' do
      expect(subject).not_to include(task_alpha)
    end
  end

  context 'with billable filter' do
    let(:billable) { 'true' }

    it 'returns only billable tasks' do
      expect(subject).to include(task_alpha)
      expect(subject).not_to include(task_beta)
    end
  end

  context 'with project_code_id filter' do
    let(:project_code) { create(:project_code, customer: customer) }
    let!(:task_with_code)    { create(:task, customer: customer, project_code: project_code) }
    let!(:task_without_code) { create(:task, customer: customer) }
    let(:project_code_id) { project_code.id }

    it 'returns only tasks with that project code' do
      expect(subject).to include(task_with_code)
      expect(subject).not_to include(task_without_code)
    end
  end

  context 'with project_code_id: "none"' do
    let(:project_code) { create(:project_code, customer: customer) }
    let!(:task_with_code)    { create(:task, customer: customer, project_code: project_code) }
    let!(:task_without_code) { create(:task, customer: customer) }
    let(:project_code_id) { 'none' }

    it 'returns only tasks with no project code' do
      expect(subject).to include(task_without_code)
      expect(subject).not_to include(task_with_code)
    end
  end

  context 'with date_from filter' do
    let!(:old_task)   { create(:task, customer: customer) }
    let!(:new_task)   { create(:task, customer: customer) }
    let(:date_from)   { 1.day.ago.to_date.to_s }

    before do
      old_task.update_columns(created_at: 1.year.ago)
      new_task.update_columns(created_at: Time.current)
    end

    it 'excludes tasks created before the date' do
      expect(subject).not_to include(old_task)
    end

    it 'includes tasks created on or after the date' do
      expect(subject).to include(new_task)
    end
  end

  context 'with sort: customer, direction: asc' do
    let(:sort)      { 'customer' }
    let(:direction) { 'asc' }
    let!(:z_customer) { create(:customer, name: 'Zephyr Corp') }
    let!(:a_customer) { create(:customer, name: 'Acme Corp') }
    let!(:task_z) { create(:task, customer: z_customer, title: 'Z task') }
    let!(:task_a) { create(:task, customer: a_customer, title: 'A task') }

    it 'orders by customer name ascending' do
      titles = subject.map { |t| t.customer.name }
      expect(titles).to eq(titles.sort)
    end
  end

  context 'with sort: created_at, direction: desc' do
    let(:sort)      { 'created_at' }
    let(:direction) { 'desc' }
    let!(:task_old) { create(:task, customer: customer) }
    let!(:task_new) { create(:task, customer: customer) }

    before do
      task_old.update_columns(created_at: 2.days.ago)
      task_new.update_columns(created_at: Time.current)
    end

    it 'orders newest first' do
      ids = subject.map(&:id)
      expect(ids.index(task_new.id)).to be < ids.index(task_old.id)
    end
  end

  context 'with an invalid sort column' do
    let(:sort) { 'evil_column; DROP TABLE tasks;--' }

    it 'falls back to title order without raising' do
      expect { subject }.not_to raise_error
    end
  end

  context 'with a ticket prefix and title combined in query' do
    let(:query) { 'aw-6770 Alpha task' }

    before { create(:ticket_reference, task: task_alpha, prefix: 'AW', number: 6770) }

    it 'finds the task by matching ticket ref and title separately' do
      expect(subject).to include(task_alpha)
    end

    it 'excludes tasks that match neither' do
      expect(subject).not_to include(task_beta)
    end
  end

  context 'with a task that has multiple matching ticket refs' do
    let(:query) { 'AW' }

    before do
      create(:ticket_reference, task: task_alpha, prefix: 'AW', number: 6770)
      create(:ticket_reference, task: task_alpha, prefix: 'AW', number: 6771)
    end

    it 'returns the task only once' do
      expect(subject.count { |t| t.id == task_alpha.id }).to eq(1)
    end
  end
end
