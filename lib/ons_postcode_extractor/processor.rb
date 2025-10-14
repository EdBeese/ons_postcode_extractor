# frozen_string_literal: true

require 'csv'
require 'tempfile'
require 'fileutils'

module OnsPostcodeExtractor
  # Class that executes the logic to extract and process the ONS data
  class Processor
    REQUIRED_COLUMNS = %w[pcds dointr doterm east1m north1m lat long lad25cd].freeze
    OUTPUT_COLUMNS = (REQUIRED_COLUMNS - ['doterm']) + %w[local_authority town]

    def initialize(file_path)
      @input_path = file_path
      @output_path = File.join(
        File.dirname(file_path),
        "processed_#{File.basename(file_path)}"
      )
      @postcode_cache = {}
      @column_indexes = nil
    end

    def run
      Tempfile.open(['onspd', '.csv'], File.dirname(@input_path)) do |temp_file|
        CSV.open(temp_file, 'w') do |csv_out|
          csv_out << OUTPUT_COLUMNS
          puts "Processing file #{@input_path} - put the kettle on, this will take a few minutes..."
          process_csv(csv_out)
        end
        FileUtils.mv(temp_file.path, @output_path)
      end
      puts "✅ Processed file saved to: #{@output_path}"
    end

    private

    def process_csv(csv_out)
      CSV.foreach(@input_path, headers: true) do |row|
        data = extract_row_data(row)
        next if skip_row?(data)

        enrich_data!(data)
        csv_out << OUTPUT_COLUMNS.map { |col| data[col] }
      end
    end

    def extract_row_data(row)
      REQUIRED_COLUMNS.zip(column_indexes(row).map { |i| row[i] }).to_h
    end

    def column_indexes(row)
      @column_indexes ||= begin
        indexes = REQUIRED_COLUMNS.map { |col| row.headers.map(&:downcase).index(col) }

        missing = REQUIRED_COLUMNS.select.with_index { |_, idx| indexes[idx].nil? }
        raise MissingColumnsError, "Missing columns: #{missing.join(', ')}" if missing.any?

        indexes
      end
    end

    def skip_row?(data)
      (data['doterm'] && !data['doterm'].strip.empty?) || non_geo?(data['lat'].to_f.round)
    end

    def enrich_data!(data)
      data['local_authority'] = LocalAuthorityLookup.name_for(data['lad25cd'])
      town = town_lookup.find_town(data['pcds'])
      data['town'] = town.is_a?(String) ? town : nil
    end

    def town_lookup
      @town_lookup ||= TownLookup.new
    end

    def non_geo?(lat)
      lat == 99 || lat == 100 || lat.nil? || lat.zero?
    end
  end
end
