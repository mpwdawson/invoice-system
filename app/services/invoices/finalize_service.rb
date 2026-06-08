# frozen_string_literal: true

module Invoices
  class FinalizeService
    Result = Struct.new(:invoice, :errors, keyword_init: true) do
      def success? = errors.empty?
    end

    def self.call(invoice:)
      new(invoice:).call
    end

    def initialize(invoice:)
      @invoice = invoice
    end

    def call
      return Result.new(invoice:, errors: [missing_project_codes_message]) if blocked_by_missing_project_codes?

      ActiveRecord::Base.transaction do
        hours = billable_entries.sum(:hours)
        billable_entries.find_each { |entry| entry.update!(invoice_id: invoice.id) }
        invoice.update!(status: 'ready', total_hours: hours, total_amount: hours * invoice.rate, wizard_current_step: 6)
      end
      Result.new(invoice:, errors: [])
    end

    private

    attr_reader :invoice

    def billable_entries
      TimeEntry.joins(:task)
        .where(tasks: { customer: invoice.customer, billable: true })
        .where(date: invoice.period_start..invoice.period_end, invoice_id: nil)
    end

    def blocked_by_missing_project_codes?
      invoice.customer.requires_project_codes? &&
        Task.exists?(id: billable_entries.select(:task_id), project_code_id: nil)
    end

    def missing_project_codes_message
      'All billable tasks in this period need a project code before the invoice can be finalized.'
    end
  end
end
