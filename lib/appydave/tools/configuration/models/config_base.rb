# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Configuration
      module Models
        # Base class for handling common configuration tasks
        class ConfigBase
          include KLog::Logging

          attr_reader :config_path, :data

          def initialize
            @config_path = File.join(Config.config_path, "#{config_name}.json")
            # puts "Config path: #{config_path}"
            @data = load
          end

          def save
            # Create backup if file exists (silent for self-healing operations)
            if File.exist?(config_path)
              backup_path = "#{config_path}.backup.#{Time.now.strftime('%Y%m%d-%H%M%S')}"
              FileUtils.cp(config_path, backup_path)
            end

            File.write(config_path, JSON.pretty_generate(data))
          end

          def load
            if debug_mode?
              log.info "Loading config: #{config_name}"
              log.info "Config path: #{config_path}"
              log.info "File exists: #{File.exist?(config_path)}"
            end

            unless File.exist?(config_path)
              log.warn "Config file not found: #{config_path}" if debug_mode?
              return default_data
            end

            content = File.read(config_path)
            log.info "Config file size: #{content.bytesize} bytes" if debug_mode?

            data = JSON.parse(content)
            log.info "Config loaded successfully: #{config_name}" if debug_mode?
            log.json data if debug_mode?
            data
          rescue JSON::ParserError => e
            log.error "JSON parse error in #{config_path}: #{e.message}"
            log.error "File content preview: #{content[0..200]}" if content
            default_data
          rescue StandardError => e
            log.error "Error loading #{config_path}: #{e.message}"
            log.error e.backtrace.first(3).join("\n") if debug_mode?
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

          def debug_mode?
            ENV['DAM_DEBUG'] == 'true' || ENV['DEBUG'] == 'true'
          end

          def default_data
            {}
          end
        end
      end
    end
  end
end
