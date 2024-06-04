#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# Process command line arguments for SubtitleMaster operations
class SubtitleMasterCLI
  def initialize
    @commands = {
      'clean' => method(:clean_subtitles),
      'correct' => method(:correct_subtitles),
      'split' => method(:split_subtitles),
      'highlight' => method(:highlight_subtitles),
      'image_prompts' => method(:generate_image_prompts)
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

  def clean_subtitles(args)
    options = parse_options(args, 'clean')
    cleaner = Appydave::Tools::SubtitleMaster::Clean.new(options[:file])
    result = cleaner.clean
    write_output(result, options[:output])
  end

  def correct_subtitles(args)
    options = parse_options(args, 'correct')
    corrector = Appydave::Tools::SubtitleMaster::Correct.new(options[:file])
    result = corrector.correct
    write_output(result, options[:output])
  end

  def split_subtitles(args)
    options = parse_options(args, 'split', %i[words_per_group])
    splitter = Appydave::Tools::SubtitleMaster::Split.new(options[:file], options[:words_per_group])
    result = splitter.split
    write_output(result, options[:output])
  end

  def highlight_subtitles(args)
    options = parse_options(args, 'highlight')
    highlighter = Appydave::Tools::SubtitleMaster::Highlight.new(options[:file])
    result = highlighter.highlight
    write_output(result, options[:output])
  end

  def generate_image_prompts(args)
    options = parse_options(args, 'image_prompts')
    image_prompter = Appydave::Tools::SubtitleMaster::ImagePrompts.new(options[:file])
    result = image_prompter.generate_prompts
    write_output(result, options[:output])
  end

  def parse_options(args, command, extra_options = [])
    options = { file: nil, output: nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: subtitle_master.rb #{command} [options]"

      opts.on('-f', '--file FILE', 'SRT file to process') { |v| options[:file] = v }
      opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }

      extra_options.each do |opt|
        case opt
        when :words_per_group
          opts.on('-w', '--words-per-group WORDS', 'Number of words per group for splitting') { |v| options[:words_per_group] = v.to_i }
        end
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    unless options[:file] && options[:output]
      puts "Missing required options. Use -h for help."
      exit
    end

    options
  end

  def write_output(result, output_file)
    File.write(output_file, result)
    puts "Processed file written to #{output_file}"
  end

  def print_help
    puts 'Usage: subtitle_master.rb [command] [options]'
    puts 'Commands:'
    puts '  clean          Clean and normalize SRT files'
    puts '  correct        Correct common typos and mistranslations in SRT files'
    puts '  split          Split subtitle groups based on word count'
    puts '  highlight      Highlight power words in subtitles'
    puts '  image_prompts  Generate image prompts from subtitle text'
    puts "Run 'subtitle_master.rb [command] --help' for more information on a command."
  end
end

SubtitleMasterCLI.new.run