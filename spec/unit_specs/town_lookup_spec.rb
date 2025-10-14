# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require_relative '../../lib/ons_postcode_extractor/town_lookup'

RSpec.describe OnsPostcodeExtractor::TownLookup do
  subject(:town_lookup) { described_class.new }

  let(:fixture_path) { File.expand_path('../fixtures/postcode_examples.csv', __dir__) }
  let(:postcodes_and_expected) do
    CSV.read(fixture_path, headers: true).map do |row|
      [row['postcode'], row['expected_town']]
    end
  end
  let(:postcodes) { postcodes_and_expected.map(&:first) }
  let(:expected_towns) { postcodes_and_expected.map(&:last) }

  describe '.find_town' do
    let(:actual_towns) do
      postcodes.map do |postcode|
        town_lookup.find_town(postcode)
      end
    end

    it 'returns the correct town for each postcode in the fixture' do
      expect(actual_towns).to eq(expected_towns)
    end
  end
end
