# frozen_string_literal: true

require 'rails_helper'

describe 'ProjectCodes' do
  let(:customer) { create(:customer) }

  before { login }

  it 'creates a project code' do
    visit new_customer_project_code_path(customer)
    fill_in 'Code', with: 'DSNSERV'
    fill_in 'Description', with: 'Design Services'
    click_button 'Create Project code'
    expect(page).to have_text('DSNSERV')
  end

  describe 'bulk CSV import' do
    it 'imports project codes from pasted CSV and shows them in the list' do
      visit customer_project_codes_path(customer)

      click_link 'Import CSV'

      expect(page).to have_css('textarea')

      fill_in 'csv_text', with: "Project Code,Description\nFRICTION,Territory Assignment\nAIFIRST,AI Initiative"

      click_button 'Import'

      expect(page).to have_text('FRICTION')
      expect(page).to have_text('Territory Assignment')
      expect(page).to have_text('AIFIRST')
      expect(page).to have_text('AI Initiative')
      expect(page).to have_text('2 created')
    end

    it 'disables the Import button when the textarea is empty' do
      visit customer_project_codes_path(customer)
      click_link 'Import CSV'

      expect(page).to have_button('Import', disabled: true)

      fill_in 'csv_text', with: "Project Code,Description\nFRICTION,Territory Assignment"

      expect(page).to have_button('Import', disabled: false)
    end
  end
end
