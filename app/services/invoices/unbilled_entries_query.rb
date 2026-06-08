# frozen_string_literal: true

module Invoices
  class UnbilledEntriesQuery
    TaskGroup = Struct.new(:task, :hours, keyword_init: true)
    Result    = Struct.new(:task_groups, :total_hours, :already_billed_count, keyword_init: true)

    def self.call(customer:, from:, to:)
      new(customer:, from:, to:).call
    end

    def initialize(customer:, from:, to:)
      @customer = customer
      @from = from
      @to = to
    end

    def call
      groups = task_groups
      Result.new(task_groups: groups, total_hours: groups.sum(&:hours),
                 already_billed_count: already_billed_count)
    end

    private

    attr_reader :customer, :from, :to

    def task_groups
      customer.tasks.billable
        .joins(:time_entries)
        .where(time_entries: { date: from..to, invoice_id: nil })
        .group('tasks.id')
        .select('tasks.*, SUM(time_entries.hours) AS total_hours')
        .order(:title)
        .map { |task| TaskGroup.new(task:, hours: task.total_hours.to_d) }
    end

    def already_billed_count
      TimeEntry.joins(:task, :invoice)
        .where(tasks: { customer:, billable: true }, date: from..to)
        .where.not(invoices: { sent_at: nil })
        .count
    end
  end
end
