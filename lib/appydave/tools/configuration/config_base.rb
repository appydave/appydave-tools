# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Configuration
      # Base class for handling common configuration tasks
      class ConfigBase
        attr_reader :config_path, :data

        def initialize(config_name = 'unknown')
          @config_path = File.join(Config.config_path, "#{config_name}.json")
          @data = load
        end

        def save
          File.write(config_path, JSON.pretty_generate(data))
        end

        def load
          return JSON.parse(File.read(config_path)) if File.exist?(config_path)

          default_data
        rescue JSON::ParserError
          default_data
        end

        def default_data
          {}
        end
      end
    end
  end
end
