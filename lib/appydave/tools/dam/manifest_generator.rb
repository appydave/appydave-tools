# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Dam
      # Generate manifest JSON for video projects
      class ManifestGenerator
        attr_reader :brand, :brand_info, :brand_path

        def initialize(brand, brand_info: nil, brand_path: nil)
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key # Use resolved brand key, not original input
          @brand_path = brand_path || Config.brand_path(@brand)
        end

        # Generate manifest for this brand
        # @return [Hash] Result with :success, :path, and :brand keys
        def generate(output_file: nil, verbose: false)
          output_file ||= File.join(brand_path, 'projects.json')
          ssd_backup = brand_info.locations.ssd_backup

          unless ssd_backup && !ssd_backup.empty?
            puts "⚠️  SSD backup location not configured for brand '#{brand}'"
            puts '   Manifest will only include local projects.'
          end

          ssd_available = ssd_backup && Dir.exist?(ssd_backup)

          puts "📊 Generating manifest for #{brand}..."
          puts ''

          # Collect all unique project IDs from both locations
          all_project_ids = collect_project_ids(ssd_backup, ssd_available)

          # Build project entries (empty array if no projects)
          projects = all_project_ids.empty? ? [] : build_project_entries(all_project_ids, ssd_backup, ssd_available)

          # Calculate disk usage
          disk_usage = calculate_disk_usage(projects, ssd_backup)

          # Build manifest
          manifest = {
            config: {
              brand: brand,
              local_base: brand_path,
              ssd_base: ssd_backup,
              last_updated: Time.now.utc.iso8601,
              note: 'Auto-generated manifest. Regenerate with: vat manifest'
            }.merge(disk_usage),
            projects: projects
          }

          # Write to file
          File.write(output_file, JSON.pretty_generate(manifest))

          timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
          puts "✅ Generated #{output_file} (#{timestamp})"
          puts "   Found #{projects.size} unique projects"
          puts ''

          # Summary stats
          show_summary(projects, disk_usage)

          # Validations
          run_validations(projects, verbose: verbose)

          # Next steps
          puts ''
          puts '💡 Next Steps:'
          puts "   dam list #{brand}              # View all projects"
          puts "   dam status #{brand}            # Check sync status"
          puts "   dam s3-up #{brand} <project>   # Upload project to S3"
          puts ''

          { success: true, brand: brand, path: output_file }
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        # Build project directory path respecting brand's projects_subfolder setting
        def project_directory_path(project_id)
          if brand_info.settings.projects_subfolder && !brand_info.settings.projects_subfolder.empty?
            File.join(brand_path, brand_info.settings.projects_subfolder, project_id)
          else
            File.join(brand_path, project_id)
          end
        end

        def collect_project_ids(ssd_backup, ssd_available)
          all_project_ids = []

          # Scan SSD (if available)
          if ssd_available
            Dir.glob(File.join(ssd_backup, '*/')).each do |ssd_path|
              basename = File.basename(ssd_path)

              if range_folder?(basename)
                # Scan projects within SSD range folders
                Dir.glob(File.join(ssd_path, '*/')).each do |project_path|
                  project_id = File.basename(project_path)
                  all_project_ids << project_id if valid_project_folder?(project_path)
                end
              elsif valid_project_folder?(ssd_path)
                # Direct project in SSD root (legacy structure)
                all_project_ids << basename
              end
            end
          end

          # Scan local flat structure (active projects only)
          # If projects_subfolder is configured, scan only that subfolder
          # Otherwise, scan brand root (for flat structure like AppyDave)
          if brand_info.settings.projects_subfolder && !brand_info.settings.projects_subfolder.empty?
            projects_folder = File.join(brand_path, brand_info.settings.projects_subfolder)
            scan_paths = Dir.exist?(projects_folder) ? [projects_folder] : []
          else
            scan_paths = [brand_path]
          end

          scan_paths.each do |scan_path|
            Dir.glob(File.join(scan_path, '*/')).each do |path|
              basename = File.basename(path)
              # Skip hidden and special directories
              next if basename.start_with?('.', '_')
              next if %w[s3-staging archived final].include?(basename)

              all_project_ids << basename if valid_project_folder?(path)
            end
          end

          # Scan archived structure (restored/archived projects)
          archived_base = File.join(brand_path, 'archived')
          if Dir.exist?(archived_base)
            # Scan range folders (e.g., archived/a50-a99/, archived/b50-b99/)
            Dir.glob(File.join(archived_base, '*/')).each do |range_folder|
              # Scan projects within each range folder
              Dir.glob(File.join(range_folder, '*/')).each do |project_path|
                basename = File.basename(project_path)
                all_project_ids << basename if valid_project_folder?(project_path)
              end
            end
          end

          all_project_ids.uniq.sort
        end

        def build_project_entries(all_project_ids, ssd_backup, ssd_available)
          all_project_ids.map { |project_id| build_project_entry(project_id, ssd_backup, ssd_available) }
        end

        def build_project_entry(project_id, ssd_backup, ssd_available)
          # Check flat structure (active projects)
          flat_path = project_directory_path(project_id)
          flat_exists = Dir.exist?(flat_path)

          # Check archived structure (restored/archived projects)
          range = determine_range(project_id)
          archived_path = File.join(brand_path, 'archived', range, project_id)
          archived_exists = Dir.exist?(archived_path)

          # Determine which path to use for file detection
          local_path = if flat_exists
                         flat_path
                       else
                         (archived_exists ? archived_path : flat_path)
                       end
          local_exists = flat_exists || archived_exists

          # Determine structure type
          structure = if flat_exists
                        'flat'
                      elsif archived_exists
                        'archived'
                      end

          # Check S3 staging (only if local exists)
          s3_staging_path = File.join(local_path, 's3-staging')
          s3_exists = local_exists && Dir.exist?(s3_staging_path)

          # Determine project type
          type = determine_project_type(local_path, project_id, local_exists)

          # Check SSD (try flat, calculated range, and search all range folders)
          ssd_exists = if ssd_available
                         flat_ssd_path = File.join(ssd_backup, project_id)
                         range_ssd_path = File.join(ssd_backup, range, project_id)

                         Dir.exist?(flat_ssd_path) || Dir.exist?(range_ssd_path) || find_project_in_ssd_ranges?(ssd_backup, project_id)
                       else
                         false
                       end

          {
            id: project_id,
            type: type,
            storage: {
              ssd: {
                exists: ssd_exists,
                path: ssd_exists ? project_id : nil
              },
              s3: {
                exists: s3_exists
              },
              local: {
                exists: local_exists,
                structure: structure,
                has_heavy_files: local_exists ? heavy_files?(local_path) : false,
                has_light_files: local_exists ? light_files?(local_path) : false
              }
            }
          }
        end

        def calculate_disk_usage(projects, ssd_backup)
          local_bytes = 0
          ssd_bytes = 0

          projects.each do |project|
            if project[:storage][:local][:exists]
              # Try flat structure first, then archived structure
              flat_path = project_directory_path(project[:id])
              if Dir.exist?(flat_path)
                local_bytes += calculate_directory_size(flat_path)
              else
                range = determine_range(project[:id])
                archived_path = File.join(brand_path, 'archived', range, project[:id])
                local_bytes += calculate_directory_size(archived_path) if Dir.exist?(archived_path)
              end
            end

            next unless project[:storage][:ssd][:exists]

            # Find actual SSD path (flat, calculated range, or search)
            ssd_path = find_ssd_project_path(ssd_backup, project[:id])
            ssd_bytes += calculate_directory_size(ssd_path) if ssd_path
          end

          {
            disk_usage: {
              local: format_bytes_hash(local_bytes),
              ssd: format_bytes_hash(ssd_bytes)
            }
          }
        end

        def show_summary(projects, disk_usage)
          local_only = projects.count { |p| p[:storage][:local][:exists] && !p[:storage][:ssd][:exists] }
          ssd_only = projects.count { |p| !p[:storage][:local][:exists] && p[:storage][:ssd][:exists] }
          both = projects.count { |p| p[:storage][:local][:exists] && p[:storage][:ssd][:exists] }

          puts 'Distribution:'
          puts "  Local only: #{local_only}"
          puts "  SSD only: #{ssd_only}"
          puts "  Both locations: #{both}"
          puts ''
          puts 'Disk Usage:'
          puts "  Local: #{format_bytes_human(disk_usage[:disk_usage][:local][:total_bytes])}"
          puts "  SSD: #{format_bytes_human(disk_usage[:disk_usage][:ssd][:total_bytes])}"
          puts ''
        end

        def run_validations(projects, verbose: false)
          puts '🔍 Running validations...'
          warnings = []

          # Check for projects with no storage locations
          projects.each do |project|
            no_storage = !project[:storage][:local][:exists] && !project[:storage][:ssd][:exists]
            warnings << "⚠️  Project has no storage: #{project[:id]}" if no_storage
          end

          if warnings.empty?
            puts '✅ All validations passed!'
          elsif verbose
            puts "#{warnings.size} warning(s) found:"
            warnings.each { |w| puts "   #{w}" }
          else
            puts "⚠️  #{warnings.size} validation warning#{'s' if warnings.size != 1} found"
            puts "   Run 'dam manifest #{brand} --verbose' to see details"
          end
        end

        # Helper methods

        # Search for project in SSD range folders
        # @param ssd_backup [String] SSD backup base path
        # @param project_id [String] Project ID to find
        # @return [Boolean] true if project found in any range folder
        def find_project_in_ssd_ranges?(ssd_backup, project_id)
          !find_ssd_project_path(ssd_backup, project_id).nil?
        end

        # Find actual SSD path for project
        # @param ssd_backup [String] SSD backup base path
        # @param project_id [String] Project ID to find
        # @return [String, nil] Full path to project or nil if not found
        def find_ssd_project_path(ssd_backup, project_id)
          return nil unless Dir.exist?(ssd_backup)

          # Try flat structure first
          flat_path = File.join(ssd_backup, project_id)
          return flat_path if Dir.exist?(flat_path)

          # Try calculated range
          range = determine_range(project_id)
          range_path = File.join(ssd_backup, range, project_id)
          return range_path if Dir.exist?(range_path)

          # Search all range folders
          Dir.glob(File.join(ssd_backup, '*/')).each do |range_folder_path|
            range_name = File.basename(range_folder_path)
            next unless range_folder?(range_name)

            project_path = File.join(range_folder_path, project_id)
            return project_path if Dir.exist?(project_path)
          end

          nil
        end

        # Determine range folder for project
        # Both SSD and local archived use 50-number ranges with letter prefixes:
        # b00-b49, b50-b99, a01-a49, a50-a99
        def determine_range(project_id)
          # FliVideo/Modern pattern: b40, a82, etc.
          if project_id =~ /^([a-z])(\d+)/
            letter = Regexp.last_match(1)
            number = Regexp.last_match(2).to_i
            # 50-number ranges (0-49, 50-99)
            range_start = (number / 50) * 50
            range_end = range_start + 49
            # Format with leading zeros and letter prefix
            format("#{letter}%02d-#{letter}%02d", range_start, range_end)
          else
            # Legacy pattern or unknown
            '000-099'
          end
        end

        # Check if folder is a valid project (permissive - any folder except infrastructure)
        def valid_project_folder?(project_path)
          basename = File.basename(project_path)

          # Exclude infrastructure directories
          excluded = %w[archived docs node_modules .git .github s3-staging final]
          return false if excluded.include?(basename)

          # Exclude hidden and underscore-prefixed
          return false if basename.start_with?('.', '_')

          true
        end

        # Determine project type based on content and naming
        def determine_project_type(local_path, project_id, local_exists)
          # 1. Check for storyline.json (highest priority)
          if local_exists
            storyline_json_path = File.join(local_path, 'data', 'storyline.json')
            return 'storyline' if File.exist?(storyline_json_path)
          end

          # 2. Check for FliVideo pattern (letter + 2 digits + dash + name)
          return 'flivideo' if project_id =~ /^[a-z]\d{2}-/

          # 3. Check for legacy pattern (starts with digit)
          return 'flivideo' if project_id =~ /^\d/

          # 4. Everything else is general
          'general'
        end

        def range_folder?(folder_name)
          # Range folder patterns:
          # - 000-099 (3 digits + dash + 3 digits)
          return true if folder_name =~ /^\d{3}-\d{3}$/

          # - a1-20, a21-40, b50-99 (letter + digits + dash + digits)
          return true if folder_name =~ /^[a-z]\d+-\d+$/

          # - b00-b49 (letter + 2 digits + dash + same letter + 2 digits)
          if folder_name =~ /^([a-z])(\d{2})-([a-z])(\d{2})$/
            letter1 = Regexp.last_match(1)
            letter2 = Regexp.last_match(3)
            # Must be same letter on both sides
            return letter1 == letter2
          end

          false
        end

        def heavy_files?(dir)
          return false unless Dir.exist?(dir)

          Dir.glob(File.join(dir, '*.{mp4,mov,avi,mkv,webm}')).any?
        end

        def light_files?(dir)
          return false unless Dir.exist?(dir)

          Dir.glob(File.join(dir, '**/*.{srt,vtt,jpg,png,md,txt,json,yml}')).any?
        end

        def calculate_directory_size(dir_path)
          total = 0
          Dir.glob(File.join(dir_path, '**', '*'), File::FNM_DOTMATCH).each do |file|
            total += File.size(file) if File.file?(file)
          end
          total
        end

        def format_bytes_hash(bytes)
          {
            total_bytes: bytes,
            total_mb: (bytes / 1024.0 / 1024.0).round(2),
            total_gb: (bytes / 1024.0 / 1024.0 / 1024.0).round(2)
          }
        end

        def format_bytes_human(bytes)
          if bytes < 1024
            "#{bytes} B"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          elsif bytes < 1024 * 1024 * 1024
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          else
            "#{(bytes / (1024.0 * 1024 * 1024)).round(2)} GB"
          end
        end
      end
    end
  end
end
