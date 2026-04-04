#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'
require 'optparse'

options = { meta: false, config: nil }

OptionParser.new do |opts|
  opts.banner = 'Usage: random_context [options]'

  opts.on('--meta', 'Return metadata as JSON instead of file paths') do
    options[:meta] = true
  end

  opts.on('--config PATH', 'Path to custom random-queries.yml config') do |path|
    options[:config] = path
  end

  opts.on('-v', '--version', 'Show version') do
    puts "random_context v#{Appydave::Tools::VERSION}"
    exit 0
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    exit 0
  end
end.parse!

randomizer_opts = { meta: options[:meta] }
randomizer_opts[:config_path] = options[:config] if options[:config]

Appydave::Tools::RandomContext::Randomizer.new(**randomizer_opts).run

exit 0
