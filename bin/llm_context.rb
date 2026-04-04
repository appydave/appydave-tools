#!/usr/bin/env ruby
# frozen_string_literal: true

# GPT Chats:
# https://chatgpt.com/c/670df475-04f4-8002-a758-f5711bf433eb

# Usage:
#   ./bin/llm_context.rb -d -i 'lib/openai_101/tools/**/*.rb'
#   ./bin/llm_context.rb -d -i 'lib/openai_101/tools/**/*' -e 'node_modules/**/*' -e 'package-lock.json' -e 'lib/openai_101/tools/prompts/*.txt'
#
#   Get LLM Context Gatherer code
#   ./bin/llm_context.rb -i 'bin/**/*gather*.rb' -i 'lib/openai_101/tools/**/*gather*.rb'
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

def build_banner
  <<~BANNER
    LLM Context Gatherer - Collect project files for AI context

    SYNOPSIS
        llm_context [options]

    DESCRIPTION
        Collects and packages codebase files for AI assistant context.
        Outputs to clipboard (default), file, or stdout.

  BANNER
end

def setup_options(opts, options)
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
          'Output target: clipboard, temp, filename, or stdout',
          'Default: clipboard. Repeatable for multiple targets.') do |target|
    options.output_target << target
  end

  opts.on('-p', '--prompt TEXT',
          'Prompt text for aider format output') do |message|
    options.prompt = message
  end

  opts.on('-t', '--tokens', 'Show estimated token count after collecting context') do
    options.show_tokens = true
  end

  opts.on('-s', '--smart', 'Auto-route: clipboard if ≤ threshold tokens, else temp file',
          'Mutually exclusive with explicit -o clipboard or -o temp') do
    options.smart = true
  end

  opts.on('--smart-limit N', Integer,
          'Token threshold for --smart (default: 100000)') do |n|
    options.smart_limit = n
  end

  opts.on('--stdin', 'Read file paths from stdin (one per line) instead of using patterns') do
    options.stdin = true
  end
end

def setup_help_sections(opts)
  opts.separator ''
  opts.separator 'OUTPUT FORMATS'
  opts.separator '    tree     - Directory tree structure'
  opts.separator '    content  - File contents with headers (default)'
  opts.separator '    json     - Structured JSON output'
  opts.separator '    aider    - Aider CLI command format (requires -p)'
  opts.separator '    files    - File paths only'
  opts.separator ''
  opts.separator 'OUTPUT TARGETS'
  opts.separator '    clipboard - Copy to system clipboard (default)'
  opts.separator '    temp      - Write to system temp dir, copy path to clipboard'
  opts.separator '    filename  - Write to specified file path'
  opts.separator '    --smart   - Auto-route: clipboard if ≤ 100k tokens, else temp file'
  opts.separator ''
  opts.separator 'INPUT MODES'
  opts.separator '    Patterns (default): -i <glob> and -e <exclude_glob>'
  opts.separator '    Stdin:             --stdin (read file paths from stdin, one per line)'
  opts.separator ''
  opts.separator 'EXAMPLES'
  opts.separator '    # Gather Ruby library code for AI context'
  opts.separator "    llm_context -i 'lib/**/*.rb' -e 'spec/**/*' -d"
  opts.separator ''
  opts.separator '    # Project structure overview'
  opts.separator "    llm_context -i '**/*' -f tree -e 'node_modules/**/*'"
  opts.separator ''
  opts.separator '    # Save to file with tree and content'
  opts.separator "    llm_context -i 'src/**/*.ts' -f tree,content -o context.txt"
  opts.separator ''
  opts.separator '    # Write to system temp dir and copy path to clipboard'
  opts.separator "    llm_context -i 'lib/**/*.rb' -o temp"
  opts.separator ''
  opts.separator '    # Read file paths from stdin'
  opts.separator "    find lib -name '*.rb' | llm_context --stdin -o temp"
  opts.separator ''
  opts.separator '    # Generate aider command'
  opts.separator "    llm_context -i 'lib/**/*.rb' -f aider -p 'Add logging'"
  opts.separator ''
end

def setup_version_and_help(opts)
  opts.on('-v', '--version', 'Show version') do
    puts "llm_context version #{Appydave::Tools::VERSION}"
    exit
  end

  opts.on_tail('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end

# Main execution
options = Appydave::Tools::LlmContext::Options.new(
  working_directory: nil
)

parser = OptionParser.new do |opts|
  opts.banner = build_banner
  setup_options(opts, options)
  setup_help_sections(opts)
  setup_version_and_help(opts)
end

parser.parse!

# Handle stdin file paths
if options.stdin
  options.file_paths = $stdin.readlines.map(&:chomp).reject(&:empty?)
  options.working_directory = Dir.pwd unless options.working_directory
end

if options.include_patterns.empty? && options.exclude_patterns.empty? && options.file_paths.empty?
  script_name = File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME))

  puts 'No options provided to LLM Context. Please specify patterns to include or exclude, or use --stdin.'
  puts "For help, run: #{script_name} --help"
  exit
end

if options.smart && (options.output_target & %w[clipboard temp]).any?
  warn 'Error: --smart (-s) cannot be combined with explicit -o clipboard or -o temp'
  exit 1
end

if options.output_target.empty? && !options.smart
  puts 'No output target provided. Will default to `clipboard`. You can set the output target using -o'
  options.output_target << 'clipboard'
end

pp options if options.debug == 'params'

options.working_directory ||= Dir.pwd

gatherer = Appydave::Tools::LlmContext::FileCollector.new(options)
content = gatherer.build

if options.show_tokens
  token_estimate = (content.length / 4.0).ceil
  char_count = content.length
  warn ''
  warn '── Token Estimate ──────────────────────────'
  warn "  Characters : #{char_count.to_s.rjust(10)}"
  warn "  Tokens (~4c): #{token_estimate.to_s.rjust(10)}"
  warn ''
  if token_estimate > 200_000
    warn '  ⚠️  WARNING: Exceeds 200k tokens — may not fit most LLM context windows'
  elsif token_estimate > 100_000
    warn '  ⚠️  NOTICE: Exceeds 100k tokens — check your LLM context limit'
  end
  warn '────────────────────────────────────────────'
  warn ''
end

if %w[info debug].include?(options.debug)
  puts '-' * 80
  puts content
  puts '-' * 80
end

output_handler = Appydave::Tools::LlmContext::OutputHandler.new(content, options)
output_handler.execute

pp options if options.debug == 'debug'
