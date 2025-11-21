# frozen_string_literal: true

require 'fileutils'
require 'json'

module Appydave
  module Tools
    module Dam
      # Sync light files from SSD to local for a brand
      # Only copies non-video files (subtitles, images, docs)
      class SyncFromSsd
        attr_reader :brand, :brand_info, :brand_path

        # Light file patterns to include (everything except heavy video files)
        LIGHT_FILE_PATTERNS = %w[
          **/*.srt
          **/*.vtt
          **/*.txt
          **/*.md
          **/*.jpg
          **/*.jpeg
          **/*.png
          **/*.webp
          **/*.json
          **/*.yml
          **/*.yaml
        ].freeze

        # Heavy file patterns to exclude (video files)
        HEAVY_FILE_PATTERNS = %w[
          *.mp4
          *.mov
          *.avi
          *.mkv
          *.webm
        ].freeze

        # Directory patterns to exclude (generated/installable content)
        EXCLUDE_PATTERNS = %w[
          **/node_modules/**
          **/.git/**
          **/.next/**
          **/dist/**
          **/build/**
          **/out/**
          **/.cache/**
          **/coverage/**
          **/.turbo/**
          **/.vercel/**
          **/tmp/**
          **/.DS_Store
        ].freeze

        def initialize(brand, brand_info: nil, brand_path: nil)
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key # Use resolved brand key, not original input
          @brand_path = brand_path || Config.brand_path(@brand)
        end

        # Sync light files from SSD for all projects in manifest
        def sync(dry_run: false)
          puts dry_run ? '🔍 DRY-RUN MODE - No files will be copied' : '📦 Syncing from SSD...'
          puts ''

          # Validate SSD is mounted
          ssd_backup = brand_info.locations.ssd_backup
          unless ssd_backup && !ssd_backup.empty?
            puts "❌ SSD backup location not configured for brand '#{brand}'"
            return
          end

          unless Dir.exist?(ssd_backup)
            puts "❌ SSD not mounted at #{ssd_backup}"
            return
          end

          # Load manifest
          manifest_file = File.join(brand_path, 'projects.json')
          unless File.exist?(manifest_file)
            puts '❌ projects.json not found!'
            puts "   Run: vat manifest #{brand}"
            return
          end

          manifest = load_manifest(manifest_file)
          puts "📋 Loaded manifest: #{manifest[:projects].size} projects"
          puts "   Last updated: #{manifest[:config][:last_updated]}"
          puts ''

          # Filter projects to sync
          projects_to_sync = manifest[:projects].select { |p| should_sync_project?(p) }

          puts '🔍 Analysis:'
          puts "   Total projects in manifest: #{manifest[:projects].size}"
          puts "   Projects to sync: #{projects_to_sync.size}"
          puts "   Skipped (already local): #{manifest[:projects].size - projects_to_sync.size}"
          puts ''

          if projects_to_sync.empty?
            puts '✅ Nothing to sync - all projects either already local or not on SSD'
            return
          end

          # Sync each project
          total_stats = { files: 0, bytes: 0, skipped: 0 }

          projects_to_sync.each do |project|
            stats = sync_project(project, ssd_backup, dry_run: dry_run)

            # Only show project if there are files to sync or a warning
            if stats[:reason] || stats[:files]&.positive?
              puts "📁 #{project[:id]}"

              puts "  ⚠️  Skipped: #{stats[:reason]}" if stats[:reason]

              puts "  #{stats[:files]} file(s), #{format_bytes(stats[:bytes])}" if stats[:files]&.positive?
              puts ''
            end

            total_stats[:files] += stats[:files] || 0
            total_stats[:bytes] += stats[:bytes] || 0
            total_stats[:skipped] += stats[:skipped] || 0
          end

          puts ''
          puts '=' * 60
          puts 'Summary:'
          puts "  Projects scanned: #{projects_to_sync.size}"
          puts "  Files #{dry_run ? 'to copy' : 'copied'}: #{total_stats[:files]}"
          puts "  Total size: #{format_bytes(total_stats[:bytes])}"
          puts ''
          puts '✅ Sync complete!'
          puts '   Run without --dry-run to perform the sync' if dry_run
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        def load_manifest(manifest_file)
          JSON.parse(File.read(manifest_file), symbolize_names: true)
        rescue JSON::ParserError => e
          puts "❌ Error parsing projects.json: #{e.message}"
          exit 1
        end

        # Determine if project should be synced
        def should_sync_project?(project)
          # Only sync if project exists on SSD but NOT locally (either flat or archived)
          return false unless project[:storage][:ssd][:exists]

          # Skip if exists locally in any structure (flat or archived)
          return false if project[:storage][:local][:exists]

          true
        end

        # Sync a single project from SSD to local
        def sync_project(project, ssd_backup, dry_run: false)
          project_id = project[:id]
          ssd_path = File.join(ssd_backup, project_id)

          return { skipped: 1, files: 0, bytes: 0, reason: 'SSD path not found' } unless Dir.exist?(ssd_path)

          # Check for flat folder conflict (stale manifest) - use Config.project_path to respect projects_subfolder
          flat_path = Config.project_path(brand, project_id)
          return { skipped: 1, files: 0, bytes: 0, reason: 'Flat folder exists (stale manifest?)' } if Dir.exist?(flat_path)

          # Determine local destination path (archived structure)
          # Extract range from project ID (e.g., b65 → 60-69 range)
          range = determine_range(project_id)
          local_dir = File.join(brand_path, 'archived', range, project_id)

          # Create local directory
          FileUtils.mkdir_p(local_dir) if !dry_run && !Dir.exist?(local_dir)

          # Sync light files
          sync_light_files(ssd_path, local_dir, dry_run: dry_run)
        end

        # Determine range folder for project (e.g., b65 → 60-69)
        def determine_range(project_id)
          # FliVideo pattern: b40, b41, ... b99
          if project_id =~ /^b(\d+)/
            tens = (Regexp.last_match(1).to_i / 10) * 10
            "#{tens}-#{tens + 9}"
          else
            # Legacy pattern or unknown: use first 3 chars
            '000-099'
          end
        end

        # Sync light files from SSD to local
        def sync_light_files(ssd_path, local_dir, dry_run: false)
          stats = { files: 0, bytes: 0 }

          LIGHT_FILE_PATTERNS.each do |pattern|
            Dir.glob(File.join(ssd_path, pattern)).each do |source_file|
              next if heavy_file?(source_file)
              next if excluded_file?(source_file, ssd_path)

              copy_stats = copy_light_file(source_file, ssd_path, local_dir, dry_run: dry_run)
              stats[:files] += copy_stats[:files]
              stats[:bytes] += copy_stats[:bytes]
            end
          end

          stats
        end

        # Check if file is a heavy video file
        def heavy_file?(source_file)
          HEAVY_FILE_PATTERNS.any? { |pattern| File.fnmatch(pattern, File.basename(source_file)) }
        end

        # Check if file should be excluded (generated/installable content)
        def excluded_file?(source_file, ssd_path)
          relative_path = source_file.sub("#{ssd_path}/", '')

          EXCLUDE_PATTERNS.any? do |pattern|
            # Extract directory/file name from pattern (remove **)
            # **/node_modules/** → node_modules
            # **/.git/** → .git
            # **/.DS_Store → .DS_Store
            excluded_name = pattern.gsub('**/', '').chomp('/**')

            # Check path segments for matches
            path_segments = relative_path.split('/')

            if excluded_name.include?('*')
              # Pattern with wildcards - use fnmatch on filename
              File.fnmatch(excluded_name, File.basename(relative_path))
            else
              # Check if any path segment matches the excluded name
              path_segments.include?(excluded_name)
            end
          end
        end

        # Copy a single light file
        def copy_light_file(source_file, ssd_path, local_dir, dry_run: false)
          relative_path = source_file.sub("#{ssd_path}/", '')
          dest_file = File.join(local_dir, relative_path)

          # Skip if already synced (same size)
          return { files: 0, bytes: 0 } if file_already_synced?(source_file, dest_file)

          file_size = File.size(source_file)

          if dry_run
            puts "  [DRY-RUN] Would copy: #{relative_path} (#{format_bytes(file_size)})"
          else
            FileUtils.mkdir_p(File.dirname(dest_file))
            FileUtils.cp(source_file, dest_file, preserve: true)
            puts "  ✓ Copied: #{relative_path} (#{format_bytes(file_size)})"
          end

          { files: 1, bytes: file_size }
        end

        # Check if file is already synced (by size comparison)
        def file_already_synced?(source_file, dest_file)
          File.exist?(dest_file) && File.size(dest_file) == File.size(source_file)
        end

        # Format bytes into human-readable format
        def format_bytes(bytes)
          FileUtils.format_size(bytes)
        end
      end
    end
  end
end
