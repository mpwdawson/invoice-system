# frozen_string_literal: true

module Invoices
  class WizardController < ApplicationController
    STEPS = (1..6)
    STEP_TITLES = ['Customer + Date Range', 'Review Entries', 'Craft Lines',
                   'Project Codes', 'Preview', 'Finalize'].freeze

    before_action :set_invoice, only: [:show, :update, :finalize]
    before_action :set_step,    only: [:show, :update]

    # GET /invoices/:invoice_id/wizard/:step
    def show
      case @step
      when 1 then @customers = Customer.order(:name)
      when 2 then @entries_result = unbilled_entries_result
      when 3 then set_craft_lines_data
      when 4 then set_project_codes_data
      when 5 then set_preview_data
      end
    end

    # PATCH /invoices/:invoice_id/finalize
    def finalize
      result = Invoices::FinalizeService.call(invoice: @invoice)
      if result.success?
        redirect_to invoice_wizard_step_path(@invoice, step: 6), notice: 'Invoice finalized.'
      else
        redirect_to invoice_wizard_step_path(@invoice, step: 6), alert: result.errors.first
      end
    end

    # GET /invoices/new — resumes the most recent draft, or starts a new one
    def new
      invoice = Invoice.draft.order(:created_at).last || Invoice.create!(status: 'draft', wizard_current_step: 1)
      redirect_to invoice_wizard_step_path(invoice, step: invoice.wizard_current_step || 1)
    end

    # PATCH /invoices/:invoice_id/wizard/:step — advance to the given step
    def update
      if @step == 4 && params[:selected_tasks].present?
        sync_lines_from_selection
      else
        @invoice.assign_attributes(invoice_params)
      end

      @invoice.wizard_current_step = [@invoice.wizard_current_step.to_i, @step].max
      @invoice.save!

      target_step = @step
      if target_step == 4 && skip_project_codes?
        target_step = 5
        @invoice.update_column(:wizard_current_step, [@invoice.wizard_current_step, 5].max)
      end

      redirect_to invoice_wizard_step_path(@invoice, step: target_step)
    end

    private

    def invoice_params
      params.fetch(:invoice, {}).permit(:customer_id, :period_start, :period_end, :po_number)
    end

    def unbilled_entries_result
      return unless @invoice.customer && @invoice.period_start && @invoice.period_end

      Invoices::UnbilledEntriesQuery.call(customer: @invoice.customer, from: @invoice.period_start,
                                          to: @invoice.period_end)
    end

    def set_craft_lines_data
      return unless @invoice.customer && @invoice.period_start && @invoice.period_end

      @sort = params[:sort].presence || "title_asc"
      @period_tasks = Invoices::PeriodTasksQuery.call(
        customer: @invoice.customer, from: @invoice.period_start, to: @invoice.period_end,
        sort: @sort
      )
      @sort_key, @sort_dir = @sort.match(/\A(title|hours|date)_(asc|desc)\z/)&.captures || ["title", "asc"]
      @existing_line_task_ids = @invoice.invoice_lines.where.not(task_id: nil).pluck(:task_id)
    end

    def set_project_codes_data
      return redirect_to invoice_wizard_step_path(@invoice, step: 5) if skip_project_codes?

      line_task_ids = @invoice.invoice_lines.where.not(task_id: nil).pluck(:task_id)
      tasks = Task.includes(:project_code).where(id: line_task_ids).order(:title)
      @tasks_missing_codes = tasks.select { |task| task.project_code_id.nil? }
      @tasks_with_codes = tasks.select { |task| task.project_code_id.present? }
      @task_hours = TimeEntry.where(task_id: line_task_ids, date: @invoice.period_start..@invoice.period_end, invoice_id: nil)
                             .group(:task_id).sum(:hours)
    end

    def skip_project_codes?
      !@invoice.customer&.requires_project_codes?
    end

    def set_preview_data
      @entries_result = unbilled_entries_result
      return unless @invoice.customer&.requires_project_codes?

      @project_summary = Invoices::ProjectSummaryQuery.call(customer: @invoice.customer,
                                                            from: @invoice.period_start, to: @invoice.period_end)
    end

    # Sync invoice_lines based on step 3 checkbox selections
    def sync_lines_from_selection
      selected = params[:selected_tasks] || {}
      selected_task_ids = selected.keys.map(&:to_i)

      # Delete lines for unchecked tasks
      @invoice.invoice_lines.where.not(task_id: selected_task_ids).where.not(task_id: nil).destroy_all

      # Create or update lines for checked tasks
      next_sort = (@invoice.invoice_lines.maximum(:sort_order) || -1) + 1
      selected.each do |task_id, invoice_name|
        task = Task.find(task_id.to_i)
        name = invoice_name.presence || task.invoice_name.presence || task.title

        task.update!(invoice_name: name) if name != task.invoice_name

        existing_line = @invoice.invoice_lines.find_by(task_id: task.id)
        if existing_line
          existing_line.update!(description: name)
        else
          @invoice.invoice_lines.create!(task_id: task.id, description: name, sort_order: next_sort)
          next_sort += 1
        end
      end
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
