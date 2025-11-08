#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# Process command line arguments for SubtitleProcessor operations
class SubtitleProcessorCLI
  def initialize
    @commands = {
      'clean' => method(:clean_subtitles),
      'join' => method(:join_subtitles)
    }
  end

  def run
    command, *args = ARGV
    if command.nil?
      puts 'No command provided. Use -h for help.'
      print_help
      exit
    end

    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def clean_subtitles(args)
    options = { file: nil, output: nil }

    # Command-specific option parser
    clean_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor.rb clean [options]'

      opts.on('-f', '--file FILE', 'SRT file to process') do |v|
        options[:file] = v
      end

      opts.on('-o', '--output FILE', 'Output file') do |v|
        options[:output] = v
      end

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    begin
      clean_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}"
      puts clean_parser
      exit
    end

    # Validate required options
    if options[:file].nil? || options[:output].nil?
      puts 'Error: Missing required options.'
      puts clean_parser
      exit
    end

    # Assuming `Appydave::Tools::SubtitleProcessor::Clean` exists
    cleaner = Appydave::Tools::SubtitleProcessor::Clean.new(file_path: options[:file])
    cleaner.clean
    cleaner.write(options[:output])
  end

  def join_subtitles(args)
    options = {
      folder: './',
      files: '*.srt',
      sort: 'inferred',
      buffer: 100,
      output: 'merged.srt',
      verbose: false
    }

    join_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor.rb join [options]'

      opts.on('-d', '--directory DIR', 'Directory containing SRT files (default: current directory)') do |v|
        options[:folder] = v
      end

      opts.on('-f', '--files PATTERN', 'File pattern (e.g., "*.srt" or "part1.srt,part2.srt")') do |v|
        options[:files] = v
      end

      opts.on('-s', '--sort ORDER', %w[asc desc inferred], 'Sort order (asc/desc/inferred)') do |v|
        options[:sort] = v
      end

      opts.on('-b', '--buffer MS', Integer, 'Buffer between merged files in milliseconds') do |v|
        options[:buffer] = v
      end

      opts.on('-o', '--output FILE', 'Output file') do |v|
        options[:output] = v
      end

      opts.on('-L', '--log-level LEVEL', %w[none info detail], 'Log level (default: info)') do |v|
        options[:log_level] = v.to_sym
      end

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    begin
      join_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}"
      puts join_parser
      exit
    end

    # Validate required options
    if options[:folder].nil? || options[:files].nil? || options[:output].nil?
      puts 'Error: Missing required options.'
      puts join_parser
      exit
    end

    # Assuming `Appydave::Tools::SubtitleProcessor::Join` exists
    joiner = Appydave::Tools::SubtitleProcessor::Join.new(folder: options[:folder], files: options[:files], sort: options[:sort], buffer: options[:buffer], output: options[:output],
                                                        log_level: options[:log_level])
    joiner.join
  end

  def print_help
    puts 'Usage: subtitle_processor.rb [command] [options]'
    puts 'Commands:'
    puts '  clean          Clean and normalize SRT files'
    puts '  join           Join multiple SRT files'
    puts "Run 'subtitle_processor.rb [command] --help' for more information on a command."
  end
end

SubtitleProcessorCLI.new.run
