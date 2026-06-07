# frozen_string_literal: true

class TimeEntry < ApplicationRecord
  belongs_to :task
  belongs_to :invoice, optional: true

  validates :date,  presence: true,
                    uniqueness: { scope: :task_id }
  validates :hours, presence: true,
                    numericality: { greater_than: 0 }
  validate :hours_multiple_of_half

  def self.log(task:, date:, hours:)
    entry = find_or_initialize_by(task: task, date: date)
    entry.hours = (entry.hours.to_d + hours.to_d)
    entry.save!
    entry
  end

  private

  def hours_multiple_of_half
    return if hours.blank?

    errors.add(:hours, 'must be a multiple of 0.5') unless (hours * 2).modulo(1).zero?
  end
end
