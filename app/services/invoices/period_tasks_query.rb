# frozen_string_literal: true

module Invoices
  class PeriodTasksQuery
    SORT_COLUMNS = {
      "title" => "tasks.title",
      "hours" => "period_hours",
      "date"  => "latest_date"
    }.freeze

    DEFAULT_DIRECTIONS = { "title" => "asc", "hours" => "desc", "date" => "desc" }.freeze

    def self.call(customer:, from:, to:, sort: "title_asc")
      new(customer:, from:, to:, sort:).call
    end

    def initialize(customer:, from:, to:, sort: "title_asc")
      @customer = customer
      @from = from
      @to = to
      @sort_key, @sort_dir = parse_sort(sort)
    end

    def call
      Task.joins(:time_entries)
          .where(customer: @customer, billable: true,
                 time_entries: { date: @from..@to, invoice_id: nil })
          .group("tasks.id")
          .select("tasks.*, SUM(time_entries.hours) AS period_hours, MAX(time_entries.date) AS latest_date")
          .order(Arel.sql("#{SORT_COLUMNS[@sort_key]} #{@sort_dir}"))
    end

    private

    def parse_sort(sort)
      key, dir = sort.to_s.match(/\A(title|hours|date)_(asc|desc)\z/)&.captures
      key ||= "title"
      dir ||= DEFAULT_DIRECTIONS[key]
      [key, dir]
    end
  end
end
