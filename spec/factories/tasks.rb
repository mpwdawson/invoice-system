# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    customer
    sequence(:title) { |n| "Task #{n}" }
    status { 'active' }
    billable { true }
  end
end
