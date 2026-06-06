# frozen_string_literal: true

class TicketReference < ApplicationRecord
  belongs_to :task

  validates :prefix, :number, presence: true
  validates :number, uniqueness: { scope: [:task_id, :prefix] }

  def to_s = "#{prefix}-#{number}"
end
