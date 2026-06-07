# frozen_string_literal: true

require 'rails_helper'

describe 'Log Time' do
  before { login }

  describe 'inline edit' do
    let!(:task)  { create(:task) }
    let!(:entry) { create(:time_entry, task:, date: Date.current, hours: 1.0) }

    it 'updates hours in place' do
      visit root_path
      find("a[href='#{edit_time_entry_path(entry)}']").click
      within("turbo-frame#time_entry_#{entry.id}") do
        fill_in 'time_entry[hours]', with: '2.5'
        click_on 'Save'
      end
      expect(page).to have_text('2.5h')
      expect(page).to have_no_css("turbo-frame#time_entry_#{entry.id} input[name='time_entry[hours]']")
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
end
