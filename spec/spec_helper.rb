# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'simplecov'

SimpleCov.start

require 'appydave/tools'
require 'webmock/rspec'
require 'vcr' # ChatGPT: https://chatgpt.com/c/f7dc1eee-a11a-4969-8ce1-f51f56cf7103

# Load shared helpers
require_relative 'support/dam_filesystem_helpers'
require_relative 'support/jump_test_helpers'

Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
  config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
  config.register(:brands, Appydave::Tools::Configuration::Models::BrandsConfig)
  config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
  config.register(:youtube_automation, Appydave::Tools::Configuration::Models::YoutubeAutomationConfig)
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
