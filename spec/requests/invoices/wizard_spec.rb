# frozen_string_literal: true

require 'rails_helper'

describe Invoices::WizardController do
  before { post login_path, params: { password: 'test_password' } }

  describe 'GET #new' do
    subject { get new_invoice_path }

    context 'when no draft invoice exists' do
      it 'creates a draft invoice and redirects to step 1' do
        expect { subject }.to change(Invoice, :count).by(1)

        invoice = Invoice.last
        expect(invoice).to be_draft
        expect(invoice.wizard_current_step).to eq(1)
        expect(response).to redirect_to(invoice_wizard_step_path(invoice, step: 1))
      end
    end

    context 'when a draft invoice already exists' do
      let!(:existing) { create(:invoice, wizard_current_step: 3) }

      it 'resumes the existing draft at its current step' do
        expect { subject }.not_to change(Invoice, :count)
        expect(response).to redirect_to(invoice_wizard_step_path(existing, step: 3))
      end
    end
  end

  describe 'GET #show' do
    subject { get invoice_wizard_step_path(invoice, step: 1) }

    let(:invoice) { create(:invoice, wizard_current_step: 1) }

    it 'returns ok' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH #update' do
    subject { patch invoice_wizard_step_path(invoice, step: 2) }

    let(:invoice) { create(:invoice, wizard_current_step: 1) }

    it 'persists the new wizard_current_step and redirects to it' do
      subject

      expect(invoice.reload.wizard_current_step).to eq(2)
      expect(response).to redirect_to(invoice_wizard_step_path(invoice, step: 2))
    end

    context 'when navigating back to an earlier step' do
      subject { patch invoice_wizard_step_path(invoice, step: 1) }

      let(:invoice) { create(:invoice, wizard_current_step: 3) }

      it 'does not regress wizard_current_step' do
        subject

        expect(invoice.reload.wizard_current_step).to eq(3)
      end
    end

    context 'when submitting step 3 task selections' do
      subject { patch invoice_wizard_step_path(invoice, step: 4), params: params }

      let(:customer) { create(:customer) }
      let(:invoice)  { create(:invoice, customer:, wizard_current_step: 3, period_start: '2026-06-01', period_end: '2026-06-30') }
      let(:task_a)   { create(:task, customer:, title: 'Design Work') }
      let(:task_b)   { create(:task, customer:, title: 'Bug Fixes') }

      before do
        create(:time_entry, task: task_a, date: Date.new(2026, 6, 5), hours: 3.0)
        create(:time_entry, task: task_b, date: Date.new(2026, 6, 10), hours: 2.0)
      end

      let(:params) { { selected_tasks: { task_a.id.to_s => 'Design Platform Features', task_b.id.to_s => '' } } }

      it 'creates invoice lines and skips project codes step when not required' do
        expect { subject }.to change(invoice.invoice_lines, :count).by(2)

        lines = invoice.invoice_lines.reload.order(:sort_order)
        expect(lines.first.task_id).to eq(task_a.id)
        expect(lines.first.description).to eq('Design Platform Features')
        expect(lines.second.task_id).to eq(task_b.id)
        expect(lines.second.description).to eq('Bug Fixes')
        expect(response).to redirect_to(invoice_wizard_step_path(invoice, step: 5))
      end

      it 'saves invoice_name back to the task' do
        subject

        expect(task_a.reload.invoice_name).to eq('Design Platform Features')
      end

      it 'deletes lines for unchecked tasks on re-submission' do
        create(:invoice_line, invoice:, task: task_a, description: 'Old')
        create(:invoice_line, invoice:, task: task_b, description: 'Old')

        patch invoice_wizard_step_path(invoice, step: 4),
              params: { selected_tasks: { task_a.id.to_s => 'Design Platform Features' } }

        expect(invoice.invoice_lines.reload.pluck(:task_id)).to eq([task_a.id])
      end
    end

    context 'when submitting step 3 for a customer requiring project codes' do
      subject { patch invoice_wizard_step_path(invoice, step: 4), params: params }

      let(:customer) { create(:customer, requires_project_codes: true) }
      let(:invoice)  { create(:invoice, customer:, wizard_current_step: 3, period_start: '2026-06-01', period_end: '2026-06-30') }
      let(:task)     { create(:task, customer:, title: 'Design Work', project_code: nil) }
      let(:params)   { { selected_tasks: { task.id.to_s => 'Design Platform Features' } } }

      before { create(:time_entry, task:, date: Date.new(2026, 6, 5), hours: 3.0) }

      it 'stops at the project codes step' do
        subject

        expect(response).to redirect_to(invoice_wizard_step_path(invoice, step: 4))
      end
    end

    context 'when submitting step 1 invoice fields' do
      subject { patch invoice_wizard_step_path(invoice, step: 1), params: params }

      let(:invoice)        { create(:invoice, wizard_current_step: 1) }
      let(:other_customer) { create(:customer) }
      let(:params) do
        { invoice: { customer_id: other_customer.id, period_start: '2026-05-01', period_end: '2026-05-31' } }
      end

      it 'persists the customer and date range onto the invoice' do
        subject

        invoice.reload
        expect(invoice.customer).to eq(other_customer)
        expect(invoice.period_start).to eq(Date.new(2026, 5, 1))
        expect(invoice.period_end).to eq(Date.new(2026, 5, 31))
      end
    end
  end
end
