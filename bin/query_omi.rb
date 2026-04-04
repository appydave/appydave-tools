#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::BrainContextOptions.new
options.omi = true

def setup_options(options)
  OptionParser.new do |opts|
    opts.banner = 'Usage: query_omi [options]'

    opts.on('--brain NAME', 'Find OMI sessions mentioning this brain') do |name|
      options.brain_names << name
    end

    opts.on('--routing ROUTING',
            'Filter by routing (brain-update, todo-item, personal, til, archive; pipe-delimited)') do |routing|
      options.omi_routings.concat(routing.split('|').map(&:strip))
    end

    opts.on('--activity ACTIVITY',
            'Filter by activity (planning, reviewing, learning, debugging, etc.; pipe-delimited)') do |activity|
      options.omi_activities.concat(activity.split('|').map(&:strip))
    end

    opts.on('--days N', Integer, 'Include sessions from the last N days') do |n|
      options.days = n
    end

    opts.on('--limit N', Integer, 'Return at most N results (most recent)') do |n|
      options.limit = n
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
