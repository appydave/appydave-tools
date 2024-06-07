# frozen_string_literal: true

require 'clipboard'
require 'csv'
require 'fileutils'
require 'json'
require 'open3'
require 'openai'
require 'optparse'
require 'k_log'

require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'webrick'

require 'pry'

require 'appydave/tools/version'
require 'appydave/tools/indifferent_access_hash'

require 'appydave/tools/gpt_context/file_collector'

require 'appydave/tools/configuration/openai'
require 'appydave/tools/configuration/configurable'
require 'appydave/tools/configuration/config'
require 'appydave/tools/configuration/models/config_base'
require 'appydave/tools/configuration/models/settings_config'
require 'appydave/tools/configuration/models/bank_reconciliation_config'
require 'appydave/tools/configuration/models/channels_config'
require 'appydave/tools/name_manager/project_name'
require 'appydave/tools/bank_reconciliation/clean/clean_transactions'
require 'appydave/tools/bank_reconciliation/clean/read_transactions'
require 'appydave/tools/bank_reconciliation/clean/mapper'
require 'appydave/tools/bank_reconciliation/models/transaction'

require 'appydave/tools/subtitle_master/clean'

require 'appydave/tools/youtube_manager/youtube_base'
require 'appydave/tools/youtube_manager/authorization'
require 'appydave/tools/youtube_manager/get_video'
require 'appydave/tools/youtube_manager/reports/video_details_report'
require 'appydave/tools/youtube_manager/reports/video_content_report'

Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = File.expand_path('~/.config/appydave')
  config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
  config.register(:bank_reconciliation, Appydave::Tools::Configuration::Models::BankReconciliationConfig)
  config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
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
