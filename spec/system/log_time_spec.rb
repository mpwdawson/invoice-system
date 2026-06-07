# frozen_string_literal: true

require 'rails_helper'

describe 'Log Time' do
  before { login }

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
