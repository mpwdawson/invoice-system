# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    sequence(:name)           { |n| "Customer #{n}" }
    sequence(:invoice_prefix) { |n| "CUST#{n}" }
    requires_project_codes    { false }
  end
end
