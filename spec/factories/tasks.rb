FactoryBot.define do
  factory :task do
    association :customer
    sequence(:title) { |n| "Task #{n}" }
    status  { "active" }
    billable { true }
  end
end
