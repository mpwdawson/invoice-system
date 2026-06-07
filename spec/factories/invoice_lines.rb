# frozen_string_literal: true

FactoryBot.define do
  factory :invoice_line do
    invoice
    sequence(:description) { |n| "Line #{n}" }
    sequence(:sort_order)
  end
end
