# frozen_string_literal: true

require 'clipboard'
require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'k_log'

require 'appydave/tools/version'
require 'appydave/tools/gpt_context/file_collector'

require 'appydave/tools/configuration/configurable'
require 'appydave/tools/configuration/config_base'
require 'appydave/tools/configuration/config'
require 'appydave/tools/configuration/settings_config'
require 'appydave/tools/configuration/channel_projects_config'
require 'appydave/tools/configuration/channels_config'
require 'appydave/tools/name_manager/project_name'

Appydave::Tools::Configuration::Config.configure do |config|
  config.register(:settings, Appydave::Tools::Configuration::SettingsConfig)
  config.register(:channels, Appydave::Tools::Configuration::ChannelsConfig)
  config.register(:channel_projects, Appydave::Tools::Configuration::ChannelProjectsConfig)
end

module Appydave
  module Tools
    # raise Appydave::Tools::Error, 'Sample message'
    Error = Class.new(StandardError)

    # Your code goes here...
  end
end

if ENV.fetch('KLUE_DEBUG', 'false').downcase == 'true'
  $LOADED_FEATURES.find { |f| f.include?('appydave/tools/version') }
  Appydave::Tools::VERSION.ljust(9)
  # puts "#{namespace.ljust(35)} : #{version.ljust(9)} : #{file_path}"
end
