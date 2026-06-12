# frozen_string_literal: true

require 'rails_helper'

describe ProjectCodes::AssignTasksService do
  subject { described_class.call(project_code:, task_ids:) }

  let(:customer)     { create(:customer) }
  let(:project_code) { create(:project_code, customer:) }

  context "assigning unassigned tasks" do
    let(:task)     { create(:task, customer:, project_code: nil) }
    let(:task_ids) { [task.id] }

    it "assigns the task to the project code" do
      subject
      expect(task.reload.project_code).to eq(project_code)
    end
  end

  context "reassigning a task from another project code" do
    let(:other_code) { create(:project_code, customer:) }
    let(:task)       { create(:task, customer:, project_code: other_code) }
    let(:task_ids)   { [task.id] }

    it "reassigns the task to the new project code" do
      subject
      expect(task.reload.project_code).to eq(project_code)
    end
  end

  context "with task_ids from a different customer" do
    let(:other_task) { create(:task) }
    let(:task_ids)   { [other_task.id] }

    it "ignores tasks from other customers" do
      subject
      expect(other_task.reload.project_code).to be_nil
    end
  end

  context "with an empty task_ids list" do
    let(:task_ids) { [] }

    it "assigns nothing and does not raise" do
      expect { subject }.not_to raise_error
    end
  end
end
