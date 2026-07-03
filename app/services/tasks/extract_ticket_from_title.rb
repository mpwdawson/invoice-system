# frozen_string_literal: true

module Tasks
  class ExtractTicketFromTitle
    PATTERN = /\A((?:AW|IA|QAD)-\d+)\s*/i

    Result = Struct.new(:title, :ticket_ref, keyword_init: true)

    def self.call(title:)
      new(title:).call
    end

    def initialize(title:)
      @raw_title = title.to_s
    end

    def call
      stripped = raw_title.strip
      match = stripped.match(PATTERN)
      if match
        Result.new(title: stripped.sub(PATTERN, "").strip, ticket_ref: match[1].upcase)
      else
        Result.new(title: stripped, ticket_ref: nil)
      end
    end

    private

    attr_reader :raw_title
  end
end
