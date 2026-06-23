# frozen_string_literal: true

require 'rails_helper'

describe 'Tasks' do
  let!(:customer) { create(:customer, name: 'Acme Corp') }

  before { login }

  it 'creates a task' do
    visit new_task_path
    fill_in 'Title', with: 'Design homepage'
    select customer.name, from: 'Customer'
    click_button 'Create Task'
    expect(page).to have_text('Design homepage')
  end

  it 'searches tasks by title' do
    create(:task, title: 'Design homepage', customer: customer)
    create(:task, title: 'Write tests', customer: customer)

    visit tasks_path
    fill_in 'Search', with: 'Design'
    click_button 'Filter'

    expect(page).to have_text('Design homepage')
    expect(page).to have_no_text('Write tests')
  end

  describe 'time entry actions on task show' do
    let(:task) { create(:task, title: 'Build feature', customer: customer) }

    it 'deletes an unbilled time entry' do
      create(:time_entry, task: task, date: Date.current, hours: 2.0)

      visit task_path(task)
      expect(page).to have_text('2.0h')

      accept_confirm('Delete this time entry?') do
        click_button 'Delete'
      end

      expect(page).to have_text('Entry deleted.')
      expect(page).to have_no_text('2.0h')
    end

    it 'shows billed badge instead of actions for billed entries' do
      create(:time_entry, task: task, date: Date.current, hours: 1.5, invoice_id: 99)

      visit task_path(task)
      expect(page).to have_text('billed')
      expect(page).to have_no_button('Reassign')
      expect(page).to have_no_button('Delete')
    end

    it 'reassigns a time entry to another task' do
      target_task = create(:task, title: 'Target task', customer: customer, status: 'active')
      create(:time_entry, task: task, date: Date.current, hours: 3.0)

      visit task_path(task)
      click_button 'Reassign'

      within('[data-time-entry-reassign-target="modal"]') do
        fill_in placeholder: 'Search tasks…', with: 'Target'
        find('[data-task-id]', wait: 5).click
        click_button 'Reassign'
      end

      expect(page).to have_text('reassigned')
      expect(page).to have_no_text('3.0h')
    end
  end
end
