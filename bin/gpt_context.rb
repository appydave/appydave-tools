#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage:
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*.rb'
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*' -e 'node_modules/**/*' -e 'package-lock.json' -e 'lib/openai_101/tools/prompts/*.txt'
#
#   Get GPT Context Gatherer code
#   ./bin/gpt_context.rb -i 'bin/**/*gather*.rb' -i 'lib/openai_101/tools/**/*gather*.rb'
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

options = {
  include_patterns: [],
  exclude_patterns: [],
  format: 'tree,content',
  line_limit: nil,
  debug: 'none'
}

OptionParser.new do |opts|
  opts.banner = 'Usage: gather_content.rb [options]'

  opts.on('-i', '--include PATTERN', 'Pattern or file to include (can be used multiple times)') do |pattern|
    options[:include_patterns] << pattern
  end

  opts.on('-e', '--exclude PATTERN', 'Pattern or file to exclude (can be used multiple times)') do |pattern|
    options[:exclude_patterns] << pattern
  end

  opts.on('-f', '--format FORMAT', 'Output format: content or tree, if not provided then both are used') do |format|
    options[:format] = format
  end

  opts.on('-l', '--line-limit LIMIT', 'Limit the number of lines included from each file') do |limit|
    options[:line_limit] = limit.to_i
  end

  # None - No debug output
  # Output - Output the content to the console, this is the same as found in the clipboard
  # Params - Output the options that were passed to the script
  # Debug - Output content, options and debug information
  opts.on('-d', '--debug [MODE]', 'Enable debug mode [none, output, params, debug]', 'none', 'output', 'params', 'debug') do |debug|
    options[:debug] = debug || 'output'
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

pp options if options[:debug] == 'params'

gatherer = Appydave::Tools::GptContext::FileCollector.new(
  include_patterns: options[:include_patterns],
  exclude_patterns: options[:exclude_patterns],
  format: options[:format],
  line_limit: options[:line_limit],
  working_directory: Dir.pwd
)

content = gatherer.build

if %w[output debug].include?(options[:debug])
  puts '-' * 80
  puts content
  puts '-' * 80
end

pp options if options[:debug] == 'debug'

Clipboard.copy(content)
