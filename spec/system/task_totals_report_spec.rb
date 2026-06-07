# frozen_string_literal: true

require 'rails_helper'

describe 'Task Totals Report' do
  let(:customer)     { create(:customer, name: 'Acme Corp') }
  let(:project_code) { create(:project_code, customer:, code: 'AW') }
  let(:task)         { create(:task, customer:, project_code:, title: 'Build feature') }

  before do
    login
    create(:time_entry, task:, date: Date.current, hours: 4.0)
  end

  it 'displays per-task totals for the selected customer' do
    visit task_totals_report_path
    select 'Acme Corp', from: 'customer_id'
    click_on 'Run'

    expect(page).to have_text('Build feature')
    expect(page).to have_text('AW')
    expect(page).to have_text('4.0h')
  end
end
