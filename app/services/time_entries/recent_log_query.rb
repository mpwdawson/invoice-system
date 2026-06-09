# frozen_string_literal: true

module TimeEntries
  class RecentLogQuery
    Group = Struct.new(:date, :items, :total_hours, keyword_init: true)

    def self.call(days:, customer_id: nil, today: Date.current)
      new(days:, customer_id:, today:).call
    end

    def initialize(days:, customer_id: nil, today: Date.current)
      @days        = days
      @customer_id = customer_id
      @today       = today
    end

    def call
      range = (@today - (@days - 1))..@today
      scope = TimeEntry
        .includes(task: [:customer, :project_code])
        .where(date: range)
        .order(id: :asc)
      scope = scope.joins(:task).where(tasks: { customer_id: }) if customer_id.present?
      by_date = scope.group_by(&:date)

      range.to_a.reverse.map do |date|
        day_entries = by_date.fetch(date, [])
        Group.new(date:, items: day_entries, total_hours: day_entries.sum(&:hours))
      end
    end

    private

    attr_reader :days, :customer_id, :today
  end
end
