# frozen_string_literal: true

module Tasks
  class SearchQuery
    def self.call(query:, customer_id: nil, status: 'active', billable: nil)
      new(query:, customer_id:, status:, billable:).call
    end

    def initialize(query:, customer_id: nil, status: 'active', billable: nil)
      @query       = query.to_s.strip
      @customer_id = customer_id
      @status      = status
      @billable    = billable
    end

    def call
      scope = Task.includes(:customer, :project_code, :ticket_references).ordered
      scope = scope.where(customer_id:) if customer_id.present?
      scope = scope.where(status: status.presence || 'active')
      scope = scope.where(billable: true) if billable.present?
      scope = apply_search(scope) if query.present?
      scope
    end

    private

    attr_reader :query, :customer_id, :status, :billable

    def apply_search(scope)
      term = "%#{query}%"
      scope.left_joins(:ticket_references)
        .where(
          "tasks.title LIKE :term OR UPPER(ticket_references.prefix || '-' || ticket_references.number) LIKE UPPER(:term)",
          term:
        )
        .distinct
    end
  end
end
