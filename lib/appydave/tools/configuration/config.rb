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
          attr_reader :default_block

          def configure
            if block_given?
              yield self
            elsif default_block
              default_block.call(self)
            else
              raise Appydave::Tools::Error, 'No configuration block provided'
            end
            ensure_config_directory
          end

          def register(key, klass)
            @configurations ||= {}
            @configurations[key] = klass.new
          end

          def method_missing(method_name, *_args)
            raise Appydave::Tools::Error, 'Configuration has never been registered' if @configurations.nil?
            raise Appydave::Tools::Error, "Configuration not available: #{method_name}" unless @configurations.key?(method_name)

            @configurations[method_name]
          end

          def respond_to_missing?(method_name, include_private = false)
            @configurations.key?(method_name) || super
          end

          def save
            configurations.each_value(&:save)
          end

          def set_default(&block)
            @default_block = block
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

          # def print
          #   log.kv 'Configuration Path', config_path
          #   configurations.each_value(&:print)
          # end

          def print(*keys)
            if keys.empty?
              keys = configurations.keys
            else
              keys.map!(&:to_sym)
            end

            keys.each do |key|
              if configurations[key]
                configurations[key].print
              else
                log.error "Configuration not available: #{key}"
              end
            end
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
