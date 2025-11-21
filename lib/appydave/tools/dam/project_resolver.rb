# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # ProjectResolver - Resolve short project names to full paths
      #
      # Handles:
      # - FliVideo pattern: b65 → b65-guy-monroe-marketing-plan
      # - Storyline pattern: boy-baker → boy-baker (exact match)
      # - Pattern matching: b6* → all b60-b69 projects
      class ProjectResolver
        class << self
          # Resolve project hint to full project name(s)
          # @param brand [String] Brand shortcut or full name
          # @param project_hint [String] Project name or pattern (e.g., 'b65', 'boy-baker', 'b6*')
          # @return [String, Array<String>] Full project name or array of names for patterns
          def resolve(brand, project_hint)
            raise '❌ Project name is required' if project_hint.nil? || project_hint.empty?

            # Check for pattern (wildcard)
            return resolve_pattern(brand, project_hint) if project_hint.include?('*')

            # Exact match first - use Config.project_path to respect projects_subfolder
            full_path = Config.project_path(brand, project_hint)
            return project_hint if Dir.exist?(full_path)

            # FliVideo pattern: b65 → b65-*
            if project_hint =~ /^[a-z]\d+$/
              projects_dir = projects_directory(brand)
              matches = Dir.glob("#{projects_dir}/#{project_hint}-*")
                           .select { |path| File.directory?(path) }
                           .map { |path| File.basename(path) }

              case matches.size
              when 0
                raise "❌ No project found matching '#{project_hint}' in #{Config.expand_brand(brand)}"
              when 1
                return matches.first
              else
                # Multiple matches - show and ask
                puts "⚠️  Multiple projects match '#{project_hint}':"
                matches.each_with_index do |match, idx|
                  puts "  #{idx + 1}. #{match}"
                end
                print "\nSelect project (1-#{matches.size}): "
                selection = $stdin.gets.to_i
                return matches[selection - 1] if selection.between?(1, matches.size)

                raise 'Invalid selection'
              end
            end

            # No match - return as-is (will error later if doesn't exist)
            project_hint
          end

          # Resolve pattern to list of matching projects
          # @param brand [String] Brand shortcut or full name
          # @param pattern [String] Pattern with wildcards (e.g., 'b6*')
          # @return [Array<String>] List of matching project names
          def resolve_pattern(brand, pattern)
            projects_dir = projects_directory(brand)
            matches = Dir.glob("#{projects_dir}/#{pattern}")
                         .select { |path| File.directory?(path) }
                         .select { |path| valid_project?(path) }
                         .map { |path| File.basename(path) }
                         .sort

            raise "❌ No projects found matching pattern '#{pattern}' in #{projects_dir}" if matches.empty?

            matches
          end

          # List all projects for a brand
          # @param brand [String] Brand shortcut or full name
          # @param pattern [String, nil] Optional filter pattern
          # @return [Array<String>] List of project names
          def list_projects(brand, pattern = nil)
            projects_dir = projects_directory(brand)

            glob_pattern = pattern || '*'
            Dir.glob("#{projects_dir}/#{glob_pattern}")
               .select { |path| File.directory?(path) }
               .select { |path| valid_project?(path) }
               .map { |path| File.basename(path) }
               .sort
          end

          # Check if directory is a valid project
          # @param project_path [String] Full path to potential project directory
          # @return [Boolean] true if valid project
          def valid_project?(project_path)
            basename = File.basename(project_path)

            # Exclude system/infrastructure directories
            excluded = %w[archived docs node_modules .git .github]
            return false if excluded.include?(basename)

            # Exclude organizational folders (for brands using projects_subfolder)
            # Including 'projects' because if it appears, it means projects_directory isn't working correctly
            organizational = %w[brand personas projects video-scripts]
            return false if organizational.include?(basename)

            # Exclude hidden and underscore-prefixed
            return false if basename.start_with?('.', '_')

            true
          end

          # Detect brand and project from current directory
          # @return [Array<String, String>] [brand_key, project] or [nil, nil]
          def detect_from_pwd
            current = Dir.pwd

            # Check if we're inside a v-* directory
            if current =~ %r{/(v-[^/]+)/([^/]+)/?}
              brand_with_prefix = ::Regexp.last_match(1)
              project = ::Regexp.last_match(2) # Capture BEFORE .sub() which resets Regexp.last_match
              # Strip 'v-' prefix to get brand key (e.g., 'v-supportsignal' → 'supportsignal')
              brand_key = brand_with_prefix.sub(/^v-/, '')
              return [brand_key, project] if project_exists?(brand_key, project)
            end

            [nil, nil]
          end

          # Check if project exists in brand directory
          # @param brand [String] Brand key (e.g., 'appydave', 'supportsignal')
          # @param project [String] Project name
          # @return [Boolean] true if project directory exists
          def project_exists?(brand, project)
            project_path = Config.project_path(brand, project)
            Dir.exist?(project_path)
          end

          private

          # Get the directory where projects are stored for a brand
          # Respects projects_subfolder setting
          # @param brand [String] Brand shortcut or full name
          # @return [String] Path to directory containing projects
          def projects_directory(brand)
            Appydave::Tools::Configuration::Config.configure
            brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand)
            brand_path = Config.brand_path(brand)

            subfolder = brand_info.settings.projects_subfolder
            puts "DEBUG projects_directory: brand=#{brand}, brand_info.key=#{brand_info.key}, subfolder='#{subfolder}'" if ENV['DEBUG']

            if subfolder && !subfolder.empty?
              result = File.join(brand_path, subfolder)
              puts "DEBUG projects_directory: returning #{result}" if ENV['DEBUG']
              result
            else
              puts "DEBUG projects_directory: returning brand_path #{brand_path}" if ENV['DEBUG']
              brand_path
            end
          end
        end
      end
    end
  end
end
