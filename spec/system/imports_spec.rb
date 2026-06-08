# frozen_string_literal: true

require 'rails_helper'

describe 'Import' do
  let!(:customer)     { create(:customer, name: 'Acme Corp') }
  let!(:project_code) { create(:project_code, customer:, code: 'AW100', description: 'Main App') }

  before { login }

  it 'pastes a log, previews, assigns a project code, and commits the import' do
    visit new_import_path
    select customer.name, from: 'Customer'
    fill_in 'Pasted rows', with: "6/1/2026\t8\tAW-9001 New Feature Work (2)"
    click_button 'Preview'

    expect(page).to have_text('New Feature Work')
    expect(page).to have_text('new task')

    select 'AW100 — Main App', from: 'Project code'
    click_button 'Commit Import'

    expect(page).to have_text('1 time entries created')
    expect(page).to have_text('1 tasks created')

    task = Task.find_by(title: 'New Feature Work')
    expect(task.project_code).to eq(project_code)
    expect(task.time_entries.first.hours).to eq(2.0)
  end
end
