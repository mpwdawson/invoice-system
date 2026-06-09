# frozen_string_literal: true

class TimeEntriesController < ApplicationController
  def show
    @time_entry = TimeEntry.find(params.expect(:id))
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
      @time_entry.destroy!
      @log_entries = TimeEntries::RecentLogQuery.call(days: 14, customer_id: @customer_id, today: user_date)
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
end
