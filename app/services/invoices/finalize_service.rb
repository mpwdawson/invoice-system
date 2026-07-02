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
      ActiveRecord::Base.transaction do
        hours = billable_entries.sum(:hours)
        task_hours = billable_entries.group(:task_id).sum(:hours)
        billable_entries.find_each { |entry| entry.update!(invoice_id: invoice.id) }
        snapshot_line_quantities(task_hours)
        expense_total = invoice.invoice_lines.expenses.sum(&:line_total)
        total_amount = (hours * invoice.rate) + expense_total
        invoice.update!(status: 'ready', total_hours: hours, total_amount: total_amount, wizard_current_step: 6)
      end
      Result.new(invoice:, errors: [])
    end

    private

    attr_reader :invoice

    def snapshot_line_quantities(task_hours)
      invoice.invoice_lines.tasks.find_each do |line|
        line.update!(quantity: task_hours[line.task_id] || 0, unit_price: invoice.rate)
      end
    end

    def billable_entries
      TimeEntry.joins(:task)
        .where(tasks: { customer: invoice.customer, billable: true })
        .where(date: invoice.period_start..invoice.period_end, invoice_id: nil)
    end
  end
end
