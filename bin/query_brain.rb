#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::BrainContextOptions.new

def setup_options(options)
  OptionParser.new do |opts|
    opts.banner = 'Usage: query_brain [options]'

    opts.on('--find TERM', 'Find brain by name, tag, or alias (repeatable)') do |term|
      options.brain_names << term
    end

    opts.on('--category CAT', 'Find all brains in category (repeatable)') do |cat|
      options.categories << cat
    end

    opts.on('--active', 'Return all high-activity brains') do
      options.active = true
    end

    opts.on('--files-only', 'Exclude INDEX.md, only include content files') do
      options.include_index = false
    end

    opts.on('-d', '--debug [MODE]', %w[none info params debug],
            'Debug output level') do |level|
      options.debug_level = level || 'info'
    end

    opts.on('-v', '--version', 'Show version') do
      puts "query_brain v#{Appydave::Tools::VERSION}"
      exit 0
    end

    opts.on('-h', '--help', 'Show this message') do
      puts opts
      exit 0
    end
  end.parse!
end

setup_options(options)

# Query
finder = Appydave::Tools::BrainQuery.new(options)
paths = finder.find

# Output file paths, one per line
paths.each { |p| puts p }

exit 0
