# frozen_string_literal: true

require 'rails_helper'

describe 'Ticket References', :js do
  let(:task) { create(:task) }

  before do
    login
    visit task_path(task)
  end

  it 'adds ticket references via bulk input' do
    fill_in 'input', with: 'AW-6770 & AW-6771'
    click_button 'Add'
    expect(page).to have_text('AW-6770')
    expect(page).to have_text('AW-6771')
  end

  it 'removes a ticket reference' do
    fill_in 'input', with: 'AW-6770 & AW-6771'
    click_button 'Add'
    expect(page).to have_text('AW-6770')

    find('a[aria-label="Remove AW-6770"]').click

    expect(page).to have_no_text('AW-6770')
    expect(page).to have_text('AW-6771')
  end
end
