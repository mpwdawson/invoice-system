# frozen_string_literal: true

FactoryBot.define do
  factory :invoice_line do
    invoice
    sequence(:description) { |n| "Line #{n}" }
    sequence(:sort_order)
    line_type { "task" }

    trait :expense do
      line_type { "expense" }
      quantity { 1 }
      unit_price { 50.00 }
    end
  end
end
