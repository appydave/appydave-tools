# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Configuration
      # Base class for handling common configuration tasks
      class ConfigBase
        attr_reader :config_path, :data

        def initialize(config_name)
          @config_path = File.join(Config.config_path, "#{config_name}.json")
          @data = load
        end

        def save
          File.write(config_path, JSON.pretty_generate(data))
        end

        def load
          return JSON.parse(File.read(config_path)) if File.exist?(config_path)

          {}
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
