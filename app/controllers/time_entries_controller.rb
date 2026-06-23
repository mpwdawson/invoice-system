# frozen_string_literal: true

class TimeEntriesController < ApplicationController
  def show
    @time_entry = TimeEntry.find(params.expect(:id))
  end

  # PATCH /time_entries/:id/update_inline
  def update_inline
    @time_entry = TimeEntry.find(params.expect(:id))
    if @time_entry.update(inline_time_entry_params)
      @customer_id = session[:log_customer_id]
      @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
    else
      head :unprocessable_content
    end
  end

  def edit
    @time_entry = TimeEntry.find(params.expect(:id))
  end

  def create
    @customer_id = session[:log_customer_id]
    @customers   = Customer.order(:name)
    @time_entry  = TimeEntry.log(
      task: Task.find(params.dig(:time_entry, :task_id)),
      date: params.dig(:time_entry, :date),
      hours: params.dig(:time_entry, :hours).to_d
    )
    @date        = params.dig(:time_entry, :date)
    @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    @error       = e.try(:record)&.errors&.full_messages&.first || e.message
    @date        = params.dig(:time_entry, :date)
    @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
    render :log, formats: [:html], status: :unprocessable_content
  end

  def update
    @customer_id = session[:log_customer_id]
    @time_entry  = TimeEntry.find(params.expect(:id))
    if @time_entry.update(time_entry_params)
      @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
    else
      render :edit, formats: [:html], status: :unprocessable_content
    end
  end

  def destroy
    @customer_id = session[:log_customer_id]
    @time_entry  = TimeEntry.find(params.expect(:id))
    if @time_entry.invoice_id? && params[:force].blank?
      @soft_lock = true
    else
      task_redirect = @time_entry.task if params[:source] == "task"
      @time_entry.destroy!

      if task_redirect
        redirect_to task_path(task_redirect), notice: "Entry deleted."
        return
      end

      @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
    end
  end

  # PATCH /time_entries/:id/reassign — move entry to a different task
  def reassign
    @time_entry = TimeEntry.find(params.expect(:id))
    target_task = Task.find(params.expect(:task_id))

    if @time_entry.invoice_id?
      redirect_to task_path(@time_entry.task), alert: "Cannot reassign a billed entry."
      return
    end

    unless target_task.customer_id == @time_entry.task.customer_id
      redirect_to task_path(@time_entry.task), alert: "Target task must belong to the same customer."
      return
    end

    original_task = @time_entry.task
    @time_entry.task = target_task

    if @time_entry.save
      redirect_to task_path(original_task), notice: "Entry reassigned to \"#{target_task.title}\"."
    else
      redirect_to task_path(original_task), alert: @time_entry.errors.full_messages.to_sentence
    end
  end

  # GET /log — primary daily entry screen
  def log
    if params.key?(:customer_id)
      session[:log_customer_id] = params[:customer_id].presence
    end
    @customer_id = session[:log_customer_id]
    @customers   = Customer.order(:name)
    @date        = params[:date].presence || user_date.to_s
    @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
  end

  # GET /time_entries/preview — Turbo Frame running-total panel, updated on field change
  def preview
    permitted = params.permit(:task_id, :date, :hours)
    @task = Task.includes(:customer, :project_code).find_by(id: permitted[:task_id])
    @date = begin
      Date.parse(permitted[:date].to_s)
    rescue ArgumentError
      user_date
    end
    @hours          = permitted[:hours].to_d
    @existing       = @task && TimeEntry.find_by(task: @task, date: @date)
    @existing_hours = @existing&.hours.to_d
    @total          = @existing_hours + @hours
  end

  private

  def time_entry_params
    params.expect(time_entry: %i[hours date])
  end

  def inline_time_entry_params
    params.expect(time_entry: %i[hours date])
  end
end
