#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

options = {
  sequence: nil,
  debug: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: youtube_automation.rb [options]'

  opts.on('-s', '--sequence SEQUENCE', 'Sequence number (e.g., 01-1)') do |sequence|
    options[:sequence] = sequence
  end

  opts.on('-d', '--debug', 'Enable debug mode') do
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

if options[:sequence].nil?
  puts 'Error: Sequence number is required. Use -h for help.'
  exit 1
end

Appydave::Tools::Configuration::Config.configure

automation = Appydave::Tools::YoutubeAutomation::GptAgent.new(options[:sequence], options[:debug])
automation.run
