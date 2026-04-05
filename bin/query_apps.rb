#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::AppContext::Options.new

def setup_options(options)
  OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
    opts.banner = 'Usage: query_apps [APP] [options]'

    opts.on('--find APP', 'Find app by key, jump alias, or substring (repeatable)') do |app|
      options.app_names << app
    end

    opts.on('--glob NAMES', 'Glob names to resolve (comma-separated)') do |names|
      options.glob_names.concat(names.split(',').map(&:strip))
    end

    opts.on('--pattern PATTERN', 'Filter by project pattern type (e.g., rvets, nextjs)') do |pat|
      options.pattern_filter = pat
    end

    opts.on('--list', 'List available glob names for the specified app') do
      options.list = true
    end

    opts.on('--list-apps', 'List all apps with context.globs.json') do
      options.list_apps = true
    end

    opts.on('--meta', 'Return metadata as JSON instead of file paths') do
      options.meta = true
    end

    opts.on('-d', '--debug [MODE]', %w[none info params debug],
            'Debug output level') do |level|
      options.debug_level = level || 'info'
    end

    opts.on('-v', '--version', 'Show version') do
      puts "query_apps v#{Appydave::Tools::VERSION}"
      exit 0
    end

    opts.on('-h', '--help', 'Show this message') do
      puts opts
      exit 0
    end
  end.parse!
end

setup_options(options)

# Positional arg as app name if no --find given
options.app_names << ARGV.shift if ARGV.any? && options.app_names.empty?

finder = Appydave::Tools::AppContext::AppQuery.new(options)

if options.list_apps
  require 'json'
  puts JSON.pretty_generate(finder.list_apps)
elsif options.list && options.app_names.any?
  require 'json'
  puts JSON.pretty_generate(finder.list_globs(options.app_names.first))
elsif options.meta
  require 'json'
  puts JSON.pretty_generate(finder.find_meta)
else
  finder.find.each { |p| puts p }
end

exit 0
