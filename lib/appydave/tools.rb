# frozen_string_literal: true

require 'clipboard'
require 'csv'
require 'fileutils'
require 'json'
require 'open3'
require 'openai'
require 'optparse'
require 'pathname'
require 'k_log'
require 'active_model'

require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'webrick'

require 'appydave/tools/version'
require 'appydave/tools/debuggable'
require 'appydave/tools/types/indifferent_access_hash'
require 'appydave/tools/types/hash_type'
require 'appydave/tools/types/array_type'
require 'appydave/tools/types/base_model'

require 'appydave/tools/llm/models/llm_info'
require 'appydave/tools/llm/openai_completion'

require 'appydave/tools/cli_actions/base_action'

# May want to move this into the tools location
require 'appydave/tools/cli_actions/prompt_completion_action'
require 'appydave/tools/cli_actions/get_video_action'
require 'appydave/tools/cli_actions/update_video_action'

require 'appydave/tools/gpt_context/options'
require 'appydave/tools/gpt_context/file_collector'
require 'appydave/tools/gpt_context/output_handler'

require 'appydave/tools/configuration/openai'
require 'appydave/tools/configuration/configurable'
require 'appydave/tools/configuration/config'
require 'appydave/tools/configuration/models/config_base'
require 'appydave/tools/configuration/models/settings_config'
require 'appydave/tools/configuration/models/brands_config'
require 'appydave/tools/configuration/models/channels_config'
require 'appydave/tools/configuration/models/youtube_automation_config'
require 'appydave/tools/name_manager/project_name'

require 'appydave/tools/prompt_tools/prompt_completion'

require 'appydave/tools/subtitle_processor/clean'
require 'appydave/tools/subtitle_processor/join'

require 'appydave/tools/vat/config'
require 'appydave/tools/vat/project_resolver'
require 'appydave/tools/vat/config_loader'
require 'appydave/tools/vat/s3_operations'
require 'appydave/tools/vat/project_listing'
require 'appydave/tools/vat/manifest_generator'

require 'appydave/tools/youtube_automation/gpt_agent'

require 'appydave/tools/youtube_manager/models/youtube_details'
require 'appydave/tools/youtube_manager/models/captions'
require 'appydave/tools/youtube_manager/youtube_base'
require 'appydave/tools/youtube_manager/authorization'
require 'appydave/tools/youtube_manager/get_video'
require 'appydave/tools/youtube_manager/update_video'
require 'appydave/tools/youtube_manager/reports/video_details_report'
require 'appydave/tools/youtube_manager/reports/video_content_report'

Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = File.expand_path('~/.config/appydave')
  config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
  config.register(:brands, Appydave::Tools::Configuration::Models::BrandsConfig)
  config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
  config.register(:youtube_automation, Appydave::Tools::Configuration::Models::YoutubeAutomationConfig)
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
