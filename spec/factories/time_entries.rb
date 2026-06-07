# frozen_string_literal: true

FactoryBot.define do
  factory :time_entry do
    task
    date  { Date.current }
    hours { 1.0 }
  end
end
