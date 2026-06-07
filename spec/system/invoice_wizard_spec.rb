# frozen_string_literal: true

require 'rails_helper'

describe 'Invoice Wizard' do
  before { login }

  it 'starts a draft invoice, advances through steps, and persists progress on reload' do
    visit root_path
    click_on 'Invoices'

    expect(page).to have_text('1. Customer + Date Range')
    expect(page).to have_text('Step 1 — Customer + Date Range')

    click_on 'Next'

    expect(page).to have_text('Step 2 — Review Entries')

    invoice = Invoice.last
    expect(invoice.wizard_current_step).to eq(2)

    visit invoice_wizard_step_path(invoice, step: 2)

    expect(page).to have_text('Step 2 — Review Entries')
  end
end
