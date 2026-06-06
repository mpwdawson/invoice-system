FactoryBot.define do
  factory :customer_rate do
    association :customer
    rate          { 150.00 }
    effective_from { Date.today }
  end
end
