# frozen_string_literal: true

FactoryBot.define do
  factory :customer_rate do
    customer
    rate { 150.00 }
    effective_from { Time.zone.today }
  end
end
