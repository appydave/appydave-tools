#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::BrainContextOptions.new

def setup_options(options)
  OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
    opts.banner = 'Usage: query_brain [options]'

    opts.on('--brain NAME', 'Query brain by name, alias, or fuzzy match') do |name|
      options.brain_names << name
    end

    opts.on('--tag TAG', 'Query brains by tag') do |tag|
      options.tags << tag
    end

    opts.on('--category CAT', 'Query all brains in category') do |cat|
      options.categories << cat
    end

    opts.on('--activity-min LEVEL', %w[high medium low none],
            'Filter brains by minimum activity level') do |level|
      options.activity_levels << level
    end

    opts.on('--status STATUS', %w[active stable deprecated],
            'Filter brains by status (default: exclude deprecated)') do |status|
      options.status = status
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
