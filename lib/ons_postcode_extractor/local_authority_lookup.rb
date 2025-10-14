# frozen_string_literal: true
require_relative '../../data/local_authorities'

module OnsPostcodeExtractor
  # Class that assigns a local authority value to a postcode
  class LocalAuthorityLookup
    def self.name_for(ons_reference)
      authority_name = LocalAuthorities::LOCAL_AUTHORITY_DATA[ons_reference]

      authority_name.nil? ? unknown_authority_warning(ons_reference) : authority_name
    end

    def self.unknown_authority_warning(ons_reference)
      binding.pry
      puts "⚠️ LAD25CD #{ons_reference} not found. List of references may need to be updated."
    end
  end
end
