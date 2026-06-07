# frozen_string_literal: true

module Reports
  class DailyLogQuery
    Entry  = Struct.new(:task, :hours, :billed, keyword_init: true)
    Day    = Struct.new(:date, :time_entries, :hours, keyword_init: true)
    Result = Struct.new(:days, :total_hours, keyword_init: true)

    def self.call(customer:, from:, to:)
      new(customer:, from:, to:).call
    end

    def initialize(customer:, from:, to:)
      @customer = customer
      @from     = from
      @to       = to
    end

    def call
      entries = scoped_entries
      days = entries.group_by(&:date).map do |date, day_entries|
        Day.new(date:, time_entries: day_entries.map { |entry| to_entry(entry) }, hours: day_entries.sum(&:hours))
      end
      Result.new(days:, total_hours: entries.sum(&:hours))
    end

    private

    attr_reader :customer, :from, :to

    def scoped_entries
      TimeEntry.joins(:task)
        .where(tasks: { customer: }, date: from..to)
        .includes(:task)
        .order(:date, 'tasks.title')
    end

    def to_entry(entry)
      Entry.new(task: entry.task, hours: entry.hours, billed: entry.invoice_id.present?)
    end
  end
end
