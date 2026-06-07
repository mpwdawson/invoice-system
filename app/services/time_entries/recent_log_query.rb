# frozen_string_literal: true

module TimeEntries
  class RecentLogQuery
    Group = Struct.new(:date, :items, :total_hours, keyword_init: true)

    def self.call(days:)
      new(days:).call
    end

    def initialize(days:)
      @days = days
    end

    def call
      range = (Date.current - (@days - 1))..Date.current
      by_date = TimeEntry
        .includes(task: [:customer, :project_code])
        .where(date: range)
        .group_by(&:date)

      range.to_a.reverse.map do |date|
        day_entries = by_date.fetch(date, [])
        Group.new(date:, items: day_entries, total_hours: day_entries.sum(&:hours))
      end
    end

    private

    attr_reader :days
  end
end
