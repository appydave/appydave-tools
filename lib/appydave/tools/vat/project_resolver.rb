# frozen_string_literal: true

module Appydave
  module Tools
    module Vat
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
            brand_path = Config.brand_path(brand)

            # Check for pattern (wildcard)
            return resolve_pattern(brand_path, project_hint) if project_hint.include?('*')

            # Exact match first
            full_path = File.join(brand_path, project_hint)
            return project_hint if Dir.exist?(full_path)

            # FliVideo pattern: b65 → b65-*
            if project_hint =~ /^[a-z]\d+$/
              matches = Dir.glob("#{brand_path}/#{project_hint}-*")
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
          # @param brand_path [String] Full path to brand directory
          # @param pattern [String] Pattern with wildcards (e.g., 'b6*')
          # @return [Array<String>] List of matching project names
          def resolve_pattern(brand_path, pattern)
            matches = Dir.glob("#{brand_path}/#{pattern}")
                         .select { |path| File.directory?(path) }
                         .select { |path| valid_project?(path) }
                         .map { |path| File.basename(path) }
                         .sort

            raise "❌ No projects found matching pattern '#{pattern}' in #{brand_path}" if matches.empty?

            matches
          end

          # List all projects for a brand
          # @param brand [String] Brand shortcut or full name
          # @param pattern [String, nil] Optional filter pattern
          # @return [Array<String>] List of project names
          def list_projects(brand, pattern = nil)
            brand_path = Config.brand_path(brand)

            glob_pattern = pattern || '*'
            Dir.glob("#{brand_path}/#{glob_pattern}")
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

            # Exclude hidden and underscore-prefixed
            return false if basename.start_with?('.', '_')

            true
          end

          # Detect brand and project from current directory
          # @return [Array<String, String>] [brand, project] or [nil, nil]
          def detect_from_pwd
            current = Dir.pwd

            # Check if we're inside a v-* directory
            if current =~ %r{/(v-[^/]+)/([^/]+)/?}
              brand = ::Regexp.last_match(1)
              project = ::Regexp.last_match(2)
              return [brand, project] if project_exists?(brand, project)
            end

            [nil, nil]
          end

          # Check if project exists in brand directory
          # @param brand [String] Brand name (v-appydave format)
          # @param project [String] Project name
          # @return [Boolean] true if project directory exists
          def project_exists?(brand, project)
            projects_root = Config.projects_root
            project_path = File.join(projects_root, brand, project)
            Dir.exist?(project_path)
          end
        end
      end
    end
  end
end
