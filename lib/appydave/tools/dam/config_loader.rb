# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Configuration loader for video asset tools
      # Loads settings from .video-tools.env file in the repository root
      #
      # Usage:
      #   config = ConfigLoader.load_from_repo(repo_path)
      #   ssd_base = config['SSD_BASE']
      class ConfigLoader
        class ConfigNotFoundError < StandardError; end
        class InvalidConfigError < StandardError; end

        CONFIG_FILENAME = '.video-tools.env'
        REQUIRED_KEYS = %w[SSD_BASE].freeze

        class << self
          # Load configuration from a repository path
          # @param repo_path [String] Path to the video project repository
          # @return [Hash] Configuration hash
          def load_from_repo(repo_path)
            config_path = File.join(repo_path, CONFIG_FILENAME)

            unless File.exist?(config_path)
              raise ConfigNotFoundError, <<~ERROR
                ❌ Configuration file not found: #{config_path}

                Create a .video-tools.env file in your repository root with:

                SSD_BASE=/Volumes/T7/youtube-PUBLISHED/appydave

                See .env.example for a full template.
              ERROR
            end

            config = parse_env_file(config_path)
            validate_config!(config)
            config
          end

          private

          # Parse a .env file into a hash
          # @param file_path [String] Path to .env file
          # @return [Hash] Parsed key-value pairs
          def parse_env_file(file_path)
            config = {}

            File.readlines(file_path).each do |line|
              line = line.strip

              # Skip comments and empty lines
              next if line.empty? || line.start_with?('#')

              # Parse KEY=value
              next unless line =~ /^([A-Z_]+)=(.*)$/

              key = ::Regexp.last_match(1)
              value = ::Regexp.last_match(2)

              # Remove quotes if present
              value = value.gsub(/^["']|["']$/, '')

              config[key] = value
            end

            config
          end

          # Validate required configuration keys
          # @param config [Hash] Configuration to validate
          # @raise [InvalidConfigError] if required keys are missing
          def validate_config!(config)
            missing_keys = REQUIRED_KEYS - config.keys

            return if missing_keys.empty?

            raise InvalidConfigError, <<~ERROR
              ❌ Missing required configuration keys: #{missing_keys.join(', ')}

              Your .video-tools.env must include:
              #{REQUIRED_KEYS.map { |k| "  #{k}=..." }.join("\n")}
            ERROR
          end
        end
      end
    end
  end
end
