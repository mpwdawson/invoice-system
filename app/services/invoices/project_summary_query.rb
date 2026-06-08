# frozen_string_literal: true

module Invoices
  class ProjectSummaryQuery
    Row    = Struct.new(:project_code, :hours, keyword_init: true)
    Result = Struct.new(:rows, :unassigned_hours, :total_hours, keyword_init: true)

    def self.call(customer:, from:, to:)
      new(customer:, from:, to:).call
    end

    def initialize(customer:, from:, to:)
      @customer = customer
      @from = from
      @to = to
    end

    def call
      assigned   = assigned_rows
      unassigned = unassigned_hours
      Result.new(rows: assigned, unassigned_hours: unassigned, total_hours: assigned.sum(&:hours) + unassigned)
    end

    private

    attr_reader :customer, :from, :to

    def assigned_rows
      ProjectCode
        .joins(tasks: :time_entries)
        .where(customer:, tasks: { billable: true }, time_entries: { date: from..to, invoice_id: nil })
        .group('project_codes.id')
        .select('project_codes.*, SUM(time_entries.hours) AS total_hours')
        .order(:code)
        .map { |project_code| Row.new(project_code:, hours: project_code.total_hours.to_d) }
    end

    def unassigned_hours
      TimeEntry
        .joins(:task)
        .where(tasks: { customer:, project_code_id: nil, billable: true }, date: from..to, invoice_id: nil)
        .sum(:hours)
    end
  end
end
