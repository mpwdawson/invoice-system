# frozen_string_literal: true

require 'rails_helper'

describe 'Daily Log Report' do
  let(:customer)       { create(:customer, name: 'Acme Corp') }
  let(:billed_task)    { create(:task, customer:, title: 'Billed work') }
  let(:unbilled_task)  { create(:task, customer:, title: 'Unbilled work') }

  before do
    login
    create(:time_entry, task: billed_task,   date: Date.current, hours: 2.0, invoice_id: 99)
    create(:time_entry, task: unbilled_task, date: Date.current, hours: 1.0)
  end

  it 'displays entries grouped by date with billed status and totals' do
    visit daily_log_report_path
    select 'Acme Corp', from: 'customer_id'
    click_on 'Run'

    expect(page).to have_text('Billed work')
    expect(page).to have_text('billed')
    expect(page).to have_text('Unbilled work')
    expect(page).to have_text('unbilled')
    expect(page).to have_text('3.0h')
  end
end
