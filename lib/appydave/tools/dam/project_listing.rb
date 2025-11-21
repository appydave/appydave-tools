# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken
# Disabled: Using simple unannotated tokens (%s) for straightforward string formatting
# Annotated tokens (%<foo>s) add unnecessary complexity for simple table formatting

module Appydave
  module Tools
    module Dam
      # Project listing functionality for VAT
      class ProjectListing
        # List all brands with summary table
        def self.list_brands_with_counts
          brands = Config.available_brands

          if brands.empty?
            puts "⚠️  No brands found in #{Config.projects_root}"
            return
          end

          # Gather brand data
          brand_data = brands.map do |brand|
            brand_path = Config.brand_path(brand)
            projects = ProjectResolver.list_projects(brand)
            total_size = calculate_total_size(brand, projects)
            last_modified = find_last_modified(brand, projects)

            {
              name: brand,
              path: brand_path,
              count: projects.size,
              size: total_size,
              modified: last_modified
            }
          end

          # Print table header
          puts 'BRAND                  PROJECTS         SIZE        LAST MODIFIED    PATH'
          puts '-' * 120

          # Print table rows
          brand_data.each do |data|
            puts format(
              '%-20s %10d %12s %20s    %s',
              data[:name],
              data[:count],
              format_size(data[:size]),
              format_date(data[:modified]),
              shorten_path(data[:path])
            )
          end
        end

        # List all projects for a specific brand (Mode 3)
        def self.list_brand_projects(brand_arg)
          # ProjectResolver expects the original brand key/shortcut, not the expanded v-* version
          projects = ProjectResolver.list_projects(brand_arg)

          # Only expand brand for display purposes
          brand = Config.expand_brand(brand_arg)

          if projects.empty?
            puts "⚠️  No projects found for brand: #{brand}"
            puts ''
            puts '   This could mean:'
            puts '   - The brand exists but has no project directories'
            puts '   - The manifest needs updating'
            puts ''
            puts "   Try: dam manifest #{brand_arg}"
            return
          end

          # Gather project data
          project_data = projects.map do |project|
            project_path = Config.project_path(brand_arg, project)
            size = FileHelper.calculate_directory_size(project_path)
            modified = File.mtime(project_path)

            {
              name: project,
              path: project_path,
              size: size,
              modified: modified
            }
          end

          # Print table header
          puts "Projects in #{brand}:"
          puts 'PROJECT                                               SIZE        LAST MODIFIED    PATH'
          puts '-' * 120

          # Print table rows
          project_data.each do |data|
            puts format(
              '%-45s %12s %20s    %s',
              data[:name],
              format_size(data[:size]),
              format_date(data[:modified]),
              shorten_path(data[:path])
            )
          end
        end

        # List with pattern matching (Mode 3b)
        def self.list_with_pattern(brand_arg, pattern)
          # ProjectResolver expects the original brand key/shortcut, not the expanded v-* version
          matches = ProjectResolver.resolve_pattern(brand_arg, pattern)

          # Only expand brand for display purposes
          brand = Config.expand_brand(brand_arg)

          if matches.empty?
            puts "⚠️  No projects found matching pattern: #{pattern}"
            puts ''
            puts '   Pattern tips:'
            puts '   - Use * for wildcards: b6* matches b60-b69'
            puts '   - Use ? for single character: b6? matches b60-b69'
            puts '   - Patterns are case-insensitive'
            puts ''
            puts "   Try: dam list #{brand_arg}  # See all projects"
            return
          end

          # Gather project data
          project_data = matches.map do |project|
            project_path = Config.project_path(brand_arg, project)
            size = FileHelper.calculate_directory_size(project_path)
            modified = File.mtime(project_path)

            {
              name: project,
              path: project_path,
              size: size,
              modified: modified
            }
          end

          # Print table header
          match_count = matches.size
          puts "#{match_count} project#{'s' if match_count != 1} matching '#{pattern}' in #{brand}:"
          puts 'PROJECT                                               SIZE        LAST MODIFIED    PATH'
          puts '-' * 120

          # Print table rows
          project_data.each do |data|
            puts format(
              '%-45s %12s %20s    %s',
              data[:name],
              format_size(data[:size]),
              format_date(data[:modified]),
              shorten_path(data[:path])
            )
          end
        end

        # Helper methods

        # Calculate total size of all projects in a brand
        def self.calculate_total_size(brand, projects)
          projects.sum do |project|
            FileHelper.calculate_directory_size(Config.project_path(brand, project))
          end
        end

        # Find the most recent modification time across all projects
        def self.find_last_modified(brand, projects)
          return nil if projects.empty?

          projects.map do |project|
            File.mtime(Config.project_path(brand, project))
          end.max
        end

        # Format size in human-readable format
        def self.format_size(bytes)
          FileHelper.format_size(bytes)
        end

        # Format date/time in readable format
        def self.format_date(time)
          return 'N/A' if time.nil?

          time.strftime('%Y-%m-%d %H:%M')
        end

        # Shorten path by replacing home directory with ~
        def self.shorten_path(path)
          path.sub(Dir.home, '~')
        end
      end
    end
  end
end
# rubocop:enable Style/FormatStringToken
