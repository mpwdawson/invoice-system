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
    click_on 'New Invoice'

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

  it 'selects tasks in step 3 and creates invoice lines' do
    invoice = create(:invoice, customer:, period_start: Date.new(2026, 5, 1),
                               period_end: Date.new(2026, 5, 31), wizard_current_step: 3)

    visit invoice_wizard_step_path(invoice, step: 3)

    expect(page).to have_text('Step 3 — Craft Lines')
    expect(page).to have_text('Rewards Dashboard')

    row = find('tr', text: 'Rewards Dashboard')
    within(row) { check(match: :first) }

    click_on 'Next'

    expect(invoice.invoice_lines.reload.count).to eq(1)
    expect(invoice.invoice_lines.first.description).to eq('Rewards Dashboard')
  end

  it 'previews the invoice and finalizes it' do
    invoice = create(:invoice, customer:, period_start: Date.new(2026, 5, 1),
                               period_end: Date.new(2026, 5, 31), wizard_current_step: 5)
    create(:invoice_line, invoice:, task:, description: 'Dashboard polish and bug fixes')

    visit invoice_wizard_step_path(invoice, step: 5)

    expect(page).to have_text('Step 5 — Preview')
    expect(page).to have_text(invoice.invoice_number)
    expect(page).to have_text('Dashboard polish and bug fixes')
    expect(page).to have_text('4.0h')
    expect(page).to have_text('$95.00/hr')
    expect(page).to have_text('$380.00')

    click_on 'Next'

    expect(page).to have_text('Step 6 — Finalize')

    accept_confirm do
      click_on 'Finalize Invoice'
    end

    expect(page).to have_text('Finalized — ready to send')

    reloaded = invoice.reload
    expect(reloaded.status).to eq('ready')
    expect(reloaded.total_hours).to eq(4.0)
    expect(reloaded.total_amount).to eq(380.00)

    entry = TimeEntry.find_by!(task:, date: Date.new(2026, 5, 12))
    expect(entry.invoice_id).to eq(invoice.id)
  end
end
