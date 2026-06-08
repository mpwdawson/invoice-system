# frozen_string_literal: true

require 'rails_helper'

describe 'Invoice Wizard' do
  let(:customer) { create(:customer, name: 'Acme Corp') }
  let(:task)     { create(:task, customer:, title: 'Rewards Dashboard') }

  before do
    login
    create(:customer_rate, customer:, rate: 95.00, effective_from: Date.new(2026, 1, 1))
    create(:time_entry, task:, date: Date.new(2026, 5, 12), hours: 4.0)
  end

  it 'picks a customer + period, sees the rate populate, and reviews un-billed entries' do
    visit root_path
    click_on 'Invoices'

    expect(page).to have_text('1. Customer + Date Range')
    expect(page).to have_text('Step 1 — Customer + Date Range')

    select 'Acme Corp', from: 'invoice_customer_id'
    fill_in 'invoice_period_start', with: '2026-05-01'
    fill_in 'invoice_period_end', with: '2026-05-31'
    click_on 'Next'

    expect(page).to have_text('Step 2 — Review Entries')
    expect(page).to have_text('Rewards Dashboard')
    expect(page).to have_text('4.0h')

    invoice = Invoice.last
    expect(invoice.customer).to eq(customer)
    expect(invoice.period_start).to eq(Date.new(2026, 5, 1))
    expect(invoice.period_end).to eq(Date.new(2026, 5, 31))
    expect(invoice.rate).to eq(95.00)
    expect(invoice.wizard_current_step).to eq(2)

    click_on 'Back'

    expect(page).to have_text('Step 1 — Customer + Date Range')
    expect(page).to have_text('$95.00/hr')
  end
end
