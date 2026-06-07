# frozen_string_literal: true

module Reports
  class TaskTotalsQuery
    Row    = Struct.new(:task, :hours, keyword_init: true)
    Result = Struct.new(:rows, :total_hours, keyword_init: true)

    def self.call(customer:, from:, to:, project_code: nil, status: nil, billable: nil)
      new(customer:, from:, to:, project_code:, status:, billable:).call
    end

    def initialize(customer:, from:, to:, project_code:, status:, billable:)
      @customer     = customer
      @from         = from
      @to           = to
      @project_code = project_code
      @status       = status
      @billable     = billable
    end

    def call
      rows = scoped_tasks
        .joins(:time_entries)
        .where(time_entries: { date: from..to })
        .group('tasks.id')
        .select('tasks.*, SUM(time_entries.hours) AS total_hours')
        .order('tasks.title')
        .map { |task| Row.new(task:, hours: task.total_hours.to_d) }

      Result.new(rows:, total_hours: rows.sum(&:hours))
    end

    private

    attr_reader :customer, :from, :to, :project_code, :status, :billable

    def scoped_tasks
      tasks = Task.where(customer:)
      tasks = tasks.where(project_code:) if project_code
      tasks = tasks.where(status:)       if status.present?
      tasks = tasks.where(billable:)     unless billable.nil?
      tasks
    end
  end
end
