# frozen_string_literal: true

FactoryBot.define do
  factory :project_code do
    customer
    sequence(:code) { |n| "CODE#{n}" }
    description     { 'A project code' }
    active          { true }
  end
end
