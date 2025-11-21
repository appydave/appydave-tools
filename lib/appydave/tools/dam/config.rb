# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
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

            unless Dir.exist?(path)
              brands_list = available_brands_display
              raise "Brand directory not found: #{path}\nAvailable brands:\n#{brands_list}"
            end

            path
          end

          # Get the full path to a project directory, respecting brand's projects_subfolder setting
          # @param brand_key [String] Brand key (e.g., 'appydave', 'supportsignal')
          # @param project_id [String] Project ID (e.g., 'b64-bmad-claude-sdk', 'a01-shocking-stat-v1')
          # @return [String] Absolute path to project directory
          def project_path(brand_key, project_id)
            Appydave::Tools::Configuration::Config.configure
            brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_key)
            brand_dir = brand_path(brand_key)

            if brand_info.settings.projects_subfolder && !brand_info.settings.projects_subfolder.empty?
              File.join(brand_dir, brand_info.settings.projects_subfolder, project_id)
            else
              File.join(brand_dir, project_id)
            end
          end

          # Get git remote URL for a brand (with self-healing)
          # @param brand_key [String] Brand key (e.g., 'appydave', 'voz')
          # @return [String, nil] Git remote URL or nil if not a git repo
          def git_remote(brand_key)
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands
            brand_info = brands_config.get_brand(brand_key)

            # 1. Check if git_remote is already configured
            return brand_info.git_remote if brand_info.git_remote && !brand_info.git_remote.empty?

            # 2. Try to infer from git command
            brand_path_dir = brand_path(brand_key)
            inferred_remote = infer_git_remote(brand_path_dir)

            # 3. Auto-save if inferred successfully
            if inferred_remote
              brand_info.git_remote = inferred_remote
              brands_config.set_brand(brand_info.key, brand_info)
              brands_config.save
            end

            inferred_remote
          end

          # Expand brand shortcut to full brand name
          # Delegates to BrandResolver for centralized brand resolution
          # @param shortcut [String] Brand shortcut (e.g., 'appydave', 'ad', 'APPYDAVE')
          # @return [String] Full brand name (e.g., 'v-appydave')
          def expand_brand(shortcut)
            BrandResolver.expand(shortcut)
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

          # Get available brands with both shortcut and name for error messages
          def available_brands_display
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands

            brands_config.brands.map do |brand|
              "  #{brand.shortcut.ljust(10)} - #{brand.name}"
            end.sort.join("\n")
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

          # Auto-detect projects root by finding v-shared directory
          # @return [String] Detected path or raises error
          def detect_projects_root
            # Try to find v-shared in parent directories
            current = Dir.pwd
            5.times do
              test_path = File.join(current, 'v-shared')
              # Return parent of v-shared as projects root
              return File.dirname(test_path) if Dir.exist?(test_path)

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

          # Infer git remote URL from git repository
          # @param path [String] Path to git repository
          # @return [String, nil] Remote URL or nil if not a git repo
          def infer_git_remote(path)
            return nil unless Dir.exist?(path)

            # Try to get git remote URL
            result = `git -C "#{path}" remote get-url origin 2>/dev/null`.strip
            result.empty? ? nil : result
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
