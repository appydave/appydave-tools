#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'pry'
require 'appydave/tools'

# !/usr/bin/env ruby
# frozen_string_literal: true

# Process command line arguments for any bank reconciliation operations
class BankReconciliationCLI
  def initialize
    @commands = {
      'clean' => method(:clean_transactions),
      'transform' => method(:transform),
      'process' => method(:process_transactions),
      'filter' => method(:filter_transactions)
    }
  end

  def run
    command, *args = ARGV
    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def clean_transactions(args)
    options = { include: [] }
    OptionParser.new do |opts|
      opts.banner = 'Usage: bank_reconciliation.rb clean [options]'

      opts.on('-i', '--include PATTERN', 'GLOB pattern for source transaction files') do |v|
        options[:include] << v
      end

      opts.on('-f', '--transaction FOLDER', 'Transaction CSV folder where original banking CSV files are stored') do |v|
        options[:transaction_folder] = v
      end

      opts.on('-o', '--output FILE', 'Output CSV file name') do |v|
        options[:output] = v
      end

      opts.on('-d', '--debug', 'Enable debug mode') do
        options[:debug] = true
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    transaction_folder = options[:transaction_folder] || '/default/transaction/folder'
    output_file = options[:output] || 'clean_transactions.csv'
    include_patterns = options[:include].empty? ? ['*'] : options[:include]

    # puts "Cleaning transactions with options: #{options}"

    # Ensure the clean directory exists
    clean_dir = File.dirname(output_file)
    FileUtils.mkdir_p(clean_dir)

    # Initialize the CleanTransactions class and process the files
    cleaner = Appydave::Tools::BankReconciliation::Clean::CleanTransactions.new(transaction_folder: transaction_folder, debug: options[:debug])
    cleaner.clean_transactions(include_patterns, output_file)
  end

  def transform(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: bank_reconciliation.rb clean [options]'

      opts.on('-c', '--to-csv', 'Write chart of accounts JSON to CSV') { options[:to_csv] = true }
      opts.on('-j', '--to-json', 'Write chart of accounts CSV to JSON') { options[:to_json] = true }

      opts.on('-d', '--debug', 'Enable debug mode') do
        options[:debug] = true
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    Appydave::Tools::Configuration::Models::BankReconciliationConfig.new.coa_to_csv if options[:to_csv]
    Appydave::Tools::Configuration::Models::BankReconciliationConfig.new.coa_csv_to_json if options[:to_json]
  end

  def process_transactions(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: bank_reconciliation.rb process [options]'
      opts.on('-i', '--input FILE', 'Input CSV file with transactions') { |v| options[:input] = v }
      opts.on('-d', '--debug', 'Enable debug mode') { |v| options[:debug] = v }
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    # Implement processing transactions with chart of accounts lookup
    puts "Processing transactions with options: #{options}"
  end

  def filter_transactions(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: bank_reconciliation.rb filter [options]'
      opts.on('-i', '--input FILE', 'Input CSV file with processed transactions') { |v| options[:input] = v }
      opts.on('-y', '--year YEAR', 'Filter by financial year') { |v| options[:year] = v }
      opts.on('-b', '--begin DATE', 'Filter by dates greater than or eqaul to DDMMYY') { |v| options[:year] = v }
      opts.on('-e', '--end DATE', 'Filter by dates less than or eqaul to DDMMYY') { |v| options[:year] = v }
      opts.on('-c', '--codes CODES', 'Filter by chart of account codes (comma-separated)') { |v| options[:codes] = v }
      opts.on('-w', '--wild TEXT', 'Wildcard text match') { |v| options[:text] = v }
      opts.on('-v', '--view', 'Display filtered transactions in table format') { |v| options[:display] = v }
      opts.on('-o', '--output FILE', 'Output CSV file name') { |v| options[:output] = v }
      opts.on('-d', '--debug', 'Enable debug mode') { |v| options[:debug] = v }
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    # Implement filtering of processed transactions
    puts "Filtering transactions with options: #{options}"
  end

  def print_help
    puts 'Usage: bank_reconciliation.rb [command] [options]'
    puts 'Commands:'
    puts '  clean    Clean and normalize transaction files'
    puts '  process  Process transaction list via chart of accounts lookup'
    puts '  filter   Filter processed transaction list'
    puts "Run 'bank_reconciliation.rb [command] --help' for more information on a command."
  end
end

Appydave::Tools::Configuration::Config.configure

BankReconciliationCLI.new.run
# BankReconciliationCLI.new.run if __FILE__ == $PROGRAM_NAME
