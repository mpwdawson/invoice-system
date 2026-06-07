# frozen_string_literal: true

class TimeEntriesController < ApplicationController
  def log
    @date = params[:date].presence || Date.current.to_s
  end

  def preview
    p = params.permit(:task_id, :date, :hours)
    @task = Task.includes(:customer, :project_code).find_by(id: p[:task_id])
    @date = begin
      Date.parse(p[:date].to_s)
    rescue ArgumentError
      Date.current
    end
    @hours          = p[:hours].to_d
    @existing       = @task && TimeEntry.find_by(task: @task, date: @date)
    @existing_hours = @existing&.hours.to_d
    @total          = @existing_hours + @hours
  end

  def create
    @time_entry = TimeEntry.log(
      task: Task.find(params.dig(:time_entry, :task_id)),
      date: params.dig(:time_entry, :date),
      hours: params.dig(:time_entry, :hours).to_d
    )
    @date = params.dig(:time_entry, :date)
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    @error = e.try(:record)&.errors&.full_messages&.first || e.message
    @date  = params.dig(:time_entry, :date)
    render :log, formats: [:html], status: :unprocessable_content
  end
end
