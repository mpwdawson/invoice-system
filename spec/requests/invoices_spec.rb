# frozen_string_literal: true

require 'rails_helper'

describe InvoicesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }

  describe 'GET #index' do
    subject { get invoices_path }

    it 'renders the index' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #show' do
    subject { get invoice_path(invoice) }

    context 'for a draft invoice' do
      let(:invoice) { create(:invoice, customer:, wizard_current_step: 3) }

      it 'redirects to the wizard at its current step' do
        subject
        expect(response).to redirect_to(invoice_wizard_step_path(invoice, step: 3))
      end
    end

    context 'for a finalized invoice' do
      let(:invoice) { create(:invoice, customer:, status: 'ready', total_hours: 4.0, total_amount: 380.00, rate: 95.00) }

      it 'returns ok' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #print' do
    subject { get print_invoice_path(invoice) }

    context 'for a finalized invoice' do
      let(:profile) { create(:contractor_profile, phone: '555.123.4567') }
      let(:invoice) do
        create(:invoice, customer:, status: 'ready', total_hours: 10.0,
               total_amount: 1000.00, rate: 100.00, po_number: 'PO-999')
      end

      before do
        profile
        create(:invoice_line, invoice:, description: 'January work')
      end

      it 'renders the print layout with invoice data' do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('555.123.4567')
        expect(response.body).to include(invoice.invoice_number)
        expect(response.body).to include('PO-999')
        expect(response.body).to include('January work')
        expect(response.body).to include('$1,000.00')
        expect(response.body).not_to include('main-sidebar')
      end
    end

    context 'with expense lines' do
      let(:profile) { create(:contractor_profile) }
      let(:invoice) do
        create(:customer_rate, customer:, rate: 100.00, effective_from: Date.new(2026, 1, 1))
        create(:invoice, customer:, status: 'ready', total_hours: 10.0,
               total_amount: 1050.00,
               period_start: Date.new(2026, 5, 1), period_end: Date.new(2026, 5, 31))
      end

      before do
        profile
        create(:invoice_line, invoice:, description: 'Dev work', line_type: 'task', quantity: 10.0, unit_price: 100.00)
        create(:invoice_line, :expense, invoice:, description: 'Monthly internet - May 2026', quantity: 1, unit_price: 50.00)
      end

      it 'renders task lines, expense lines, and correct totals' do
        subject

        expect(response.body).to include('Dev work')
        expect(response.body).to include('Monthly internet - May 2026')
        expect(response.body).to include('$50.00')
        expect(response.body).to include('Total Hours')
        expect(response.body).to include('$1,000.00')
        expect(response.body).to include('$1,050.00')
      end
    end

    context 'with project code breakdown' do
      let(:customer) { create(:customer, requires_project_codes: true) }
      let(:profile)  { create(:contractor_profile) }
      let(:project_code) { create(:project_code, customer:, code: 'PROJ-001', description: 'Platform Work') }
      let(:task) { create(:task, customer:, project_code:) }
      let(:invoice) do
        create(:invoice, customer:, status: 'ready', total_hours: 4.0,
               total_amount: 400.00, rate: 100.00)
      end

      before do
        profile
        create(:invoice_line, invoice:, task:, description: 'Platform dev')
        create(:time_entry, task:, date: Date.new(2026, 5, 10), hours: 4.0, invoice:)
      end

      it 'renders the project code table on page 2' do
        subject

        expect(response.body).to include('Project Code Breakdown')
        expect(response.body).to include('PROJ-001')
        expect(response.body).to include('Platform Work')
      end
    end

    context 'for a draft invoice' do
      let(:invoice) { create(:invoice, customer:, status: 'draft') }

      it 'redirects with an alert' do
        subject

        expect(response).to redirect_to(invoice_path(invoice))
        expect(flash[:alert]).to eq('Only finalized invoices can be printed.')
      end
    end
  end

  describe 'PATCH #mark_sent' do
    subject { patch mark_sent_invoice_path(invoice) }

    context 'for a ready invoice' do
      let(:invoice) { create(:invoice, customer:, status: 'ready', total_hours: 4.0, total_amount: 380.00, rate: 95.00) }

      it 'transitions to sent and stamps sent_at' do
        subject

        invoice.reload
        expect(invoice.status).to eq('sent')
        expect(invoice.sent_at).to be_present
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end

    context 'for a draft invoice' do
      let(:invoice) { create(:invoice, customer:, status: 'draft') }

      it 'rejects the illegal transition' do
        subject

        invoice.reload
        expect(invoice.status).to eq('draft')
        expect(invoice.sent_at).to be_nil
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'PATCH #mark_paid' do
    subject { patch mark_paid_invoice_path(invoice) }

    context 'for a sent invoice' do
      let(:invoice) do
        create(:invoice, customer:, status: 'sent', sent_at: 1.day.ago, total_hours: 4.0, total_amount: 380.00, rate: 95.00)
      end

      it 'transitions to paid and stamps paid_at' do
        subject

        invoice.reload
        expect(invoice.status).to eq('paid')
        expect(invoice.paid_at).to be_present
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end

    context 'for a ready invoice' do
      let(:invoice) { create(:invoice, customer:, status: 'ready', total_hours: 4.0, total_amount: 380.00, rate: 95.00) }

      it 'rejects the illegal transition' do
        subject

        invoice.reload
        expect(invoice.status).to eq('ready')
        expect(invoice.paid_at).to be_nil
        expect(flash[:alert]).to be_present
      end
    end
  end
end
