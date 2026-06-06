# frozen_string_literal: true

class CustomerRate < ApplicationRecord
  belongs_to :customer

  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true

  def self.current_for(customer, date)
    where(customer: customer)
      .where(effective_from: ..date)
      .order(effective_from: :desc)
      .first
  end
end
