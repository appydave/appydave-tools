# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Central configuration management for appydave-tools
      #
      # Thread-safe singleton pattern with memoization for registered configurations.
      # Calling `Config.configure` multiple times is safe and idempotent.
      #
      # @example Basic usage
      #   Config.configure  # Load default configuration (idempotent)
      #   Config.settings.video_projects_root  # Access settings
      #   Config.brands.get_brand('appydave')  # Access brands
      #
      # @example DAM module usage pattern
      #   # Config.configure called once at module load time
      #   # All subsequent calls within DAM classes are no-ops (memoized)
      #   def some_method
      #     Config.configure  # Safe to call - returns immediately if already configured
      #     brand = Config.brands.get_brand('appydave')
      #   end
      #
      # @example Registered configurations
      #   Config.settings         # => SettingsConfig instance
      #   Config.brands           # => BrandsConfig instance
      #   Config.channels         # => ChannelsConfig instance
      #   Config.youtube_automation  # => YoutubeAutomationConfig instance
      #
      # @note Configuration instances are created once on first registration and reused
      #   for all subsequent accesses. This prevents unnecessary file I/O and ensures
      #   consistent state across the application.
      class Config
        class << self
          include KLog::Logging

          attr_accessor :config_path
          attr_reader :configurations
          attr_reader :default_block

          # Load configuration using either provided block or default configuration
          #
          # This method is idempotent and thread-safe. Calling it multiple times
          # has no negative side effects - configurations are memoized on first call.
          #
          # @yield [Config] configuration object for manual setup
          # @return [void]
          # @raise [Error] if no block provided and no default_block set
          #
          # @example With block (manual configuration)
          #   Config.configure do |config|
          #     config.config_path = '/custom/path'
          #     config.register(:settings, SettingsConfig)
          #   end
          #
          # @example Without block (uses default_block)
          #   Config.set_default { |config| config.register(:settings, SettingsConfig) }
          #   Config.configure  # Uses default_block
          #   Config.configure  # Safe to call again - no-op due to memoization
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

          # Register a configuration class with memoization
          #
          # Creates a single instance of the configuration class on first call.
          # Subsequent calls return the same instance (memoized). This prevents
          # unnecessary file I/O and ensures consistent configuration state.
          #
          # @param key [Symbol] configuration identifier (e.g., :settings, :brands)
          # @param klass [Class] configuration class to instantiate
          # @return [Object] configuration instance
          #
          # @example
          #   Config.register(:settings, SettingsConfig)
          #   Config.settings  # => SettingsConfig instance (created on first access)
          #   Config.settings  # => Same instance (memoized)
          #
          # @note This method implements lazy initialization - the configuration
          #   instance is only created when first accessed, not at registration time.
          def register(key, klass)
            @configurations ||= {}
            # Only create new instance if not already registered (prevents multiple reloads)
            @configurations[key] ||= klass.new
          end

          # Reset all configurations (primarily for testing)
          #
          # Clears all memoized configuration instances. Use this in test teardown
          # to ensure each test starts with a clean configuration state.
          #
          # @return [void]
          #
          # @example RSpec usage
          #   after { Config.reset }
          def reset
            @configurations = nil
          end

          # Dynamic accessor for registered configurations
          #
          # Provides method-style access to registered configuration instances.
          # Called when accessing Config.settings, Config.brands, etc.
          #
          # @param method_name [Symbol] configuration key
          # @return [Object] configuration instance
          # @raise [Error] if configurations not registered or key not found
          def method_missing(method_name, *_args)
            raise Appydave::Tools::Error, 'Configuration has never been registered' if @configurations.nil?
            raise Appydave::Tools::Error, "Configuration not available: #{method_name}" unless @configurations.key?(method_name)

            @configurations[method_name]
          end

          def respond_to_missing?(method_name, include_private = false)
            @configurations.key?(method_name) || super
          end

          # Save all registered configurations to their respective files
          # @return [void]
          def save
            configurations.each_value(&:save)
          end

          # Set default configuration block used when configure called without block
          # @yield [Config] configuration block to execute by default
          # @return [Proc] the stored block
          def set_default(&block)
            @default_block = block
          end

          # Load all registered configurations from their respective files
          # @return [void]
          def load
            configurations.each_value(&:load)
          end

          # Open configuration directory in VS Code
          # @return [void]
          def edit
            ensure_config_directory
            puts "Edit configuration: #{config_path}"
            open_vscode = "code  --folder-uri '#{config_path}'" # --new-window
            Open3.capture3(open_vscode)
          end

          # Debug output for all configurations
          # @return [void]
          def debug
            log.kv 'Configuration Path', config_path
            configurations.each_value(&:debug)
          end

          # def print
          #   log.kv 'Configuration Path', config_path
          #   configurations.each_value(&:print)
          # end

          # Print specific configurations or all if no keys provided
          # @param keys [Array<String, Symbol>] configuration keys to print
          # @return [void]
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
