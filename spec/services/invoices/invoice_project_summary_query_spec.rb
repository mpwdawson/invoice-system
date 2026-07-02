# frozen_string_literal: true

require 'rails_helper'

describe Invoices::InvoiceProjectSummaryQuery do
  subject { described_class.call(invoice:) }

  let(:customer) { create(:customer) }
  let(:invoice)  { create(:invoice, customer:, status: 'ready') }

  context 'with stamped entries on tasks with project codes' do
    let(:design_code) { create(:project_code, customer:, code: 'DSNSERV', description: 'Design Services') }
    let(:infra_code)  { create(:project_code, customer:, code: 'INFRAWEB', description: 'Rails Upgrades') }
    let(:design_task) { create(:task, customer:, project_code: design_code) }
    let(:infra_task)  { create(:task, customer:, project_code: infra_code) }

    let!(:design_entry) { create(:time_entry, task: design_task, date: Date.new(2026, 5, 5), hours: 3.0, invoice:) }
    let!(:infra_entry)  { create(:time_entry, task: infra_task, date: Date.new(2026, 5, 12), hours: 2.5, invoice:) }

    it 'groups hours by project code, ordered by code' do
      expect(subject.rows.map(&:project_code)).to eq([design_code, infra_code])
      expect(subject.rows.map(&:hours)).to eq([3.0, 2.5])
    end

    it 'sums rows into total_hours' do
      expect(subject.total_hours).to eq(5.5)
    end
  end

  context 'with entries stamped on a different invoice' do
    let(:other_invoice) { create(:invoice, customer:) }
    let(:project_code)  { create(:project_code, customer:) }
    let(:task)          { create(:task, customer:, project_code:) }

    before { create(:time_entry, task:, date: Date.new(2026, 5, 5), hours: 4.0, invoice: other_invoice) }

    it 'excludes them' do
      expect(subject.rows).to be_empty
      expect(subject.total_hours).to eq(0)
    end
  end

  context 'with stamped entries on tasks without a project code' do
    let(:task) { create(:task, customer:, project_code: nil) }

    before { create(:time_entry, task:, date: Date.new(2026, 5, 8), hours: 5.0, invoice:) }

    it 'sums them into unassigned_hours and total_hours but not rows' do
      expect(subject.rows).to be_empty
      expect(subject.unassigned_hours).to eq(5.0)
      expect(subject.total_hours).to eq(5.0)
    end
  end
end
