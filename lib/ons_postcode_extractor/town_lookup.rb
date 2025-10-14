# frozen_string_literal: true

require 'uk_postcode'
require_relative '../../data/towns_outward_postcode_matchers'
require_relative '../../data/towns_shared_outward_postcode_matchers'

module OnsPostcodeExtractor
  # Class that assigns a post town value to a postcode
  class TownLookup
    def initialize
      @cache = {}
    end

    def find_town(postcode_string)
      @parsed_postcode = UKPostcode.parse(postcode_string)
      return invalid_postcode_warning unless @parsed_postcode.valid? && @parsed_postcode.full?
      return @cache[@parsed_postcode.outcode] if @cache[@parsed_postcode.outcode]

      outcode_result = town_from_outcode(@parsed_postcode.outcode)

      return town_from_shared_outcode if outcode_result == 'Shared'

      @cache[@parsed_postcode.outcode] = outcode_result
      outcode_result
    end

    def town_from_shared_outcode
      matches = TownsSharedOutwardPostcodeMatchers::SHARED_TOWN_DATA.map do |town, regex|
        town if @parsed_postcode.to_s.gsub(' ', '').match?(regex)
      end.compact

      return unknown_outcode(outcode) if matches.none?
      return matches.first if matches.length == 1

      multiple_matches
    end

    def town_from_outcode(outcode)
      @compiled_regexes ||= TownsdOutwardPostcodeMatchers::TOWN_DATA.transform_values { |r| Regexp.new(r) }
      @compiled_regexes.each do |name, regex|
        return name if outcode.match?(regex)
      end
      unknown_outcode(outcode)
    end

    def invalid_postcode_warning
      puts "⛔️ Postcode Failed Validation: #{@parsed_postcode}. Check data."
      :invalid_postcode
    end

    def unknown_outcode(outcode)
      puts "⚠️ Outcode #{outcode} not found. Regex data may need to be updated."
      :unknown_outcode
    end

    def multiple_matches
      puts "⚠️ Multiple possible matches for #{postcode_string}. Regex data may need to be updated."
      :multiple_possible_matches
    end
  end
end
