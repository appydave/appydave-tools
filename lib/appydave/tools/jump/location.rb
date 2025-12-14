# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      # Location represents a single development folder location
      #
      # @example Creating a location
      #   location = Location.new(
      #     key: 'ad-tools',
      #     path: '~/dev/ad/appydave-tools',
      #     jump: 'jad-tools',
      #     brand: 'appydave',
      #     type: 'tool',
      #     tags: ['ruby', 'cli'],
      #     description: 'AppyDave CLI tools'
      #   )
      class Location
        VALID_KEY_PATTERN = /\A[a-z0-9][a-z0-9-]*[a-z0-9]\z|\A[a-z0-9]\z/.freeze
        VALID_PATH_PATTERN = %r{\A[~/]}.freeze
        VALID_TAG_PATTERN = /\A[a-z0-9][a-z0-9-]*[a-z0-9]\z|\A[a-z0-9]\z/.freeze

        attr_reader :key, :path, :jump, :brand, :client, :type, :tags, :description

        def initialize(attrs = {})
          attrs = normalize_attrs(attrs)

          @key = attrs[:key]
          @path = attrs[:path]
          @jump = attrs[:jump] || default_jump
          @brand = attrs[:brand]
          @client = attrs[:client]
          @type = attrs[:type]
          @tags = Array(attrs[:tags])
          @description = attrs[:description]
        end

        # Validate the location
        #
        # @return [Array<String>] List of validation errors (empty if valid)
        def validate
          errors = []
          errors << 'Key is required' if key.nil? || key.empty?
          errors << "Key '#{key}' is invalid (must be lowercase alphanumeric with hyphens)" if key && !valid_key?
          errors << 'Path is required' if path.nil? || path.empty?
          errors << "Path '#{path}' is invalid (must start with ~ or /)" if path && !valid_path?
          errors.concat(validate_tags)
          errors
        end

        # Check if location is valid
        #
        # @return [Boolean]
        def valid?
          validate.empty?
        end

        # Convert to hash for JSON serialization
        #
        # @return [Hash]
        def to_h
          {
            key: key,
            path: path,
            jump: jump,
            brand: brand,
            client: client,
            type: type,
            tags: tags,
            description: description
          }.compact
        end

        # Get all searchable text for this location
        #
        # @param brands [Hash] Brand definitions with aliases
        # @param clients [Hash] Client definitions with aliases
        # @return [Array<String>] All searchable terms
        def searchable_terms(brands: {}, clients: {})
          terms = [key, path, type, description].compact
          terms.concat(tags)

          # Add brand and its aliases
          if brand && brands[brand]
            terms << brand
            terms.concat(Array(brands[brand]['aliases'] || brands[brand][:aliases]))
          elsif brand
            terms << brand
          end

          # Add client and its aliases
          if client && clients[client]
            terms << client
            terms.concat(Array(clients[client]['aliases'] || clients[client][:aliases]))
          elsif client
            terms << client
          end

          terms.compact.map(&:to_s).map(&:downcase)
        end

        private

        def normalize_attrs(attrs)
          attrs.transform_keys(&:to_sym)
        end

        def default_jump
          return nil unless key

          "j#{key}"
        end

        def valid_key?
          key.match?(VALID_KEY_PATTERN)
        end

        def valid_path?
          path.match?(VALID_PATH_PATTERN)
        end

        def validate_tags
          errors = []
          tags.each do |tag|
            next if tag.match?(VALID_TAG_PATTERN)

            errors << "Tag '#{tag}' is invalid (must be lowercase alphanumeric with hyphens)"
          end
          errors
        end
      end
    end
  end
end
