# frozen_string_literal: true

require 'csv'
require 'json'

# Core module for the ONS Postcode Extractor CLI tool
module OnsPostcodeExtractor
  VERSION = '0.1.0'

  # Require the library files
  require_relative 'ons_postcode_extractor/cli'
  require_relative 'ons_postcode_extractor/processor'
  require_relative 'ons_postcode_extractor/town_lookup'
  require_relative 'ons_postcode_extractor/local_authority_lookup'
  require_relative 'ons_postcode_extractor/missing_columns_error'
end
