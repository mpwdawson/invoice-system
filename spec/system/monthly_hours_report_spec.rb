# frozen_string_literal: true

require 'rails_helper'

describe 'Monthly Hours Report' do
  let(:customer)     { create(:customer, name: 'Acme Corp') }
  let(:project_code) { create(:project_code, customer:, code: 'AW', description: 'Acme Work') }
  let(:task_with_pc) { create(:task, customer:, project_code:) }
  let(:task_no_pc)   { create(:task, customer:) }

  before do
    login
    create(:time_entry, task: task_with_pc, date: Date.current, hours: 3.0)
    create(:time_entry, task: task_no_pc,   date: Date.current, hours: 1.5)
  end

  it 'displays project code breakdown and grand total' do
    visit monthly_hours_report_path
    select 'Acme Corp', from: 'customer_id'
    click_on 'Run'

    expect(page).to have_text('AW')
    expect(page).to have_text('3.0h')
    expect(page).to have_text('unassigned')
    expect(page).to have_text('1.5h')
    expect(page).to have_text('4.5h')
  end
end
