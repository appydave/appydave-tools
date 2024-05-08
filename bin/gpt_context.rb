#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage:
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*.rb'
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*' -e 'node_modules/**/*' -e 'package-lock.json' -e 'lib/openai_101/tools/prompts/*.txt'
#
#   Get GPT Context Gatherer code
#   ./bin/gpt_context.rb -i 'bin/**/*gather*.rb' -i 'lib/openai_101/tools/**/*gather*.rb'
require 'optparse'
require 'clipboard'
require_relative '../lib/appydave/tools/gpt_context/file_collector'

options = {
  include_patterns: [],
  exclude_patterns: [],
  format: nil,
  debug: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: gather_content.rb [options]'

  opts.on('-i', '--include PATTERN', 'Pattern or file to include (can be used multiple times)') do |pattern|
    options[:include_patterns] << pattern
  end

  opts.on('-e', '--exclude PATTERN', 'Pattern or file to exclude (can be used multiple times)') do |pattern|
    options[:exclude_patterns] << pattern
  end

  opts.on('-f', '--format FORMAT', 'Output format: default or tree') do |format|
    options[:format] = format
  end

  opts.on('-d', '--debug', 'Enable debug mode') do
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    puts "\nExamples:"
    puts "  #{File.basename($PROGRAM_NAME)} -i 'lib/**/*.rb' -e 'lib/excluded/**/*.rb' -d"
    puts "  #{File.basename($PROGRAM_NAME)} --include 'src/**/*.js' --exclude 'src/vendor/**/*.js'"

    puts ''
    puts '  # Get GPT Context Gatherer code that is found in any folder (bin, lib & spec)'
    puts "  #{File.basename($PROGRAM_NAME)} -i '**/*gather*.rb'"
    exit
  end
end.parse!

if options[:include_patterns].empty? && options[:exclude_patterns].empty? && options[:format].nil?
  script_name = File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME))

  puts 'No options provided to GPT Context. Please specify patterns to include or exclude.'
  puts "For help, run: #{script_name} --help"
  exit
end

pp options if options[:debug]

gatherer = Appydave::Tools::GptContext::FileCollector.new(
  include_patterns: options[:include_patterns],
  exclude_patterns: options[:exclude_patterns],
  format: options[:format]
)

content = gatherer.build

if options[:debug]
  puts '-' * 80
  puts content
  puts '-' * 80
end

Clipboard.copy(content)
