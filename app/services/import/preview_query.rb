# frozen_string_literal: true

module Import
  class PreviewQuery
    Result     = Struct.new(:days, :new_tasks, keyword_init: true)
    DayPreview = Struct.new(:date, :stated_hours, :parsed_hours, :rows, keyword_init: true)
    Row        = Struct.new(:title, :ticket_refs, :hours, :matched_task,
                            :new_task_key, :duplicate, keyword_init: true)
    NewTask    = Struct.new(:key, :title, :ticket_refs, keyword_init: true)

    def self.call(customer:, text:) = new(customer:, text:).call

    def initialize(customer:, text:)
      @customer  = customer
      @text      = text
      @new_tasks = {}
    end

    def call
      days = Import::ParseLogService.call(text:).map { |day_log| build_day(day_log) }
      Result.new(days:, new_tasks: new_tasks.values)
    end

    private

    attr_reader :customer, :text, :new_tasks

    def build_day(day_log)
      rows = day_log.items.map { |item| build_row(item, date: day_log.date) }
      DayPreview.new(date: day_log.date, stated_hours: day_log.stated_hours,
                     parsed_hours: rows.filter_map(&:hours).sum, rows:)
    end

    def build_row(item, date:)
      matched_task = match_task(item)
      new_task_key = register_new_task(item) unless matched_task

      Row.new(title: item.title, ticket_refs: item.ticket_refs, hours: item.hours,
              matched_task:, new_task_key:,
              duplicate: matched_task.present? && TimeEntry.exists?(task: matched_task, date:))
    end

    def match_task(item)
      if item.ticket_refs.any?
        match_by_ticket_ref(item.ticket_refs)
      else
        match_by_title(item.title)
      end
    end

    def match_by_ticket_ref(ticket_refs)
      ticket_refs.each do |ref|
        ticket_reference = TicketReference.joins(:task)
          .find_by(prefix: ref[:prefix], number: ref[:number], tasks: { customer_id: customer.id })
        return ticket_reference.task if ticket_reference
      end
      nil
    end

    def match_by_title(title)
      customer.tasks.find_by('LOWER(title) = ?', title.downcase)
    end

    def register_new_task(item)
      key = new_task_key(item)
      new_tasks[key] ||= NewTask.new(key:, title: item.title, ticket_refs: item.ticket_refs)
      key
    end

    def new_task_key(item)
      if item.ticket_refs.any?
        item.ticket_refs.map { |ref| "#{ref[:prefix]}-#{ref[:number]}" }.sort.join('+')
      else
        item.title.downcase.strip
      end
    end
  end
end
