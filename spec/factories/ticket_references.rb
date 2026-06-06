# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_reference do
    task
    prefix { 'AW' }
    sequence(:number) { |n| 6770 + n }
  end
end
