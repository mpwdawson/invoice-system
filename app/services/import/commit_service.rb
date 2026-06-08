# frozen_string_literal: true

module Import
  class CommitService
    Result = Struct.new(:entries_created, :skipped_duplicates, :skipped_missing_hours,
                        :tasks_created, :tasks_matched, keyword_init: true)

    def self.call(customer:, text:, corrections: []) = new(customer:, text:, corrections:).call

    def initialize(customer:, text:, corrections: [])
      @customer       = customer
      @corrections    = corrections
      @preview        = Import::PreviewQuery.call(customer:, text:)
      @created_tasks  = {}
      @entries_created = @skipped_duplicates = @skipped_missing_hours = 0
    end

    def call
      ActiveRecord::Base.transaction do
        preview.days.each do |day|
          day.rows.each { |row| commit_row(row, date: day.date) }
        end
      end

      Result.new(entries_created:, skipped_duplicates:, skipped_missing_hours:,
                 tasks_created: created_tasks.size, tasks_matched: matched_task_count)
    end

    private

    attr_reader :customer, :corrections, :preview, :created_tasks,
                :entries_created, :skipped_duplicates, :skipped_missing_hours

    def commit_row(row, date:)
      task = row.matched_task || resolve_new_task(row)

      if row.hours.nil?
        @skipped_missing_hours += 1
      elsif TimeEntry.exists?(task:, date:)
        @skipped_duplicates += 1
      else
        TimeEntry.create!(task:, date:, hours: row.hours)
        @entries_created += 1
      end
    end

    def resolve_new_task(row)
      created_tasks[row.new_task_key] ||= create_task(row)
    end

    def create_task(row)
      task = Task.create!(customer:, title: row.title, project_code_id: corrected_project_code_id(row.new_task_key))
      row.ticket_refs.each { |ref| task.ticket_references.create!(prefix: ref[:prefix], number: ref[:number]) }
      task
    end

    def corrected_project_code_id(new_task_key)
      corrections.find { |correction| correction[:key] == new_task_key }&.dig(:project_code_id)
    end

    def matched_task_count
      preview.days.flat_map { |day| day.rows.filter_map(&:matched_task) }.uniq(&:id).size
    end
  end
end
