# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'simplecov'

SimpleCov.start

require 'appydave/tools'

Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
  config.register(:settings, Appydave::Tools::Configuration::SettingsConfig)
  config.register(:channels, Appydave::Tools::Configuration::ChannelsConfig)
  config.register(:channel_projects, Appydave::Tools::Configuration::ChannelProjectsConfig)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
