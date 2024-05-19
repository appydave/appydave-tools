# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Configuration class for handling multiple configurations
      class Config
        class << self
          include KLog::Logging

          attr_accessor :config_path
          attr_reader :configurations

          def configure
            yield self
            ensure_config_directory
          end

          def register(key, klass)
            @configurations ||= {}
            @configurations[key] = klass.new
          end

          def method_missing(method_name, *args, &block)
            if @configurations.key?(method_name)
              @configurations[method_name]
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            @configurations.key?(method_name) || super
          end

          def save
            configurations.each_value(&:save)
          end

          def load
            configurations.each_value(&:load)
          end

          def edit
            ensure_config_directory
            puts "Edit configuration: #{config_path}"
            open_vscode = "code  --folder-uri '#{config_path}'" # --new-window
            Open3.capture3(open_vscode)
          end

          def debug
            log.kv 'Configuration Path', config_path
            configurations.each_value(&:debug)
          end

          private

          def ensure_config_directory
            FileUtils.mkdir_p(config_path) unless File.directory?(config_path)
          end
        end

        self.config_path = File.expand_path('~/.config/appydave') # set default configuration path
      end
    end
  end
end

# Configuration example usage
# Appydave::Tools::Configuration::Config.configure do |config|
#   config.config_path = File.expand_path('~/.config/appydave') # optional, as this is already the default
#   # config.register(:settings, SettingsConfig)
#   # config.register(:gpt_context, GptContextConfig)
#   # Additional configurations can be registered as needed.
# end
