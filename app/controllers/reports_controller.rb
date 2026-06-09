# frozen_string_literal: true

require 'csv'

class ReportsController < ApplicationController
  before_action :set_filters

  # GET /reports/monthly_hours
  def monthly_hours
    @result = @customer ? Reports::MonthlyHoursQuery.call(customer: @customer, from: @from, to: @to) : nil

    respond_to do |format|
      format.html
      format.csv do
        send_data build_csv, filename: csv_filename, type: 'text/csv', disposition: 'attachment'
      end
    end
  end

  # GET /reports/daily_log
  def daily_log
    @result = @customer ? Reports::DailyLogQuery.call(customer: @customer, from: @from, to: @to) : nil
  end

  # GET /reports/task_totals
  def task_totals
    @project_codes = @customer ? @customer.project_codes.ordered : ProjectCode.none
    @project_code  = @project_codes.find_by(id: params[:project_code_id])
    @status        = params[:status].presence
    @billable      = parse_bool(params[:billable])

    @result = if @customer
                Reports::TaskTotalsQuery.call(
                  customer: @customer, from: @from, to: @to,
                  project_code: @project_code, status: @status, billable: @billable
                )
              end
  end

  private

  def set_filters
    @customers = Customer.order(:name)
    @customer  = Customer.find_by(id: params[:customer_id])
    @from      = parse_date(params[:from]) || user_date.beginning_of_month
    @to        = parse_date(params[:to])   || user_date.end_of_month
  end

  def parse_date(val)
    Date.parse(val.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_bool(val)
    return nil if val.blank?

    val == 'true'
  end

  def build_csv
    CSV.generate do |csv|
      csv << %w[project_code description hours]
      @result.rows.each { |row| csv << [row.project_code.code, row.project_code.description, row.hours] }
      csv << ['(unassigned)', '', @result.unassigned_hours] if @result.unassigned_hours.positive?
      csv << (%w[TOTAL] + ['', @result.total_hours])
    end
  end

  def csv_filename
    "monthly-hours-#{@customer.name.parameterize}-#{@from}.csv"
  end
end
