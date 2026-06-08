# frozen_string_literal: true

require 'rails_helper'

describe 'Invoice Lifecycle' do
  let(:customer) { create(:customer, name: 'Acme Corp') }
  let(:task)     { create(:task, customer:, title: 'Rewards Dashboard') }
  let(:entry)    { create(:time_entry, task:, date: Date.new(2026, 5, 12), hours: 4.0) }

  let(:invoice) do
    create(:invoice, customer:, status: 'ready', period_start: Date.new(2026, 5, 1), period_end: Date.new(2026, 5, 31),
                     total_hours: 4.0, total_amount: 380.00)
  end

  before do
    login
    create(:customer_rate, customer:, rate: 95.00, effective_from: Date.new(2026, 1, 1))
    create(:invoice_line, invoice:, description: 'Dashboard polish and bug fixes')
    entry.update!(invoice_id: invoice.id)
  end

  it 'marks an invoice sent then paid, and confirms its stamped entries show the soft-lock warning' do
    visit invoices_path

    expect(page).to have_text(invoice.invoice_number)
    expect(page).to have_text('Ready')

    click_on invoice.invoice_number

    expect(page).to have_text('Dashboard polish and bug fixes')
    expect(page).to have_text('Ready')

    accept_confirm do
      click_on 'Mark as Sent'
    end

    expect(page).to have_text('Sent:')
    expect(page).to have_button('Mark as Paid')
    expect(page).to have_no_button('Mark as Sent')

    reloaded = invoice.reload
    expect(reloaded.status).to eq('sent')
    expect(reloaded.sent_at).to be_present

    accept_confirm do
      click_on 'Mark as Paid'
    end

    expect(page).to have_text('Paid:')
    expect(page).to have_no_button('Mark as Paid')

    reloaded = invoice.reload
    expect(reloaded.status).to eq('paid')
    expect(reloaded.paid_at).to be_present

    visit edit_time_entry_path(entry)

    expect(page).to have_text('This entry is on a sent invoice')
  end
end
