#!/usr/bin/env ruby
# frozen_string_literal: true

# Example of a simple command line tool to manage configuration files
# ad_config -p settings,channels
# ad_config -p
# ad_config -l
# ad_config -c
# ad_config -e

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'pry'
require 'appydave/tools'

options = { keys: [] }

OptionParser.new do |opts|
  opts.banner = 'Usage: config_tool.rb [options]'

  opts.on('-e', '--edit', 'Edit configuration in Visual Studio Code') do
    options[:command] = :edit
  end

  opts.on('-l', '--list', 'List all configurations') do
    options[:command] = :list
  end

  opts.on('-c', '--create', 'Create missing configurations') do
    options[:command] = :create
  end

  opts.on('-p', '--print [KEYS]', Array, 'Print configuration details for specified keys') do |keys|
    options[:command] = :print
    options[:keys] = keys
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

case options[:command]
when :edit
  Appydave::Tools::Configuration::Config.edit
when :list
  Appydave::Tools::Configuration::Config.configure
  configurations = Appydave::Tools::Configuration::Config.configurations.map do |name, config|
    { name: name, path: config.config_path, exists: File.exist?(config.config_path) }
  end
  tp configurations, :name, :exists, { path: { width: 150 } }
when :create
  Appydave::Tools::Configuration::Config.configure

  # Only save configs that don't exist yet
  created = []
  skipped = []

  Appydave::Tools::Configuration::Config.configurations.each do |name, config|
    if File.exist?(config.config_path)
      skipped << name
    else
      config.save
      created << name
    end
  end

  puts "\n✅ Created configurations:"
  created.each { |name| puts "  - #{name}" }

  if skipped.any?
    puts "\n⚠️  Skipped (already exist):"
    skipped.each { |name| puts "  - #{name}" }
  end
when :print
  Appydave::Tools::Configuration::Config.configure
  Appydave::Tools::Configuration::Config.print(*options[:keys])
else
  puts 'No valid command provided. Use --help for usage information.'
end
