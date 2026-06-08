# frozen_string_literal: true

module Import
  class ParseLogService
    DayLog      = Struct.new(:date, :stated_hours, :items, keyword_init: true)
    ParsedEntry = Struct.new(:title, :ticket_refs, :hours, keyword_init: true)

    HOURS_PATTERN         = /\(\s*(\d+(?:\.\d+)?)\s*\)\s*\z/
    TICKET_PREFIX_PATTERN = /\A(?:[A-Za-z]+-(?:\d+|\*)\s*(?:&\s*)?)+\s*/

    def self.call(text:) = new(text:).call

    def initialize(text:)
      @text = text.to_s
    end

    def call
      text.each_line.filter_map { |line| parse_row(line) }
    end

    private

    attr_reader :text

    def parse_row(line)
      date_str, stated_hours_str, notes = line.split("\t", 3)
      date = parse_date(date_str)
      return unless date

      DayLog.new(date:, stated_hours: stated_hours_str.to_s.to_d, items: parse_entries(notes))
    end

    def parse_date(str)
      Date.strptime(str.to_s.strip, '%m/%d/%Y')
    rescue ArgumentError
      nil
    end

    def parse_entries(notes)
      notes.to_s.split(',').filter_map { |chunk| parse_entry(chunk.strip) }
    end

    def parse_entry(chunk)
      return if chunk.blank?

      hours_match = chunk.match(HOURS_PATTERN)
      body  = hours_match ? chunk[0...hours_match.begin(0)].strip : chunk
      title = body.sub(TICKET_PREFIX_PATTERN, '').strip

      ParsedEntry.new(title:, ticket_refs: Tasks::ParseTicketRefsService.call(input: body),
                      hours: hours_match&.[](1)&.to_d)
    end
  end
end
