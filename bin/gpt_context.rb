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

options = Appydave::Tools::GptContext::Options.new(
  working_directory: nil
)

OptionParser.new do |opts|
  opts.banner = <<~BANNER
    GPT Context Gatherer - Collect project files for AI context

    SYNOPSIS
        gpt_context [options]

    DESCRIPTION
        Collects and packages codebase files for AI assistant context.
        Outputs to clipboard (default), file, or stdout.

  BANNER

  opts.separator 'OPTIONS'
  opts.separator ''

  opts.on('-i', '--include PATTERN',
          'Glob pattern for files to include (repeatable)',
          'Example: -i "lib/**/*.rb" -i "bin/**/*.rb"') do |pattern|
    options.include_patterns << pattern
  end

  opts.on('-e', '--exclude PATTERN',
          'Glob pattern for files to exclude (repeatable)',
          'Example: -e "spec/**/*" -e "node_modules/**/*"') do |pattern|
    options.exclude_patterns << pattern
  end

  opts.on('-f', '--format FORMATS',
          'Output format(s): tree, content, json, aider, files',
          'Comma-separated. Default: content',
          'Example: -f tree,content') do |format|
    options.format = format
  end

  opts.on('-l', '--line-limit N', Integer,
          'Limit lines per file (default: unlimited)') do |n|
    options.line_limit = n
  end

  opts.on('-b', '--base-dir DIRECTORY',
          'Set the base directory to gather files from') do |directory|
    options.working_directory = directory
  end

  opts.on('-d', '--debug [MODE]', 'Enable debug mode [none, info, params, debug]',
          'none', 'info', 'params', 'debug') do |debug|
    options.debug = debug || 'info'
  end

  opts.on('-o', '--output TARGET',
          'Output target: clipboard, filename, or stdout',
          'Default: clipboard. Repeatable for multiple targets.') do |target|
    options.output_target << target
  end

  opts.on('-p', '--prompt TEXT',
          'Prompt text for aider format output') do |message|
    options.prompt = message
  end

  opts.separator ''
  opts.separator 'OUTPUT FORMATS'
  opts.separator '    tree     - Directory tree structure'
  opts.separator '    content  - File contents with headers (default)'
  opts.separator '    json     - Structured JSON output'
  opts.separator '    aider    - Aider CLI command format (requires -p)'
  opts.separator '    files    - File paths only'
  opts.separator ''
  opts.separator 'EXAMPLES'
  opts.separator '    # Gather Ruby library code for AI context'
  opts.separator "    gpt_context -i 'lib/**/*.rb' -e 'spec/**/*' -d"
  opts.separator ''
  opts.separator '    # Project structure overview'
  opts.separator "    gpt_context -i '**/*' -f tree -e 'node_modules/**/*'"
  opts.separator ''
  opts.separator '    # Save to file with tree and content'
  opts.separator "    gpt_context -i 'src/**/*.ts' -f tree,content -o context.txt"
  opts.separator ''
  opts.separator '    # Generate aider command'
  opts.separator "    gpt_context -i 'lib/**/*.rb' -f aider -p 'Add logging'"
  opts.separator ''

  opts.on('-v', '--version', 'Show version') do
    puts "gpt_context version #{Appydave::Tools::VERSION}"
    exit
  end

  opts.on_tail('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end.parse!

if options.include_patterns.empty? && options.exclude_patterns.empty? && options.format.nil?
  script_name = File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME))

  puts 'No options provided to GPT Context. Please specify patterns to include or exclude.'
  puts "For help, run: #{script_name} --help"
  exit
end

if options.output_target.empty?
  puts 'No output target provided. Will default to `clipboard`. You can set the output target using -o'
  options.output_target << 'clipboard'
end

pp options if options.debug == 'params'

options.working_directory ||= Dir.pwd

gatherer = Appydave::Tools::GptContext::FileCollector.new(options)
content = gatherer.build

if %w[info debug].include?(options.debug)
  puts '-' * 80
  puts content
  puts '-' * 80
end

output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute

pp options if options.debug == 'debug'
