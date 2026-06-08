# frozen_string_literal: true

module Invoices
  class WizardController < ApplicationController
    STEPS = (1..6)
    STEP_TITLES = ['Customer + Date Range', 'Review Entries', 'Craft Lines',
                   'Generate Descriptions', 'Preview', 'Finalize'].freeze

    before_action :set_invoice, only: [:show, :update]
    before_action :set_step,    only: [:show, :update]

    # GET /invoices/:invoice_id/wizard/:step
    def show
      case @step
      when 1 then @customers = Customer.order(:name)
      when 2 then @entries_result = unbilled_entries_result
      when 3 then set_lines_data
      end
    end

    # GET /invoices/new — resumes the most recent draft, or starts a new one
    def new
      invoice = Invoice.draft.order(:created_at).last || Invoice.create!(status: 'draft', wizard_current_step: 1)
      redirect_to invoice_wizard_step_path(invoice, step: invoice.wizard_current_step || 1)
    end

    # PATCH /invoices/:invoice_id/wizard/:step — advance to the given step
    def update
      @invoice.assign_attributes(invoice_params)
      @invoice.wizard_current_step = [@invoice.wizard_current_step.to_i, @step].max
      @invoice.save!
      redirect_to invoice_wizard_step_path(@invoice, step: @step)
    end

    private

    def invoice_params
      params.fetch(:invoice, {}).permit(:customer_id, :period_start, :period_end)
    end

    def unbilled_entries_result
      return unless @invoice.customer && @invoice.period_start && @invoice.period_end

      Invoices::UnbilledEntriesQuery.call(customer: @invoice.customer, from: @invoice.period_start,
                                          to: @invoice.period_end)
    end

    def set_lines_data
      @available_tasks = @invoice.customer.tasks.billable.ordered if @invoice.customer
    end

    def set_invoice
      @invoice = Invoice.find(params.expect(:invoice_id))
    end

    def set_step
      @step = params[:step].to_i.clamp(STEPS.first, STEPS.last)
      @step_partial = case @step
                      when 1 then 'step_1'
                      when 2 then 'step_2'
                      when 3 then 'step_3'
                      when 4 then 'step_4'
                      when 5 then 'step_5'
                      else 'step_6'
                      end
      @step_titles = STEP_TITLES
      @first_step = @step == STEPS.first
      @last_step = @step == STEPS.last
    end
  end
end
