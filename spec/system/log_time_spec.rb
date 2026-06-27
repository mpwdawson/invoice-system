# frozen_string_literal: true

require 'rails_helper'

describe 'Log Time' do
  before { login }

  describe 'inline edit' do
    let!(:task)  { create(:task) }
    let!(:entry) { create(:time_entry, task:, date: Date.current, hours: 1.0) }

    it 'shows hours and date inputs directly on the row with no separate Edit button' do
      visit root_path
      within("turbo-frame#time_entry_#{entry.id}") do
        expect(page).to have_css("input[data-time-entries--inline-edit-target='hours']")
        expect(page).to have_css("input[data-time-entries--inline-edit-target='date']")
        expect(page).to have_no_link(href: edit_time_entry_path(entry))
      end
    end

    it 'shows task title as a link to the task page' do
      visit root_path
      within("turbo-frame#time_entry_#{entry.id}") do
        expect(page).to have_link(task.title, href: task_path(task))
      end
    end

    it 'reveals the title input when the edit icon is clicked' do
      visit root_path
      row = find("turbo-frame#time_entry_#{entry.id}")
      row.hover
      row.find('[data-tasks--inline-edit-target="editButton"]').click
      expect(row).to have_css("input[data-tasks--inline-edit-target='input']:not(.hidden)")
    end
  end

  describe '+ Add entry button' do
    it 'pre-fills the date input with the selected day' do
      visit root_path

      target_date = 3.days.ago.to_date
      find("button[data-date='#{target_date}']").click

      expect(find("input[name='time_entry[date]']").value).to eq(target_date.to_s)
    end

    it 'updates the date when clicking a different day' do
      visit root_path

      find("button[data-date='#{2.days.ago.to_date}']").click
      find("button[data-date='#{5.days.ago.to_date}']").click

      expect(find("input[name='time_entry[date]']").value).to eq(5.days.ago.to_date.to_s)
    end
  end

  describe 'customer filter pills' do
    let!(:customer_a) { create(:customer, name: 'Acme Corp') }
    let!(:customer_b) { create(:customer, name: 'Globex Inc') }
    let!(:task_a)     { create(:task, customer: customer_a, title: 'Acme Task') }
    let!(:task_b)     { create(:task, customer: customer_b, title: 'Globex Task') }
    let!(:entry_a)    { create(:time_entry, task: task_a, date: Date.current, hours: 1) }
    let!(:entry_b)    { create(:time_entry, task: task_b, date: Date.current, hours: 2) }

    it 'shows all entries by default, filters to one customer, then shows all again on All' do
      visit root_path

      expect(page).to have_link('Acme Task')
      expect(page).to have_link('Globex Task')

      click_link 'Acme Corp'

      expect(page).to have_link('Acme Task')
      expect(page).to have_no_link('Globex Task')

      click_link 'All'

      expect(page).to have_link('Acme Task')
      expect(page).to have_link('Globex Task')
    end
  end
end
