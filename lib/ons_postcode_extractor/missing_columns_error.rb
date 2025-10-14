# frozen_string_literal: true

module OnsPostcodeExtractor
  # Bespoke error raised if input data does not contain all requisite columns.
  # If raised, please consult README.
  class MissingColumnsError < StandardError
    def initialize(missing_columns)
      super("Missing required columns: #{Array(missing_columns).join(', ')}")
    end
  end
end
