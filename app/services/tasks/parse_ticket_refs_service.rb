# frozen_string_literal: true

module Tasks
  class ParseTicketRefsService
    def self.call(input:)
      new(input:).call
    end

    def initialize(input:)
      @input = input.to_s
    end

    def call
      input.scan(/([A-Za-z]+)-(\d+)/)
        .map { |prefix, number| { prefix: prefix.upcase, number: number.to_i } }
        .uniq
    end

    private

    attr_reader :input
  end
end
