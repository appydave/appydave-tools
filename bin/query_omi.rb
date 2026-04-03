#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::BrainContextOptions.new
options.omi = true

def setup_options(options)
  OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
    opts.banner = 'Usage: query_omi [options]'

    opts.on('--signal SIGNAL', %w[work life ambient],
            'Filter by signal') do |signal|
      options.omi_signals << signal
    end

    opts.on('--routing ROUTING',
            'Filter by routing (brain-update, todo-item, personal, til, archive; pipe-delimited)') do |routing|
      options.omi_routings.concat(routing.split('|').map(&:strip))
    end

    opts.on('--activity ACTIVITY',
            'Filter by activity (planning, reviewing, learning, debugging, etc.; pipe-delimited)') do |activity|
      options.omi_activities.concat(activity.split('|').map(&:strip))
    end

    opts.on('--date-from DATE', 'Include files from date (YYYY-MM-DD)') do |date|
      options.date_from = date
    end

    opts.on('--date-to DATE', 'Include files up to date (YYYY-MM-DD)') do |date|
      options.date_to = date
    end

    opts.on('--enriched-only', 'Skip raw (non-enriched) transcripts') do
      options.enriched_only = true
    end

    opts.on('--brain NAME', 'Find OMI files mentioning this brain') do |name|
      options.brain_names << name
    end

    opts.on('-d', '--debug [MODE]', %w[none info params debug],
            'Debug output level') do |level|
      options.debug_level = level || 'info'
    end

    opts.on('-v', '--version', 'Show version') do
      puts "query_omi v#{Appydave::Tools::VERSION}"
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
finder = Appydave::Tools::OmiQuery.new(options)
paths = finder.find

# Output file paths, one per line
paths.each { |p| puts p }

exit 0
