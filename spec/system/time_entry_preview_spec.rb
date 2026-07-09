# frozen_string_literal: true

require 'rails_helper'

describe 'Log Time preview' do
  before { login }

  let!(:task) { create(:task, title: 'Alpha task') }

  it 'shows the preview immediately after selecting a task, before hours are entered' do
    visit root_path
    fill_in placeholder: 'Search tasks…', with: 'Alpha'
    within('turbo-frame#task-search-results') { click_link 'Alpha task' }

    within('turbo-frame#time-entry-preview') do
      expect(page).to have_content('Alpha task')
      expect(page).to have_content('Enter hours to log this entry')
    end
  end

  it 'updates the preview once hours are typed after selecting a task' do
    visit root_path
    fill_in placeholder: 'Search tasks…', with: 'Alpha'
    within('turbo-frame#task-search-results') { click_link 'Alpha task' }
    fill_in 'time_entry[hours]', with: '2'

    within('turbo-frame#time-entry-preview') { expect(page).to have_content('Adding 2.0h') }
  end

  it 'shows the preview when hours are typed before selecting a task' do
    visit root_path
    fill_in 'time_entry[hours]', with: '2'
    fill_in placeholder: 'Search tasks…', with: 'Alpha'
    within('turbo-frame#task-search-results') { click_link 'Alpha task' }

    within('turbo-frame#time-entry-preview') { expect(page).to have_content('Adding 2.0h') }
  end

  context 'with hours already logged for that task today' do
    let!(:entry) { create(:time_entry, task:, date: Date.current, hours: 3) }

    it 'shows the existing total before new hours are entered' do
      visit root_path
      fill_in placeholder: 'Search tasks…', with: 'Alpha'
      within('turbo-frame#task-search-results') { click_link 'Alpha task' }

      within('turbo-frame#time-entry-preview') { expect(page).to have_content('Already 3.0h logged today') }
    end
  end
end
