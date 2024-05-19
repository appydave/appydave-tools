# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Configuration
      # Base class for handling common configuration tasks
      class ConfigBase
        include KLog::Logging

        attr_reader :config_path, :data

        def initialize
          @config_path = File.join(Config.config_path, "#{config_name}.json")
          @data = load
        end

        def save
          File.write(config_path, JSON.pretty_generate(data))
        end

        def load
          return JSON.parse(File.read(config_path)) if File.exist?(config_path)

          default_data
        rescue JSON::ParserError => e
          # log.exception e
          default_data
        end

        def name
          self.class.name.split('::')[-1].gsub(/Config$/, '')
        end

        def config_name
          name.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
        end

        def debug
          log.kv 'Config', name
          log.kv 'Path', config_path

          log.json data
        end

        private

        def default_data
          {}
        end
      end
    end
  end
end
