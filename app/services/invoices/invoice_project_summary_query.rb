# frozen_string_literal: true

module Invoices
  class InvoiceProjectSummaryQuery
    Row    = Struct.new(:project_code, :hours, keyword_init: true)
    Result = Struct.new(:rows, :unassigned_hours, :total_hours, keyword_init: true)

    def self.call(invoice:)
      new(invoice:).call
    end

    def initialize(invoice:)
      @invoice = invoice
    end

    def call
      assigned   = assigned_rows
      unassigned = unassigned_hours
      Result.new(rows: assigned, unassigned_hours: unassigned, total_hours: assigned.sum(&:hours) + unassigned)
    end

    private

    attr_reader :invoice

    def stamped_entries
      TimeEntry.joins(:task).where(invoice_id: invoice.id)
    end

    def assigned_rows
      ProjectCode
        .joins(tasks: :time_entries)
        .where(time_entries: { invoice_id: invoice.id })
        .group("project_codes.id")
        .select("project_codes.*, SUM(time_entries.hours) AS total_hours")
        .order(:code)
        .map { |project_code| Row.new(project_code:, hours: project_code.total_hours.to_d) }
    end

    def unassigned_hours
      stamped_entries
        .where(tasks: { project_code_id: nil })
        .sum(:hours)
    end
  end
end
