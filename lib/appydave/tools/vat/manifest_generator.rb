# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Vat
      # Generate manifest JSON for video projects
      class ManifestGenerator
        attr_reader :brand, :brand_info, :brand_path

        def initialize(brand, brand_info: nil, brand_path: nil)
          @brand = brand
          @brand_path = brand_path || Config.brand_path(brand)
          @brand_info = brand_info || load_brand_info(brand)
        end

        # Generate manifest for this brand
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
            return
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
            Dir.glob(File.join(ssd_backup, '*/')).each do |project_path|
              all_project_ids << File.basename(project_path)
            end
          end

          # Scan local (all projects in brand directory)
          Dir.glob(File.join(brand_path, '*/')).each do |path|
            basename = File.basename(path)
            # Skip hidden and special directories
            next if basename.start_with?('.', '_')
            next if %w[s3-staging archived final].include?(basename)

            all_project_ids << basename if valid_project_id?(basename)
          end

          all_project_ids.uniq.sort
        end

        def build_project_entries(all_project_ids, ssd_backup, ssd_available)
          projects = []

          all_project_ids.each do |project_id|
            local_path = File.join(brand_path, project_id)
            ssd_path = ssd_available ? File.join(ssd_backup, project_id) : nil

            local_exists = Dir.exist?(local_path)
            ssd_exists = ssd_path && Dir.exist?(ssd_path)

            projects << {
              id: project_id,
              storage: {
                ssd: {
                  exists: ssd_exists,
                  path: ssd_exists ? project_id : nil
                },
                local: {
                  exists: local_exists,
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
              local_path = File.join(brand_path, project[:id])
              local_bytes += calculate_directory_size(local_path)
            end

            if project[:storage][:ssd][:exists]
              ssd_path = File.join(ssd_backup, project[:id])
              ssd_bytes += calculate_directory_size(ssd_path)
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
        def valid_project_id?(project_id)
          # Valid formats:
          # - Modern: letter + 2 digits + dash + name (e.g., b63-flivideo)
          # - Legacy: just numbers (e.g., 006-ac-carnivore-90)
          !!(project_id =~ /^[a-z]\d{2}-/ || project_id =~ /^\d/)
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
