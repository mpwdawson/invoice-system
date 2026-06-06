# frozen_string_literal: true

FactoryBot.define do
  factory :contractor_profile do
    name  { 'Test Contractor' }
    email { 'contractor@example.com' }
  end
end
