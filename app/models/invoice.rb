# frozen_string_literal: true

class Invoice < ApplicationRecord
  SEQUENCE_SEED = 316

  VALID_TRANSITIONS = {
    'draft' => 'ready',
    'ready' => 'sent',
    'sent' => 'paid'
  }.freeze

  belongs_to :customer, optional: true
  has_many :invoice_lines, -> { order(:sort_order) }, inverse_of: :invoice, dependent: :destroy

  enum :status, { draft: 'draft', ready: 'ready', sent: 'sent', paid: 'paid' }, default: 'draft'

  before_validation :assign_sequence_number, on: :create
  before_save :assign_current_rate, if: -> { customer_id_changed? || period_start_changed? }

  validates :sequence_number, presence: true, uniqueness: true
  validate :status_transition_must_be_legal, if: :status_changed?

  def self.next_sequence_number
    transaction { (maximum(:sequence_number) || (SEQUENCE_SEED - 1)) + 1 }
  end

  def invoice_number
    padded = sequence_number.to_s.rjust(4, '0')
    customer&.invoice_prefix.present? ? "#{customer.invoice_prefix}-#{padded}" : padded
  end

  private

  def assign_sequence_number
    self.sequence_number ||= self.class.next_sequence_number
  end

  def assign_current_rate
    self.rate = CustomerRate.current_for(customer, period_start)&.rate if customer && period_start
  end

  def status_transition_must_be_legal
    return if new_record? || VALID_TRANSITIONS[status_was] == status

    errors.add(:status, "cannot transition from #{status_was} to #{status}")
  end
end
