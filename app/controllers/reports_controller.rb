# frozen_string_literal: true

require 'csv'

class ReportsController < ApplicationController
  # GET /reports/monthly_hours
  def monthly_hours
    @customers = Customer.order(:name)
    @customer  = Customer.find_by(id: params[:customer_id])
    @from      = parse_date(params[:from]) || Date.current.beginning_of_month
    @to        = parse_date(params[:to])   || Date.current.end_of_month

    @result = @customer ? Reports::MonthlyHoursQuery.call(customer: @customer, from: @from, to: @to) : nil

    respond_to do |format|
      format.html
      format.csv do
        send_data build_csv, filename: csv_filename, type: 'text/csv', disposition: 'attachment'
      end
    end
  end

  private

  def parse_date(val)
    Date.parse(val.to_s)
  rescue ArgumentError, TypeError
    nil
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
