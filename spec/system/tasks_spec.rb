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
end
