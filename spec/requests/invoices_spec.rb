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
