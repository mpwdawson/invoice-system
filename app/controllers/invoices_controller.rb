# frozen_string_literal: true

class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :print, :mark_sent, :mark_paid]

  def index
    @invoices = Invoice.includes(:customer).order(sequence_number: :desc)
  end

  def show
    redirect_to invoice_wizard_step_path(@invoice, step: @invoice.wizard_current_step || 1) if @invoice.draft?
  end

  # GET /invoices/:id/print — clean printable invoice (no app shell)
  def print
    redirect_to invoice_path(@invoice), alert: "Only finalized invoices can be printed." and return if @invoice.draft?

    @profile  = ContractorProfile.first
    @customer = @invoice.customer
    @lines    = @invoice.invoice_lines.order(:sort_order)
    @line_hours = TimeEntry.where(invoice_id: @invoice.id).group(:task_id).sum(:hours)
    @named_hours = @lines.filter_map { |line| @line_hours[line.task_id] if line.task_id }.sum
    @other_hours = @invoice.total_hours - @named_hours
    @project_summary = Invoices::InvoiceProjectSummaryQuery.call(invoice: @invoice) if @customer&.requires_project_codes?

    render layout: "print"
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
