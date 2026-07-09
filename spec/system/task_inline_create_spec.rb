# frozen_string_literal: true

require 'rails_helper'

describe 'Task inline create from search' do
  before { login }

  let!(:task) { create(:task, title: 'Alpha task') }

  it 'cancels back to the search results without creating a task' do
    visit root_path
    fill_in placeholder: 'Search tasks…', with: 'Brand new task'

    within('turbo-frame#task-search-results') { click_link 'Create "Brand new task"' }
    expect(page).to have_field('task_title', with: 'Brand new task')

    expect { click_link 'Cancel' }.not_to change(Task, :count)

    within('turbo-frame#task-search-results') do
      expect(page).to have_content('Create "Brand new task"')
      expect(page).to have_no_field('task_title')
    end
  end
end
