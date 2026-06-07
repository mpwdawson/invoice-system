# frozen_string_literal: true

require 'rails_helper'

describe Tasks::SearchQuery do
  subject { described_class.call(query: query, customer_id: customer_id, status: status, billable: billable) }

  let(:customer)       { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:query)          { nil }
  let(:customer_id)    { nil }
  let(:status)         { 'active' }
  let(:billable)       { nil }

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
