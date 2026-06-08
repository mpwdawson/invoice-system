# frozen_string_literal: true

require 'rails_helper'

describe Invoices::LinesController do
  before { post login_path, params: { password: 'test_password' } }

  let(:customer) { create(:customer) }
  let(:invoice)  { create(:invoice, customer:) }
  let(:task)     { create(:task, customer:, title: 'Rewards Dashboard') }

  describe 'POST #create' do
    subject { post invoice_lines_path(invoice), params: params }

    let(:params) { { invoice_line: { description: 'Worked on rewards dashboard', task_ids: [task.id.to_s] } } }

    it 'creates a line on the invoice with the next sort order' do
      create(:invoice_line, invoice:, sort_order: 0)

      expect { subject }.to change(invoice.invoice_lines, :count).by(1)
      expect(invoice.invoice_lines.order(:sort_order).last.sort_order).to eq(1)
    end

    it 'normalizes task_ids to an integer array' do
      subject

      expect(invoice.invoice_lines.last.task_ids).to eq([task.id])
    end

    it 'returns an html response with the invoice-lines turbo frame' do
      subject

      expect(response.media_type).to eq('text/html')
      expect(response.body).to include('id="invoice-lines"')
    end
  end

  describe 'PATCH #update' do
    subject { patch invoice_line_path(invoice, line), params: params }

    let(:line)   { create(:invoice_line, invoice:, description: 'Old description', task_ids: []) }
    let(:params) { { invoice_line: { description: 'New description', task_ids: [task.id.to_s] } } }

    it 'updates the description and task_ids' do
      subject

      line.reload
      expect(line.description).to eq('New description')
      expect(line.task_ids).to eq([task.id])
    end
  end

  describe 'DELETE #destroy' do
    subject { delete invoice_line_path(invoice, line) }

    let!(:line) { create(:invoice_line, invoice:) }

    it 'destroys the line' do
      expect { subject }.to change(InvoiceLine, :count).by(-1)
    end
  end

  describe 'PATCH #sort' do
    subject { patch sort_invoice_lines_path(invoice), params: { line_ids: ordered_ids } }

    let!(:first)  { create(:invoice_line, invoice:, sort_order: 0) }
    let!(:second) { create(:invoice_line, invoice:, sort_order: 1) }
    let(:ordered_ids) { [second.id, first.id] }

    it 'updates sort_order to match the given order' do
      subject

      expect(second.reload.sort_order).to eq(0)
      expect(first.reload.sort_order).to eq(1)
    end

    it 'responds with no content' do
      subject

      expect(response).to have_http_status(:no_content)
    end
  end
end
