# frozen_string_literal: true

class InvoiceLine < ApplicationRecord
  belongs_to :invoice

  before_validation :normalize_task_ids

  validates :description, presence: true

  private

  def normalize_task_ids
    self.task_ids = Array(task_ids).map(&:to_i).reject(&:zero?) if task_ids.present?
  end
end
