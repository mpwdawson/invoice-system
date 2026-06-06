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
end
