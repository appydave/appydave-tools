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
        def self.list_brands_with_counts(detailed: false, s3: false)
          brands = Config.available_brands

          if brands.empty?
            puts "⚠️  No brands found in #{Config.projects_root}"
            return
          end

          # Gather brand data (skip S3 if not requested)
          brand_data = brands.map { |brand| collect_brand_data(brand, detailed: detailed, s3: s3) }

          if detailed
            # Detailed view with additional columns
            if s3
              header = 'BRAND                              KEY          PROJECTS         SIZE        LAST MODIFIED    ' \
                       'GIT              S3 SYNC      PATH                                      SSD BACKUP                       ' \
                       'WORKFLOW     ACTIVE'
              puts header
              puts '-' * 200
            else
              header = 'BRAND                              KEY          PROJECTS         SIZE        LAST MODIFIED    ' \
                       'GIT              PATH                                      SSD BACKUP                       ' \
                       'WORKFLOW     ACTIVE'
              puts header
              puts '-' * 189
            end

            brand_data.each do |data|
              brand_display = "#{data[:shortcut]} - #{data[:name]}"

              if s3
                puts format(
                  '%-30s %-12s %10d %12s %20s    %-15s  %-10s  %-35s  %-30s  %-10s  %6d',
                  brand_display,
                  data[:key],
                  data[:count],
                  format_size(data[:size]),
                  format_date(data[:modified]),
                  data[:git_status],
                  data[:s3_sync],
                  shorten_path(data[:path]),
                  data[:ssd_backup] || 'N/A',
                  data[:workflow] || 'N/A',
                  data[:active_count] || 0
                )
              else
                puts format(
                  '%-30s %-12s %10d %12s %20s    %-15s  %-35s  %-30s  %-10s  %6d',
                  brand_display,
                  data[:key],
                  data[:count],
                  format_size(data[:size]),
                  format_date(data[:modified]),
                  data[:git_status],
                  shorten_path(data[:path]),
                  data[:ssd_backup] || 'N/A',
                  data[:workflow] || 'N/A',
                  data[:active_count] || 0
                )
              end
            end
          else
            # Default view - use same format for header and data
            # rubocop:disable Style/RedundantFormat
            if s3
              puts format(
                '%-30s %-15s %10s %12s %20s    %-15s  %-10s',
                'BRAND',
                'KEY',
                'PROJECTS',
                'SIZE',
                'LAST MODIFIED',
                'GIT',
                'S3 SYNC'
              )
              puts '-' * 133
            else
              puts format(
                '%-30s %-15s %10s %12s %20s    %-15s',
                'BRAND',
                'KEY',
                'PROJECTS',
                'SIZE',
                'LAST MODIFIED',
                'GIT'
              )
              puts '-' * 122
            end
            # rubocop:enable Style/RedundantFormat

            brand_data.each do |data|
              brand_display = "#{data[:shortcut]} - #{data[:name]}"

              if s3
                puts format(
                  '%-30s %-15s %10d %12s %20s    %-15s  %-10s',
                  brand_display,
                  data[:key],
                  data[:count],
                  format_size(data[:size]),
                  format_date(data[:modified]),
                  data[:git_status],
                  data[:s3_sync]
                )
              else
                puts format(
                  '%-30s %-15s %10d %12s %20s    %-15s',
                  brand_display,
                  data[:key],
                  data[:count],
                  format_size(data[:size]),
                  format_date(data[:modified]),
                  data[:git_status]
                )
              end
            end
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
        def self.list_brand_projects(brand_arg, detailed: false, s3: false)
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

          # Gather project data (skip S3 if not requested)
          brand_path = Config.brand_path(brand_arg)
          brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_arg)
          is_git_repo = Dir.exist?(File.join(brand_path, '.git'))

          project_data = projects.map do |project|
            collect_project_data(brand_arg, brand_path, brand_info, project, is_git_repo, detailed: detailed, s3: s3)
          end

          # Print common header
          puts "Projects in #{brand}:"
          puts ''
          puts 'ℹ️  Note: Lists only projects with files, not empty directories'
          puts ''

          if detailed
            # Detailed view with additional columns - use same format for header and data
            # rubocop:disable Style/RedundantFormat
            if s3
              puts format(
                '%-45s %12s %15s  %-15s  %-12s  %-65s  %-18s  %-18s  %-30s  %-15s  %-15s',
                'PROJECT',
                'SIZE',
                'AGE',
                'GIT',
                'S3',
                'PATH',
                'HEAVY FILES',
                'LIGHT FILES',
                'SSD BACKUP',
                'S3 ↑ UPLOAD',
                'S3 ↓ DOWNLOAD'
              )
              puts '-' * 280
            else
              puts format(
                '%-45s %12s %15s  %-15s  %-65s  %-18s  %-18s  %-30s',
                'PROJECT',
                'SIZE',
                'AGE',
                'GIT',
                'PATH',
                'HEAVY FILES',
                'LIGHT FILES',
                'SSD BACKUP'
              )
              puts '-' * 239
            end
            # rubocop:enable Style/RedundantFormat

            project_data.each do |data|
              age_display = data[:stale] ? "#{data[:age]} ⚠️" : data[:age]

              if s3
                s3_upload = data[:s3_last_upload] ? FileHelper.format_age(data[:s3_last_upload]) : 'N/A'
                s3_download = data[:s3_last_download] ? FileHelper.format_age(data[:s3_last_download]) : 'N/A'

                puts format(
                  '%-45s %12s %15s  %-15s  %-12s  %-65s  %-18s  %-18s  %-30s  %-15s  %-15s',
                  data[:name],
                  format_size(data[:size]),
                  age_display,
                  data[:git_status],
                  data[:s3_sync],
                  shorten_path(data[:path]),
                  data[:heavy_files] || 'N/A',
                  data[:light_files] || 'N/A',
                  data[:ssd_backup] || 'N/A',
                  s3_upload,
                  s3_download
                )
              else
                puts format(
                  '%-45s %12s %15s  %-15s  %-65s  %-18s  %-18s  %-30s',
                  data[:name],
                  format_size(data[:size]),
                  age_display,
                  data[:git_status],
                  shorten_path(data[:path]),
                  data[:heavy_files] || 'N/A',
                  data[:light_files] || 'N/A',
                  data[:ssd_backup] || 'N/A'
                )
              end
            end
          else
            # Default view - use same format for header and data
            # rubocop:disable Style/RedundantFormat
            if s3
              puts format(
                '%-45s %12s %15s  %-15s  %-12s',
                'PROJECT',
                'SIZE',
                'AGE',
                'GIT',
                'S3'
              )
              puts '-' * 130
            else
              puts format(
                '%-45s %12s %15s  %-15s',
                'PROJECT',
                'SIZE',
                'AGE',
                'GIT'
              )
              puts '-' * 117
            end
            # rubocop:enable Style/RedundantFormat

            project_data.each do |data|
              age_display = data[:stale] ? "#{data[:age]} ⚠️" : data[:age]

              if s3
                puts format(
                  '%-45s %12s %15s  %-15s  %-12s',
                  data[:name],
                  format_size(data[:size]),
                  age_display,
                  data[:git_status],
                  data[:s3_sync]
                )
              else
                puts format(
                  '%-45s %12s %15s  %-15s',
                  data[:name],
                  format_size(data[:size]),
                  age_display,
                  data[:git_status]
                )
              end
            end
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
              age: FileHelper.format_age(modified),
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

        # Collect brand data for display
        def self.collect_brand_data(brand, detailed: false, s3: false)
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

          # Get git status
          git_status = calculate_git_status(brand_path)

          # Get S3 sync status (count of projects with s3-staging) - only if requested
          s3_sync_status = s3 ? calculate_s3_sync_status(brand, projects) : 'N/A'

          result = {
            shortcut: shortcut || key,
            key: key,
            name: name || key.capitalize,
            path: brand_path,
            count: projects.size,
            size: total_size,
            modified: last_modified,
            git_status: git_status,
            s3_sync: s3_sync_status
          }

          # Add detailed fields if requested
          if detailed
            # SSD backup path
            ssd_backup = brand_info.locations.ssd_backup
            ssd_backup = nil if ssd_backup.nil? || ssd_backup.empty? || ssd_backup == 'NOT-SET'

            # Workflow type (inferred from projects_subfolder setting)
            workflow = brand_info.settings.projects_subfolder == 'projects' ? 'storyline' : 'flivideo'

            # Active project count (projects with flat structure, not archived)
            active_count = projects.count do |project|
              project_path = Config.project_path(brand, project)
              # Check if not in archived/ subfolder
              !project_path.include?('/archived/')
            end

            result.merge!(
              ssd_backup: ssd_backup ? shorten_path(ssd_backup) : nil,
              workflow: workflow,
              active_count: active_count
            )
          end

          result
        end

        # Calculate git status for a brand
        def self.calculate_git_status(brand_path)
          if Dir.exist?(File.join(brand_path, '.git'))
            modified = GitHelper.modified_files_count(brand_path)
            untracked = GitHelper.untracked_files_count(brand_path)
            if modified.positive? || untracked.positive?
              '⚠️ changes'
            else
              '✓ clean'
            end
          else
            'N/A'
          end
        end

        # Calculate S3 sync status for a brand
        def self.calculate_s3_sync_status(brand, projects)
          return 'N/A' if projects.empty?

          s3_count = projects.count do |project|
            project_path = Config.project_path(brand, project)
            Dir.exist?(File.join(project_path, 's3-staging'))
          end

          if s3_count.zero?
            'none'
          else
            "#{s3_count}/#{projects.size}"
          end
        end

        # Calculate git status for a specific project
        def self.calculate_project_git_status(brand_path, project)
          # Use git status --short to check for changes in project folder
          result = `cd "#{brand_path}" && git status --short "#{project}" 2>/dev/null`
          if result.empty?
            '✓ clean'
          else
            '⚠️ changes'
          end
        end

        # Calculate 3-state S3 sync status for a project
        def self.calculate_project_s3_sync_status(brand_arg, brand_info, project)
          # Check if S3 is configured
          s3_bucket = brand_info.aws.s3_bucket
          return 'N/A' if s3_bucket.nil? || s3_bucket.empty? || s3_bucket == 'NOT-SET'

          # Use S3Operations to calculate sync status
          begin
            s3_ops = S3Operations.new(brand_arg, project, brand_info: brand_info)
            s3_ops.calculate_sync_status
          rescue StandardError
            # S3 not accessible or other error
            'N/A'
          end
        end

        # Calculate S3 sync timestamps for a project
        def self.calculate_s3_timestamps(brand_arg, brand_info, project)
          # Check if S3 is configured
          s3_bucket = brand_info.aws.s3_bucket
          return { last_upload: nil, last_download: nil } if s3_bucket.nil? || s3_bucket.empty? || s3_bucket == 'NOT-SET'

          # Use S3Operations to get timestamps
          begin
            s3_ops = S3Operations.new(brand_arg, project, brand_info: brand_info)
            s3_ops.sync_timestamps
          rescue StandardError
            # S3 not accessible or other error
            { last_upload: nil, last_download: nil }
          end
        end

        # Collect project data for display
        # rubocop:disable Metrics/ParameterLists
        def self.collect_project_data(brand_arg, brand_path, brand_info, project, is_git_repo, detailed: false, s3: false)
          project_path = Config.project_path(brand_arg, project)
          size = FileHelper.calculate_directory_size(project_path)
          modified = File.mtime(project_path)

          # Check if project has uncommitted changes (if brand is git repo)
          git_status = if is_git_repo
                         calculate_project_git_status(brand_path, project)
                       else
                         'N/A'
                       end

          # Calculate 3-state S3 sync status - only if requested (performance optimization)
          s3_sync = s3 ? calculate_project_s3_sync_status(brand_arg, brand_info, project) : 'N/A'

          result = {
            name: project,
            path: project_path,
            size: size,
            modified: modified,
            age: FileHelper.format_age(modified),
            stale: stale?(modified),
            git_status: git_status,
            s3_sync: s3_sync
          }

          # Add detailed fields if requested
          if detailed
            # Heavy files (video files in root)
            heavy_count = 0
            heavy_size = 0
            Dir.glob(File.join(project_path, '*.{mp4,mov,avi,mkv,webm}')).each do |file|
              heavy_count += 1
              heavy_size += File.size(file)
            end

            # Light files (subtitles, images, metadata)
            light_count = 0
            light_size = 0
            Dir.glob(File.join(project_path, '**/*.{srt,vtt,jpg,png,md,txt,json,yml}')).each do |file|
              light_count += 1
              light_size += File.size(file)
            end

            # SSD backup path (if exists)
            ssd_backup = brand_info.locations.ssd_backup
            ssd_path = if ssd_backup && !ssd_backup.empty? && ssd_backup != 'NOT-SET'
                         ssd_project_path = File.join(ssd_backup, project)
                         File.exist?(ssd_project_path) ? shorten_path(ssd_project_path) : nil
                       end

            # S3 timestamps (last upload/download) - only if requested (performance optimization)
            if s3
              s3_timestamps = calculate_s3_timestamps(brand_arg, brand_info, project)
              result.merge!(
                heavy_files: "#{heavy_count} (#{format_size(heavy_size)})",
                light_files: "#{light_count} (#{format_size(light_size)})",
                ssd_backup: ssd_path,
                s3_last_upload: s3_timestamps[:last_upload],
                s3_last_download: s3_timestamps[:last_download]
              )
            else
              result.merge!(
                heavy_files: "#{heavy_count} (#{format_size(heavy_size)})",
                light_files: "#{light_count} (#{format_size(light_size)})",
                ssd_backup: ssd_path
              )
            end
          end

          result
        end
        # rubocop:enable Metrics/ParameterLists

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
