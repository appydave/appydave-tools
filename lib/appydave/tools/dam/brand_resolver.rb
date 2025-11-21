# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Centralized brand name resolution and transformation
      #
      # Handles conversion between:
      # - Shortcuts: 'appydave', 'ad', 'joy', 'ss'
      # - Config keys: 'appydave', 'beauty-and-joy', 'supportsignal'
      # - Display names: 'v-appydave', 'v-beauty-and-joy', 'v-supportsignal'
      #
      # @example
      #   BrandResolver.expand('ad')          # => 'v-appydave'
      #   BrandResolver.normalize('v-voz')    # => 'voz'
      #   BrandResolver.to_config_key('ad')   # => 'appydave'
      #   BrandResolver.to_display('voz')     # => 'v-voz'
      class BrandResolver
        class << self
          # Expand shortcut or key to full display name
          # @param shortcut [String] Brand shortcut or key
          # @return [String] Full brand name with v- prefix
          def expand(shortcut)
            return shortcut.to_s if shortcut.to_s.start_with?('v-')

            key = to_config_key(shortcut)
            "v-#{key}"
          end

          # Normalize brand name to config key (strip v- prefix)
          # @param brand [String] Brand name (with or without v-)
          # @return [String] Config key without v- prefix
          def normalize(brand)
            brand.to_s.sub(/^v-/, '')
          end

          # Convert to config key (handles shortcuts)
          # @param input [String] Shortcut, key, or display name
          # @return [String] Config key
          def to_config_key(input)
            # Strip v- prefix first
            normalized = normalize(input)

            # Look up from brands.json
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands

            # Check if matches brand key (case-insensitive)
            brand = brands_config.brands.find { |b| b.key.downcase == normalized.downcase }
            return brand.key if brand

            # Check if matches shortcut (case-insensitive)
            brand = brands_config.brands.find { |b| b.shortcut.downcase == normalized.downcase }
            return brand.key if brand

            # Fall back to hardcoded shortcuts (backward compatibility)
            case normalized.downcase
            when 'ad' then 'appydave'
            when 'joy' then 'beauty-and-joy'
            when 'ss' then 'supportsignal'
            else
              normalized.downcase
            end
          end

          # Convert to display name (always v- prefix)
          # @param input [String] Shortcut, key, or display name
          # @return [String] Display name with v- prefix
          def to_display(input)
            expand(input)
          end

          # Validate brand exists in filesystem
          # @param brand [String] Brand to validate
          # @raise [BrandNotFoundError] if brand invalid
          # @return [String] Config key if valid
          def validate(brand)
            key = to_config_key(brand)

            # Build brand path (avoiding circular dependency with Config.brand_path)
            Appydave::Tools::Configuration::Config.configure
            brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(key)

            # If brand has configured video_projects path, use it
            if brand_info.locations.video_projects && !brand_info.locations.video_projects.empty?
              brand_path = brand_info.locations.video_projects
            else
              # Fall back to projects_root + expanded brand name
              root = Config.projects_root
              brand_path = File.join(root, expand(key))
            end

            unless Dir.exist?(brand_path)
              available = Config.available_brands_display
              raise BrandNotFoundError.new(brand, available)
            end

            key
          rescue StandardError => e
            raise BrandNotFoundError, e.message unless e.is_a?(BrandNotFoundError)

            raise
          end

          # Check if brand exists (returns boolean instead of raising)
          # @param brand [String] Brand to check
          # @return [Boolean] true if brand exists
          def exists?(brand)
            validate(brand)
            true
          rescue BrandNotFoundError
            false
          end
        end
      end
    end
  end
end
