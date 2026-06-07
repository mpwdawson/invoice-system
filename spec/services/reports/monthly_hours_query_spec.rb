# frozen_string_literal: true

require 'rails_helper'

describe Reports::MonthlyHoursQuery do
  subject { described_class.call(customer:, from:, to:) }

  let(:customer) { create(:customer) }
  let(:from)     { Date.current.beginning_of_month }
  let(:to)       { Date.current.end_of_month }

  context 'with no entries' do
    it 'returns empty rows and zero totals' do
      expect(subject.rows).to be_empty
      expect(subject.total_hours).to eq(0)
      expect(subject.unassigned_hours).to eq(0)
    end
  end

  context 'with entries assigned to a project code' do
    let(:project_code) { create(:project_code, customer:) }
    let!(:entry) { create(:time_entry, task: create(:task, customer:, project_code:), date: from, hours: 3.0) }

    it 'includes the project code in rows' do
      expect(subject.rows.map(&:project_code)).to include(project_code)
    end

    it 'sums hours correctly' do
      expect(subject.rows.first.hours).to eq(3.0)
    end

    it 'includes the hours in total_hours' do
      expect(subject.total_hours).to eq(3.0)
    end

    it 'has zero unassigned_hours' do
      expect(subject.unassigned_hours).to eq(0)
    end
  end

  context 'with entries for a task without a project code' do
    let!(:entry) { create(:time_entry, task: create(:task, customer:), date: from, hours: 1.5) }

    it 'returns no rows' do
      expect(subject.rows).to be_empty
    end

    it 'reports unassigned_hours' do
      expect(subject.unassigned_hours).to eq(1.5)
    end

    it 'includes unassigned hours in total_hours' do
      expect(subject.total_hours).to eq(1.5)
    end
  end

  context 'with entries outside the date range' do
    let!(:entry) { create(:time_entry, task: create(:task, customer:), date: from - 1, hours: 2.0) }

    it 'excludes them from total_hours' do
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with entries for a different customer' do
    let!(:entry) { create(:time_entry, task: create(:task, customer: create(:customer)), date: from, hours: 2.0) }

    it 'excludes them from total_hours' do
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with multiple project codes' do
    let(:pc_a) { create(:project_code, customer:, code: 'AA') }
    let(:pc_b) { create(:project_code, customer:, code: 'BB') }
    let!(:ea)  { create(:time_entry, task: create(:task, customer:, project_code: pc_a), date: from,     hours: 2.0) }
    let!(:eb)  { create(:time_entry, task: create(:task, customer:, project_code: pc_b), date: from + 1, hours: 3.0) }

    it 'orders rows by project code' do
      expect(subject.rows.map { |r| r.project_code.code }).to eq(%w[AA BB])
    end

    it 'sums total_hours across all project codes' do
      expect(subject.total_hours).to eq(5.0)
    end
  end
end
