#!/usr/bin/env ruby
# frozen_string_literal: true

# GPT Chats:
# https://chatgpt.com/c/670df475-04f4-8002-a758-f5711bf433eb

# Usage:
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*.rb'
#   ./bin/gpt_context.rb -d -i 'lib/openai_101/tools/**/*' -e 'node_modules/**/*' -e 'package-lock.json' -e 'lib/openai_101/tools/prompts/*.txt'
#
#   Get GPT Context Gatherer code
#   ./bin/gpt_context.rb -i 'bin/**/*gather*.rb' -i 'lib/openai_101/tools/**/*gather*.rb'
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'
require 'json'
require 'optparse'

options = {
  include_patterns: [],
  exclude_patterns: [],
  format: 'tree,content',
  line_limit: nil,
  debug: 'none',
  output_target: []
}

OptionParser.new do |opts|
  opts.banner = 'Usage: gather_content.rb [options]'

  opts.on('-i', '--include PATTERN', 'Pattern or file to include (can be used multiple times)') do |pattern|
    options[:include_patterns] << pattern
  end

  opts.on('-e', '--exclude PATTERN', 'Pattern or file to exclude (can be used multiple times)') do |pattern|
    options[:exclude_patterns] << pattern
  end

  opts.on('-f', '--format FORMAT', 'Output format: content, tree, or json, if not provided then both are used') do |format|
    options[:format] = format
  end

  opts.on('-l', '--line-limit LIMIT', 'Limit the number of lines included from each file') do |limit|
    options[:line_limit] = limit.to_i
  end

  # New option for specifying base directory
  opts.on('-b', '--base-dir DIRECTORY', 'Set the base directory to gather files from') do |directory|
    options[:working_directory] = directory
  end

  # None - No debug output
  # Info - Write the content to the console, this is the same as found in the clipboard
  # Params - Write the options that were passed to the script
  # Debug - Write the content, options and debug information
  opts.on('-d', '--debug [MODE]', 'Enable debug mode [none, info, params, debug]', 'none', 'info', 'params', 'debug') do |debug|
    options[:debug] = debug || 'info'
  end

  # Output targets: console, clipboard, or file
  opts.on('-o', '--output TARGET', 'Output target: console, clipboard, or a file path (can be used multiple times)') do |target|
    options[:output_target] << target
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

if options[:output_target].empty?
  puts 'No output target provided. Will default to `console & clipboard`. You can set the output target using -o'
  options[:output_target] << 'clipboard'
end

pp options if options[:debug] == 'params'

options[:working_directory] ||= Dir.pwd

gatherer = Appydave::Tools::GptContext::FileCollector.new(
  include_patterns: options[:include_patterns],
  exclude_patterns: options[:exclude_patterns],
  format: options[:format],
  line_limit: options[:line_limit],
  working_directory: options[:working_directory]
)

content = gatherer.build

if %w[info debug].include?(options[:debug])
  puts '-' * 80
  puts content
  puts '-' * 80
end

Clipboard.copy(content) if options[:output_target].include?('clipboard')

file_targets = options[:output_target].select { |target| target != 'console' && target != 'clipboard' }
file_targets.each do |file_path|
  resolved_path = Pathname.new(file_path).absolute? ? file_path : File.join(options[:working_directory], file_path)
  File.write(resolved_path, content)
end

pp options if options[:debug] == 'debug'
