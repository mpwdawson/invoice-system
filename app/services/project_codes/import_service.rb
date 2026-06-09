# frozen_string_literal: true

require 'csv'

module ProjectCodes
  class ImportService
    Result = Struct.new(:created, :skipped, :errors, keyword_init: true)

    def self.call(customer:, csv_text:)
      new(customer:, csv_text:).call
    end

    def initialize(customer:, csv_text:)
      @customer = customer
      @csv_text = csv_text
    end

    def call
      created = []
      skipped = []
      errors  = []

      parsed_rows.each do |row|
        code        = row['Project Code']&.strip&.upcase
        description = row['Description']&.strip
        next if code.blank?

        if customer.project_codes.exists?(code:)
          skipped << code
        else
          pc = customer.project_codes.build(code:, description:)
          if pc.save
            created << code
          else
            errors << "#{code}: #{pc.errors.full_messages.join(', ')}"
          end
        end
      end

      Result.new(created:, skipped:, errors:)
    end

    private

    attr_reader :customer, :csv_text

    def parsed_rows
      CSV.parse(csv_text.to_s.strip, headers: true)
    rescue CSV::MalformedCSVError
      []
    end
  end
end
