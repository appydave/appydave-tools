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
        def generate(output_file: nil)
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

          if all_project_ids.empty?
            puts "❌ No projects found for brand '#{brand}'"
            return { success: false, brand: brand, path: nil }
          end

          # Build project entries
          projects = build_project_entries(all_project_ids, ssd_backup, ssd_available)

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

          puts "✅ Generated #{output_file}"
          puts "   Found #{projects.size} unique projects"
          puts ''

          # Summary stats
          show_summary(projects, disk_usage)

          # Validations
          run_validations(projects)

          { success: true, brand: brand, path: output_file }
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
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
                  all_project_ids << project_id if valid_project_id?(project_id)
                end
              elsif valid_project_id?(basename)
                # Direct project in SSD root (legacy structure)
                all_project_ids << basename
              end
            end
          end

          # Scan local flat structure (active projects only)
          Dir.glob(File.join(brand_path, '*/')).each do |path|
            basename = File.basename(path)
            # Skip hidden and special directories
            next if basename.start_with?('.', '_')
            next if %w[s3-staging archived final].include?(basename)

            all_project_ids << basename if valid_project_id?(basename)
          end

          # Scan archived structure (restored/archived projects)
          archived_base = File.join(brand_path, 'archived')
          if Dir.exist?(archived_base)
            # Scan range folders (e.g., archived/a50-a99/, archived/b50-b99/)
            Dir.glob(File.join(archived_base, '*/')).each do |range_folder|
              # Scan projects within each range folder
              Dir.glob(File.join(range_folder, '*/')).each do |project_path|
                basename = File.basename(project_path)
                all_project_ids << basename if valid_project_id?(basename)
              end
            end
          end

          all_project_ids.uniq.sort
        end

        def build_project_entries(all_project_ids, ssd_backup, ssd_available)
          projects = []

          all_project_ids.each do |project_id|
            # Check flat structure (active projects)
            flat_path = File.join(brand_path, project_id)
            flat_exists = Dir.exist?(flat_path)

            # Check archived structure (restored/archived projects)
            range = determine_range(project_id)
            archived_path = File.join(brand_path, 'archived', range, project_id)
            archived_exists = Dir.exist?(archived_path)

            # Determine which path to use for file detection
            local_path = flat_exists ? flat_path : (archived_exists ? archived_path : flat_path)
            local_exists = flat_exists || archived_exists

            # Determine structure type
            structure = if flat_exists
                          'flat'
                        elsif archived_exists
                          'archived'
                        end

            # Check SSD (try both flat and range-based structures)
            ssd_exists = false
            ssd_path = nil
            if ssd_available
              # Try flat structure first (legacy)
              flat_ssd_path = File.join(ssd_backup, project_id)
              # Try range-based structure (current)
              range_ssd_path = File.join(ssd_backup, range, project_id)

              if Dir.exist?(flat_ssd_path)
                ssd_exists = true
                ssd_path = project_id
              elsif Dir.exist?(range_ssd_path)
                ssd_exists = true
                ssd_path = project_id
              end
            end

            projects << {
              id: project_id,
              storage: {
                ssd: {
                  exists: ssd_exists,
                  path: ssd_exists ? project_id : nil
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

          projects
        end

        def calculate_disk_usage(projects, ssd_backup)
          local_bytes = 0
          ssd_bytes = 0

          projects.each do |project|
            if project[:storage][:local][:exists]
              # Try flat structure first, then archived structure
              flat_path = File.join(brand_path, project[:id])
              if Dir.exist?(flat_path)
                local_bytes += calculate_directory_size(flat_path)
              else
                range = determine_range(project[:id])
                archived_path = File.join(brand_path, 'archived', range, project[:id])
                local_bytes += calculate_directory_size(archived_path) if Dir.exist?(archived_path)
              end
            end

            if project[:storage][:ssd][:exists]
              # Try flat structure first, then range-based structure
              flat_ssd_path = File.join(ssd_backup, project[:id])
              if Dir.exist?(flat_ssd_path)
                ssd_bytes += calculate_directory_size(flat_ssd_path)
              else
                range = determine_range(project[:id])
                range_ssd_path = File.join(ssd_backup, range, project[:id])
                ssd_bytes += calculate_directory_size(range_ssd_path) if Dir.exist?(range_ssd_path)
              end
            end
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

        def run_validations(projects)
          puts '🔍 Running validations...'
          warnings = []

          projects.each do |project|
            warnings << "⚠️  Invalid project ID format: #{project[:id]}" unless valid_project_id?(project[:id])
          end

          if warnings.empty?
            puts '✅ All validations passed!'
          else
            puts "#{warnings.size} warning(s) found:"
            warnings.each { |w| puts "   #{w}" }
          end
        end

        # Helper methods

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
            "#{letter}%02d-#{letter}%02d" % [range_start, range_end]
          else
            # Legacy pattern or unknown
            '000-099'
          end
        end

        def valid_project_id?(project_id)
          # Valid formats:
          # - Modern: letter + 2 digits + dash + name (e.g., b63-flivideo)
          # - Legacy: just numbers (e.g., 006-ac-carnivore-90)
          !!(project_id =~ /^[a-z]\d{2}-/ || project_id =~ /^\d/)
        end

        def range_folder?(folder_name)
          # Range folder patterns with letter prefixes:
          # - b00-b49, b50-b99, a00-a49, a50-a99 (letter + 2 digits + dash + same letter + 2 digits)
          # - 000-099 (3 digits + dash + 3 digits)
          # Must match: same letter on both sides (b00-b49, not b00-a49)
          return true if folder_name =~ /^\d{3}-\d{3}$/

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
