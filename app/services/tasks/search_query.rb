# frozen_string_literal: true

module Tasks
  class SearchQuery
    SORT_COLUMNS = {
      'title'        => 'tasks.title',
      'customer'     => 'customers.name',
      'project_code' => 'project_codes.code',
      'created_at'   => 'tasks.created_at'
    }.freeze

    def self.call(query:, customer_id: nil, project_code_id: nil, date_from: nil,
                  status: 'active', billable: nil, sort: nil, direction: nil)
      new(query:, customer_id:, project_code_id:, date_from:,
          status:, billable:, sort:, direction:).call
    end

    def initialize(query:, customer_id: nil, project_code_id: nil, date_from: nil,
                   status: 'active', billable: nil, sort: nil, direction: nil)
      @query           = query.to_s.strip
      @customer_id     = customer_id
      @project_code_id = project_code_id
      @date_from       = date_from
      @status          = status
      @billable        = billable
      @sort            = sort
      @direction       = direction
    end

    def call
      scope = Task.includes(:customer, :project_code, :ticket_references)
      scope = scope.where(customer_id:)     if customer_id.present?
      scope = scope.where(project_code_id:) if project_code_id.present?
      scope = scope.where(status: status.presence || 'active')
      scope = scope.where(billable: true)   if billable.present?
      scope = scope.where('tasks.created_at >= ?', parsed_date_from.beginning_of_day) if parsed_date_from
      scope = apply_search(scope) if query.present?
      apply_sort(scope)
    end

    private

    attr_reader :query, :customer_id, :project_code_id, :date_from,
                :status, :billable, :sort, :direction

    def apply_search(scope)
      term = "%#{query}%"
      scope.left_joins(:ticket_references)
        .where(
          "tasks.title LIKE :term OR UPPER(ticket_references.prefix || '-' || ticket_references.number) LIKE UPPER(:term)",
          term:
        )
        .distinct
    end

    def apply_sort(scope)
      column = SORT_COLUMNS[sort]
      return scope.order('tasks.title ASC') unless column

      dir = direction == 'desc' ? 'DESC' : 'ASC'

      case sort
      when 'customer'     then scope.joins(:customer).order("#{column} #{dir}")
      when 'project_code' then scope.left_joins(:project_code).order("#{column} #{dir}, tasks.title ASC")
      else                     scope.order("#{column} #{dir}")
      end
    end

    def parsed_date_from
      return nil if date_from.blank?

      Date.parse(date_from.to_s)
    rescue ArgumentError
      nil
    end
  end
end
