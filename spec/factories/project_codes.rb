FactoryBot.define do
  factory :project_code do
    association :customer
    sequence(:code) { |n| "CODE#{n}" }
    description     { "A project code" }
    active          { true }
  end
end
