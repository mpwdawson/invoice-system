# frozen_string_literal: true

class InvoiceLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :task, optional: true

  validates :description, presence: true
  validates :line_type, inclusion: { in: %w[task expense] }
  validates :quantity, :unit_price, presence: true, if: :expense?
  validates :quantity, :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :tasks,    -> { where(line_type: "task") }
  scope :expenses, -> { where(line_type: "expense") }

  def expense? = line_type == "expense"
  def line_total = (quantity || BigDecimal("0")) * (unit_price || BigDecimal("0"))
end
