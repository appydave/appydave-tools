# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'simplecov'

SimpleCov.start

require 'appydave/tools'
require 'webmock/rspec'
require 'vcr'

Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
  config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
  config.register(:bank_reconciliation, Appydave::Tools::Configuration::Models::BankReconciliationConfig)
  config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus

  # I enable tools during course development, this is not turned on in CI
  config.filter_run_excluding :tools_enabled unless ENV['TOOLS_ENABLED'] == 'true'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    if ENV['TOOLS_ENABLED'] == 'true'
      # Can turn on if tools enabled flag is active, this is a manual flag that you can set in RSpec context/describe block
      WebMock.allow_net_connect!
    else
      # Disable all external connections on CI
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end
end
