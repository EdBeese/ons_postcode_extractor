# frozen_string_literal: true

module OnsPostcodeExtractor
  # Executes command line interface
  class CLI
    def self.start(argv)
      puts argv
      command = argv[0]
      file_path = argv[1]

      exit_bad_command(command) if command != 'process'
      check_file(file_path)
      Processor.new(file_path).run
    rescue OnsPostcodeExtractor::MissingColumnsError => e
      exit_missing_columns(e.message)
    end

    def self.check_file(file_path)
      exit_no_file_path if file_path.nil? || file_path.strip.empty?
      exit_no_file(file_path) unless File.exist?(file_path)

      nil
    end

    def self.exit_bad_command(command)
      puts "❌ Unknown command: #{command}"
      puts 'Usage: ons_postcode_extractor process path/to/ONSPD.csv'
      exit(1)
    end

    def self.exit_no_file_path
      puts '❌ You must provide a CSV file path'
      puts 'Usage: ons_postcode_extractor process path/to/ONSPD.csv'
      exit(1)
    end

    def self.exit_no_file(file_path)
      puts "❌ File not found: #{file_path}"
      exit(1)
    end

    def self.exit_missing_columns(message)
      puts "❌ #{message} - ONS data structure may have changed. Consult README."
      exit(1)
    end
  end
end
