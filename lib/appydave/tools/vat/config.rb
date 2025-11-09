# frozen_string_literal: true

module Appydave
  module Tools
    module Vat
      # VatConfig - Configuration management for Video Asset Tools
      #
      # Manages VIDEO_PROJECTS_ROOT and brand path resolution
      class Config
        class << self
          # Get the root directory for all video projects
          # @return [String] Absolute path to video-projects directory
          def projects_root
            # Use settings.json configuration
            Appydave::Tools::Configuration::Config.configure
            root = Appydave::Tools::Configuration::Config.settings.video_projects_root

            return root if root && !root.empty? && Dir.exist?(root)

            # Fall back to auto-detection if not configured
            detect_projects_root
          end

          # Get the full path to a brand directory
          # @param brand_key [String] Brand key (e.g., 'appydave', 'voz')
          # @return [String] Absolute path to brand directory
          def brand_path(brand_key)
            Appydave::Tools::Configuration::Config.configure
            brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_key)

            # If brand has configured video_projects path, use it
            return brand_info.locations.video_projects if brand_info.locations.video_projects && !brand_info.locations.video_projects.empty? && Dir.exist?(brand_info.locations.video_projects)

            # Fall back to projects_root + expanded brand name
            brand = expand_brand(brand_key)
            path = File.join(projects_root, brand)

            raise "Brand directory not found: #{path}\nAvailable brands: #{available_brands.join(', ')}" unless Dir.exist?(path)

            path
          end

          # Expand brand shortcut to full brand name
          # Reads from brands.json if available, falls back to hardcoded shortcuts
          # @param shortcut [String] Brand shortcut (e.g., 'appydave')
          # @return [String] Full brand name (e.g., 'v-appydave')
          def expand_brand(shortcut)
            return shortcut if shortcut.start_with?('v-')

            # Try to read from brands.json
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands

            # Check if this shortcut exists in brands.json
            if brands_config.shortcut?(shortcut)
              brand = brands_config.brands.find { |b| b.shortcut == shortcut }
              return "v-#{brand.key}" if brand
            end

            # Fall back to hardcoded shortcuts for backwards compatibility
            case shortcut
            when 'joy' then 'v-beauty-and-joy'
            when 'ss' then 'v-supportsignal'
            else
              "v-#{shortcut}"
            end
          end

          # Get list of available brands
          # Reads from brands.json if available, falls back to filesystem scan
          # @return [Array<String>] List of brand shortcuts
          def available_brands
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands

            # If brands are configured in brands.json, use those
            configured_brands = brands_config.brands
            return configured_brands.map(&:shortcut).sort unless configured_brands.empty?

            # Fall back to filesystem scan
            root = projects_root
            return [] unless Dir.exist?(root)

            Dir.glob("#{root}/v-*")
               .select { |path| File.directory?(path) }
               .reject { |path| File.basename(path) == 'v-shared' } # Exclude infrastructure
               .select { |path| valid_brand?(path) }
               .map { |path| File.basename(path) }
               .map { |brand| brand.sub(/^v-/, '') }
               .sort
          end

          # Check if directory is a valid brand
          # @param brand_path [String] Full path to potential brand directory
          # @return [Boolean] true if valid brand
          def valid_brand?(brand_path)
            # A valid brand is a v-* directory that contains project subdirectories
            # (This allows brands in development without .video-tools.env yet)

            # Must have at least one subdirectory that looks like a project
            Dir.glob("#{brand_path}/*")
               .select { |path| File.directory?(path) }
               .reject { |path| File.basename(path).start_with?('.', '_') }
               .any?
          end

          # Validate that VIDEO_PROJECTS_ROOT is configured
          # @return [Boolean] true if configured and exists
          def configured?
            Appydave::Tools::Configuration::Config.configure
            root = Appydave::Tools::Configuration::Config.settings.video_projects_root
            !root.nil? && !root.empty? && Dir.exist?(root)
          end

          private

          # Auto-detect projects root by finding git repos
          # @return [String] Detected path or raises error
          def detect_projects_root
            # Try to find v-shared in parent directories
            current = Dir.pwd
            5.times do
              test_path = File.join(current, 'v-shared')
              return File.dirname(test_path) if Dir.exist?(test_path) && Dir.exist?(File.join(test_path, 'video-asset-tools'))

              parent = File.dirname(current)
              break if parent == current

              current = parent
            end

            raise <<~ERROR
              ❌ VIDEO_PROJECTS_ROOT not configured!

              Configure it using:
                ad_config -e

              Then add to settings.json:
                "video-projects-root": "/path/to/your/video-projects"

              Or use ad_config command:
                # (From Ruby console)
                config = Appydave::Tools::Configuration::Config
                config.configure
                config.settings.set('video-projects-root', '/path/to/your/video-projects')
                config.save
            ERROR
          end
        end
      end
    end
  end
end
