# frozen_string_literal: true

class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :mark_sent, :mark_paid]

  def index
    @invoices = Invoice.includes(:customer).order(sequence_number: :desc)
  end

  def show
    redirect_to invoice_wizard_step_path(@invoice, step: @invoice.wizard_current_step || 1) if @invoice.draft?
  end

  # PATCH /invoices/:id/mark_sent
  def mark_sent
    if @invoice.update(status: 'sent', sent_at: Time.current)
      redirect_to invoice_path(@invoice), notice: 'Invoice marked as sent.'
    else
      redirect_to invoice_path(@invoice), alert: @invoice.errors[:status].first
    end
  end

  # PATCH /invoices/:id/mark_paid
  def mark_paid
    if @invoice.update(status: 'paid', paid_at: Time.current)
      redirect_to invoice_path(@invoice), notice: 'Invoice marked as paid.'
    else
      redirect_to invoice_path(@invoice), alert: @invoice.errors[:status].first
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params.expect(:id))
  end
end
