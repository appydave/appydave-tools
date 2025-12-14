# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      # Config manages the locations.json configuration file
      #
      # Follows the same pattern as other configuration models in appydave-tools,
      # using ConfigBase for file loading/saving with automatic backups.
      #
      # @example Basic usage
      #   config = Config.new
      #   config.locations          # => Array of Location objects
      #   config.brands             # => Hash of brand definitions
      #   config.find('ad-tools')   # => Location or nil
      class Config
        include KLog::Logging

        CONFIG_VERSION = '1.0'
        DEFAULT_CONFIG_NAME = 'locations'

        attr_reader :data, :config_path

        def initialize(config_path: nil)
          @config_path = config_path || default_config_path
          @data = load_config
        end

        # Get all locations as Location objects
        #
        # @return [Array<Location>]
        def locations
          @locations ||= (data['locations'] || []).map { |loc| Location.new(loc) }
        end

        # Reload locations from data (after modifications)
        def reload_locations
          @locations = nil
          locations
        end

        # Get brand definitions
        #
        # @return [Hash]
        def brands
          data['brands'] || {}
        end

        # Get client definitions
        #
        # @return [Hash]
        def clients
          data['clients'] || {}
        end

        # Get category definitions
        #
        # @return [Hash]
        def categories
          data['categories'] || {}
        end

        # Get metadata
        #
        # @return [Hash]
        def meta
          data['meta'] || {}
        end

        # Find a location by key
        #
        # @param key [String] Location key
        # @return [Location, nil]
        def find(key)
          locations.find { |loc| loc.key == key }
        end

        # Check if a location key exists
        #
        # @param key [String] Location key
        # @return [Boolean]
        def key_exists?(key)
          locations.any? { |loc| loc.key == key }
        end

        # Add a new location
        #
        # @param location [Location, Hash] Location to add
        # @return [Boolean] true if added successfully
        # @raise [ArgumentError] if key already exists or location is invalid
        def add(location)
          location = Location.new(location) if location.is_a?(Hash)

          raise ArgumentError, "Location key '#{location.key}' already exists" if key_exists?(location.key)

          errors = location.validate
          raise ArgumentError, "Invalid location: #{errors.join(', ')}" unless errors.empty?

          data['locations'] ||= []
          data['locations'] << location.to_h
          reload_locations
          true
        end

        # Update an existing location
        #
        # @param key [String] Key of location to update
        # @param attrs [Hash] Attributes to update
        # @return [Boolean] true if updated successfully
        # @raise [ArgumentError] if location not found or updates are invalid
        def update(key, attrs)
          index = (data['locations'] || []).find_index { |loc| loc['key'] == key || loc[:key] == key }
          raise ArgumentError, "Location '#{key}' not found" if index.nil?

          # Merge attributes
          current = data['locations'][index].transform_keys(&:to_sym)
          updated_attrs = current.merge(attrs.transform_keys(&:to_sym))

          # Validate
          updated = Location.new(updated_attrs)
          errors = updated.validate
          raise ArgumentError, "Invalid update: #{errors.join(', ')}" unless errors.empty?

          data['locations'][index] = updated.to_h.transform_keys(&:to_s)
          reload_locations
          true
        end

        # Remove a location by key
        #
        # @param key [String] Key of location to remove
        # @return [Boolean] true if removed
        # @raise [ArgumentError] if location not found
        def remove(key)
          index = (data['locations'] || []).find_index { |loc| loc['key'] == key || loc[:key] == key }
          raise ArgumentError, "Location '#{key}' not found" if index.nil?

          data['locations'].delete_at(index)
          reload_locations
          true
        end

        # Save configuration to file with backup
        #
        # @return [void]
        def save
          # Create backup if file exists
          if File.exist?(config_path)
            backup_path = "#{config_path}.backup.#{Time.now.strftime('%Y%m%d-%H%M%S')}"
            FileUtils.cp(config_path, backup_path)
          end

          # Update timestamp
          data['meta'] ||= {}
          data['meta']['version'] = CONFIG_VERSION
          data['meta']['last_updated'] = Time.now.utc.iso8601

          # Ensure directory exists
          FileUtils.mkdir_p(File.dirname(config_path))

          # Write atomically (temp file then rename)
          temp_path = "#{config_path}.tmp"
          File.write(temp_path, JSON.pretty_generate(data))
          File.rename(temp_path, config_path)
        end

        # Update validation timestamp
        #
        # @return [void]
        def touch_validated
          data['meta'] ||= {}
          data['meta']['last_validated'] = Time.now.utc.iso8601
        end

        # Get info about the configuration
        #
        # @return [Hash]
        def info
          {
            config_path: config_path,
            exists: File.exist?(config_path),
            version: meta['version'],
            last_updated: meta['last_updated'],
            last_validated: meta['last_validated'],
            location_count: locations.size,
            brand_count: brands.size,
            client_count: clients.size
          }
        end

        private

        def default_config_path
          File.join(Configuration::Config.config_path, "#{DEFAULT_CONFIG_NAME}.json")
        end

        def load_config
          return default_data unless File.exist?(config_path)

          content = File.read(config_path)
          JSON.parse(content)
        rescue JSON::ParserError => e
          log.error "JSON parse error in #{config_path}: #{e.message}"
          default_data
        rescue StandardError => e
          log.error "Error loading #{config_path}: #{e.message}"
          default_data
        end

        def default_data
          {
            'meta' => {
              'version' => CONFIG_VERSION
            },
            'categories' => {
              'type' => {
                'description' => 'Kind of location',
                'values' => %w[brand client gem video brain site tool config]
              },
              'technology' => {
                'description' => 'Primary language/framework',
                'values' => %w[ruby javascript typescript python astro]
              }
            },
            'brands' => {},
            'clients' => {},
            'locations' => []
          }
        end
      end
    end
  end
end
