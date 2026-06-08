# frozen_string_literal: true

require 'rails_helper'

describe Import::CommitService do
  subject { described_class.call(customer:, text:, corrections:) }

  let(:customer)    { create(:customer) }
  let(:corrections) { [] }
  let(:date_str)    { '6/1/2026' }
  let(:notes)       { '' }
  let(:text)        { "#{date_str}\t11\t#{notes}" }

  context 'when an item matches an existing task' do
    let!(:task) { create(:task, customer:, title: 'QA Support') }
    let(:notes) { 'QA Support (0.5)' }

    it 'creates a time entry on the matched task' do
      expect { subject }.to change(TimeEntry, :count).by(1)
      expect(task.reload.time_entries.first.hours).to eq(0.5)
    end

    it 'does not create a new task' do
      expect { subject }.not_to change(Task, :count)
    end

    it 'reports one matched task, zero created' do
      result = subject
      expect(result.tasks_matched).to eq(1)
      expect(result.tasks_created).to eq(0)
    end
  end

  context 'when no existing task matches' do
    let(:notes) { 'AW-9001 Brand New Work Item (2)' }

    it 'creates a task and a time entry for it' do
      expect { subject }.to change(Task, :count).by(1).and change(TimeEntry, :count).by(1)
    end

    it 'creates the task with the parsed title under the chosen customer' do
      subject
      task = Task.last
      expect(task.title).to eq('Brand New Work Item')
      expect(task.customer).to eq(customer)
    end

    it 'creates ticket references for the new task' do
      subject
      refs = Task.last.ticket_references
      expect(refs.map { |r| [r.prefix, r.number] }).to eq([['AW', 9001]])
    end

    it 'leaves the project code blank when no correction is supplied' do
      subject
      expect(Task.last.project_code_id).to be_nil
    end

    it 'reports one created task, zero matched' do
      result = subject
      expect(result.tasks_created).to eq(1)
      expect(result.tasks_matched).to eq(0)
    end
  end

  context 'when the same untracked title appears across multiple days' do
    let(:text) do
      [
        "6/1/2026\t8\tQA Support (0.5)",
        "6/2/2026\t8\tQA Support (1)"
      ].join("\n")
    end

    it 'creates exactly one task shared by both entries' do
      expect { subject }.to change(Task, :count).by(1).and change(TimeEntry, :count).by(2)
      expect(Task.last.time_entries.count).to eq(2)
    end

    it 'reports a single created task' do
      expect(subject.tasks_created).to eq(1)
    end
  end

  context 'when a project code correction is supplied for a new task' do
    let!(:project_code) { create(:project_code, customer:) }
    let(:notes)         { 'Brand New Work Item (2)' }
    let(:corrections)   { [{ key: 'brand new work item', project_code_id: project_code.id }] }

    it 'assigns the corrected project code to the created task' do
      subject
      expect(Task.last.project_code).to eq(project_code)
    end
  end

  context 'when a TimeEntry already exists for [task, date]' do
    let!(:task)       { create(:task, customer:, title: 'QA Support') }
    let!(:time_entry) { create(:time_entry, task:, date: Date.new(2026, 6, 1), hours: 1.0) }
    let(:notes)       { 'QA Support (0.5)' }

    it 'does not create a duplicate time entry' do
      expect { subject }.not_to change(TimeEntry, :count)
    end

    it 'reports the skipped duplicate and no created entries' do
      result = subject
      expect(result.skipped_duplicates).to eq(1)
      expect(result.entries_created).to eq(0)
    end
  end

  context 'when an item has no hours marker' do
    let(:notes) { 'Open-ended planning discussion' }

    it 'still creates the matched/new task' do
      expect { subject }.to change(Task, :count).by(1)
    end

    it 'skips creating a time entry' do
      expect { subject }.not_to change(TimeEntry, :count)
    end

    it 'reports the skipped missing-hours row and no created entries' do
      result = subject
      expect(result.skipped_missing_hours).to eq(1)
      expect(result.entries_created).to eq(0)
    end
  end

  context 'with a mixed batch of matched, new, duplicate and missing-hours items' do
    let!(:matched_task) { create(:task, customer:, title: 'QA Support') }
    let(:text) do
      [
        "6/1/2026\t10\tQA Support (1), Brand New Work Item (2)",
        "6/2/2026\t10\tBrand New Work Item (1.5)"
      ].join("\n")
    end

    it 'reports accurate combined counts' do
      result = subject
      expect(result.entries_created).to eq(3)
      expect(result.tasks_matched).to eq(1)
      expect(result.tasks_created).to eq(1)
      expect(result.skipped_duplicates).to eq(0)
      expect(result.skipped_missing_hours).to eq(0)
    end
  end
end
