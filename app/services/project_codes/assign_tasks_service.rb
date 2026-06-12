# frozen_string_literal: true

module ProjectCodes
  class AssignTasksService
    def self.call(project_code:, task_ids:)
      new(project_code:, task_ids:).call
    end

    def initialize(project_code:, task_ids:)
      @project_code = project_code
      @task_ids     = task_ids
    end

    def call
      return [] if task_ids.blank?

      tasks = Task.where(id: task_ids, customer: project_code.customer)
      tasks.each { |task| task.update!(project_code:) }
      tasks
    end

    private

    attr_reader :project_code, :task_ids
  end
end
