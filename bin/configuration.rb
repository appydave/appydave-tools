#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'pry'
require 'appydave/tools'

options = {}

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

  opts.on('-p', '--print', 'Print configuration details') do
    options[:command] = :print
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
  tp configurations, :name, :exists, { config_path => { column_width: 150 } }
when :create
  Appydave::Tools::Configuration::Config.configure
  Appydave::Tools::Configuration::Config.save
when :print
  Appydave::Tools::Configuration::Config.configure
  Appydave::Tools::Configuration::Config.print
else
  puts 'No valid command provided. Use --help for usage information.'
end
