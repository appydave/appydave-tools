#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::BrainContextOptions.new

OptionParser.new do |opts|
  opts.banner = "Usage: brain_context [options]"

  opts.on('--brain NAME', 'Include files from brain (supports aliases, fuzzy match)') do |name|
    options.brain_names << name
  end

  opts.on('--tag TAG', 'Include files from brains matching tag') do |tag|
    options.tags << tag
  end

  opts.on('--category CAT', 'Include files from all brains in category') do |cat|
    options.categories << cat
  end

  opts.on('--activity-min LEVEL', ['high', 'medium', 'low', 'none'],
          'Filter brains by minimum activity level') do |level|
    options.activity_levels << level
  end

  opts.on('--status STATUS', ['active', 'stable', 'deprecated'],
          'Filter brains by status (default: exclude deprecated)') do |status|
    options.status = status
  end

  opts.on('--files-only', 'Exclude INDEX.md files, only include content files') do
    options.include_index = false
  end

  opts.on('--omi', 'Enable OMI (wearable transcript) query mode') do
    options.omi = true
  end

  opts.on('--signal SIGNAL', ['work', 'life', 'ambient'],
          'OMI: filter by signal') do |signal|
    options.omi_signals << signal
  end

  opts.on('--routing ROUTING',
          'OMI: filter by routing (brain-update, todo-item, personal, til, archive; pipe-delimited)') do |routing|
    options.omi_routings.concat(routing.split('|').map(&:strip))
  end

  opts.on('--activity ACTIVITY',
          'OMI: filter by activity (planning, reviewing, learning, etc.; pipe-delimited)') do |activity|
    options.omi_activities.concat(activity.split('|').map(&:strip))
  end

  opts.on('--date-from DATE', 'OMI: include files from date (YYYY-MM-DD)') do |date|
    options.date_from = date
  end

  opts.on('--date-to DATE', 'OMI: include files up to date (YYYY-MM-DD)') do |date|
    options.date_to = date
  end

  opts.on('--enriched-only', 'OMI: skip raw (non-enriched) transcripts') do
    options.enriched_only = true
  end

  opts.on('-o', '--output TARGET', 'Output target: clipboard (default), temp, stdout, or filename') do |target|
    options.output_targets = [target]
  end

  opts.on('-f', '--format FORMATS', 'Output format: tree, content (default), json, aider, files') do |formats|
    options.formats = formats.split(',').map(&:strip)
  end

  opts.on('-l', '--line-limit N', Integer, 'Max lines per file') do |limit|
    options.line_limit = limit
  end

  opts.on('-t', '--tokens', 'Show estimated token count') do
    options.tokens = true
  end

  opts.on('-d', '--debug [MODE]', ['none', 'info', 'params', 'debug'],
          'Debug output level') do |level|
    options.debug_level = level || 'info'
  end

  opts.on('--dry-run', 'List matched files without concatenating') do
    options.dry_run = true
  end

  opts.on('-v', '--version', 'Show version') do
    puts "brain_context v#{Appydave::Tools::VERSION}"
    exit 0
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    exit 0
  end
end.parse!

# Perform queries
paths = []

if options.brain_query?
  finder = Appydave::Tools::BrainFinder.new(options)
  paths.concat(finder.find)
end

if options.omi_query?
  finder = Appydave::Tools::OmiFinder.new(options)
  paths.concat(finder.find)
end

paths = paths.uniq.sort

# Handle output
if options.dry_run
  puts paths
  exit 0
end

# Build content
builder = Appydave::Tools::ContentBuilder.new(paths, options)
content = builder.build

# Show token estimate if requested
if options.tokens
  tokens = builder.token_estimate
  warn "Estimated tokens: #{tokens}"
end

# Write output
handler = Appydave::Tools::BrainContextOutputHandler.new(content, options)
handler.write

exit 0
