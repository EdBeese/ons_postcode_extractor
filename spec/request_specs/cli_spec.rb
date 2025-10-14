# frozen_string_literal: true

require 'spec_helper'
require 'open3'

require_relative '../../lib/ons_postcode_extractor'

RSpec.describe OnsPostcodeExtractor::CLI, :cleanup_output_csv do
  let(:stdout_str) { StringIO.new }
  let(:argv) { [] }
  let(:fixtures_path) { File.expand_path('../fixtures/input_csv', __dir__) }
  let(:input_csv) { File.join(fixtures_path, csv_file) }
  let(:csv_file) { 'valid_test.csv' }
  let(:command) { 'process' }
  let(:output_csv) { File.join(File.dirname(input_csv), "processed_#{File.basename(input_csv)}") }

  def run_cli(*args)
    argv.replace(args)
    begin
      $stdout = stdout_str
      described_class.start(argv)
    rescue SystemExit => e
      @exit_code = e.status
    ensure
      $stdout = STDOUT
    end
  end

  before { run_cli(command, input_csv) }

  context 'when an invalid command is input' do
    let(:command) { 'foo' }

    it 'shows an error if the command is invalid' do
      expect(stdout_str.string).to include('❌ Unknown command')
    end

    it 'returns with a status code of 1' do
      expect(@exit_code).to eq(1)
    end
  end

  context 'when no file path is given' do
    let(:input_csv) { '' }

    it 'shows a clear error' do
      expect(stdout_str.string).to include('❌ You must provide a CSV file path')
    end

    it 'returns with a status code of 1' do
      expect(@exit_code).to eq(1)
    end
  end

  context 'when a bad file path is given' do
    let(:input_csv) { '../fixtures/fooba.csv' }

    it 'shows a clear error' do
      expect(stdout_str.string).to include('❌ File not found:')
    end

    it 'returns with a status code of 1' do
      expect(@exit_code).to eq(1)
    end
  end

  context 'when a passed in CSV file does not include all of the requisite columns' do
    let(:csv_file) { 'missing_columns.csv' }

    it 'shows a clear error' do
      expect(stdout_str.string).to include('ONS data structure may have changed. Consult README.')
    end

    it 'returns with a status code of 1' do
      expect(@exit_code).to eq(1)
    end
  end

  context 'when a valid CSV file is passed in' do
    let(:expected_csv_to_hash) do
      CSV.read(File.expand_path("../fixtures/expected_csv/#{csv_file}", __dir__), headers: true).map(&:to_h)
    end

    it 'shows a success message' do
      expect(stdout_str.string).to include('✅ Processed file saved to')
    end

    it 'does not have an exit code' do
      expect(@exit_code).to be_nil
    end

    it 'correctly maps the applicable fields, adds town and local authority, and omits terminated and non-geo' do
      expect(CSV.read(output_csv, headers: true).map(&:to_h)).to eq(expected_csv_to_hash)
    end
  end

  context 'when a passed in CSV file has a postcode that does not match the regex town patterns' do
    let(:csv_file) { 'unknown_postcode_outcode.csv' }

    it 'shows a clear warning' do
      expect(stdout_str.string).to include('⚠️ Outcode ZE4 not found. Regex data may need to be updated.')
    end

    it 'does not have an exit code' do
      expect(@exit_code).to be_nil
    end
  end

  context 'when an invalid postcode is present in the data' do
    let(:csv_file) { 'invalid_postcode.csv' }

    it 'shows a clear warning' do
      expect(stdout_str.string).to include('⛔️ Postcode Failed Validation: BATMAN. Check data.')
    end

    it 'does not have an exit code' do
      expect(@exit_code).to be_nil
    end
  end
end
