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
            Appydave::Tools::Configuration::Config.configure
            brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand)
            brand_path = Config.brand_path(brand)
            projects = ProjectResolver.list_projects(brand)
            total_size = calculate_total_size(brand, projects)
            last_modified = find_last_modified(brand, projects)

            # Get shortcut, key, and name with fallbacks
            shortcut = brand_info.shortcut&.strip
            shortcut = nil if shortcut&.empty?
            key = brand_info.key
            name = brand_info.name&.strip
            name = nil if name&.empty?

            {
              shortcut: shortcut || key,
              key: key,
              name: name || key.capitalize,
              path: brand_path,
              count: projects.size,
              size: total_size,
              modified: last_modified
            }
          end

          # Print table header
          puts 'BRAND                                      PROJECTS         SIZE        LAST MODIFIED    PATH'
          puts '-' * 120

          # Print table rows
          brand_data.each do |data|
            # Format: "shortcut (key) - Name"
            # If shortcut == key, just show "key - Name" to avoid redundancy
            brand_display = if data[:shortcut] == data[:key]
                              "#{data[:key]} - #{data[:name]}"
                            else
                              "#{data[:shortcut]} (#{data[:key]}) - #{data[:name]}"
                            end

            puts format(
              '%-40s %10d %12s %20s    %s',
              brand_display,
              data[:count],
              format_size(data[:size]),
              format_date(data[:modified]),
              shorten_path(data[:path])
            )
          end

          # Print footer summary
          total_projects = brand_data.sum { |d| d[:count] }
          total_size = brand_data.sum { |d| d[:size] }

          puts ''
          puts "Total: #{brand_data.size} brand#{'s' if brand_data.size != 1}, " \
               "#{total_projects} project#{'s' if total_projects != 1}, " \
               "#{format_size(total_size)}"
        end

        # List all projects for a specific brand (Mode 3)
        def self.list_brand_projects(brand_arg)
          # ProjectResolver expects the original brand key/shortcut, not the expanded v-* version
          projects = ProjectResolver.list_projects(brand_arg)

          # Only expand brand for display purposes
          brand = Config.expand_brand(brand_arg)

          # Show brand context header
          show_brand_header(brand_arg, brand)

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
              modified: modified,
              age: format_age(modified),
              stale: stale?(modified)
            }
          end

          # Print table header
          puts "Projects in #{brand}:"
          puts ''
          puts 'ℹ️  Note: Lists only projects with files, not empty directories'
          puts ''
          puts 'PROJECT                                               SIZE             AGE'
          puts '-' * 100

          # Print table rows
          project_data.each do |data|
            age_display = data[:stale] ? "#{data[:age]} ⚠️" : data[:age]
            puts format(
              '%-45s %12s %15s',
              data[:name],
              format_size(data[:size]),
              age_display
            )
          end

          # Print footer summary
          total_size = project_data.sum { |d| d[:size] }
          project_count = project_data.size

          puts ''
          puts "Total: #{project_count} project#{'s' if project_count != 1}, #{format_size(total_size)}"
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
              modified: modified,
              age: format_age(modified),
              stale: stale?(modified)
            }
          end

          # Print table header
          match_count = matches.size
          puts "#{match_count} project#{'s' if match_count != 1} matching '#{pattern}' in #{brand}:"
          puts 'PROJECT                                               SIZE             AGE'
          puts '-' * 100

          # Print table rows
          project_data.each do |data|
            age_display = data[:stale] ? "#{data[:age]} ⚠️" : data[:age]
            puts format(
              '%-45s %12s %15s',
              data[:name],
              format_size(data[:size]),
              age_display
            )
          end

          # Print footer summary
          total_size = project_data.sum { |d| d[:size] }
          all_projects = ProjectResolver.list_projects(brand_arg)
          brand_total_size = calculate_total_size(brand_arg, all_projects)
          percentage = brand_total_size.positive? ? (total_size.to_f / brand_total_size * 100).round(1) : 0

          puts ''
          puts "Total: #{match_count} project#{'s' if match_count != 1}, #{format_size(total_size)} " \
               "(#{percentage}% of #{brand})"
        end

        # Helper methods

        # Show brand context header with git, S3, and SSD info
        def self.show_brand_header(brand_arg, brand)
          Appydave::Tools::Configuration::Config.configure
          brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_arg)
          brand_path = Config.brand_path(brand_arg)

          puts "📂 Brand: #{brand}"
          puts ''

          # Git status
          if Dir.exist?(File.join(brand_path, '.git'))
            branch = GitHelper.current_branch(brand_path)
            puts "   Git: #{branch} branch"
          else
            puts '   Git: Not a git repository'
          end

          # S3 configuration
          s3_bucket = brand_info.aws.s3_bucket
          if s3_bucket && !s3_bucket.empty? && s3_bucket != 'NOT-SET'
            puts "   S3: Configured (#{s3_bucket})"
          else
            puts '   S3: Not configured'
          end

          # SSD backup path
          ssd_backup = brand_info.locations.ssd_backup
          if ssd_backup && !ssd_backup.empty? && ssd_backup != 'NOT-SET'
            puts "   SSD: #{shorten_path(ssd_backup)}"
          else
            puts '   SSD: Not configured'
          end

          puts ''
        end

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

        # Format age as relative time (e.g., "3 days", "2 weeks")
        def self.format_age(time)
          return 'N/A' if time.nil?

          seconds = Time.now - time
          return 'just now' if seconds < 60

          minutes = seconds / 60
          return "#{minutes.round}m" if minutes < 60

          hours = minutes / 60
          return "#{hours.round}h" if hours < 24

          days = hours / 24
          return "#{days.round}d" if days < 7

          weeks = days / 7
          return "#{weeks.round}w" if weeks < 4

          months = days / 30
          return "#{months.round}mo" if months < 12

          years = days / 365
          "#{years.round}y"
        end

        # Check if project is stale (>90 days old)
        def self.stale?(time)
          return false if time.nil?

          days = (Time.now - time) / 86_400 # seconds in a day
          days > 90
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
