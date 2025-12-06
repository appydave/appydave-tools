# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Show SSD mount status for all brands
      class SsdStatus
        attr_reader :brands_config

        def initialize(brands_config: nil)
          if brands_config
            @brands_config = brands_config
          else
            Appydave::Tools::Configuration::Config.configure
            @brands_config = Appydave::Tools::Configuration::Config.brands
          end
        end

        # Show SSD status for all brands
        def show_all
          results = collect_brand_statuses

          # Identify unique volumes
          volumes = results.select { |r| r[:configured] }
                           .map { |r| extract_volume_name(r[:ssd_path]) }
                           .compact
                           .uniq

          if volumes.empty?
            puts '⚠️  No SSD volumes configured'
            return
          end

          # Show simple mount status for each volume
          volumes.each do |volume|
            volume_path = "/Volumes/#{volume}"
            if Dir.exist?(volume_path)
              puts "✅ #{volume} is MOUNTED"
            else
              puts "❌ #{volume} is NOT MOUNTED"
            end
          end

          puts ''
          puts '| Brand          | Path                                   | Status       |'
          puts '|----------------|----------------------------------------|--------------|'
          results.each do |result|
            display_brand_row(result)
          end
        end

        # Show SSD status for a specific brand
        def show(brand_key)
          brand_info = @brands_config.get_brand(brand_key)
          ssd_path = brand_info.locations.ssd_backup

          puts "💾 SSD Status: #{brand_info.name} (#{brand_info.key})"
          puts ''

          if ssd_path.nil? || ssd_path.empty? || ssd_path == 'NOT-SET'
            puts '⚠️  SSD backup not configured for this brand'
            puts ''
            puts 'To configure, add ssd_backup to brands.json:'
            puts ''
            puts '  "locations": {'
            puts '    "video_projects": "/path/to/projects",'
            puts '    "ssd_backup": "/Volumes/T7/youtube-PUBLISHED/appydave"'
            puts '  }'
            return
          end

          puts "Path: #{ssd_path}"
          puts ''

          if Dir.exist?(ssd_path)
            display_mounted_details(brand_info, ssd_path)
          else
            display_unmounted_details(ssd_path)
          end
        end

        private

        def collect_brand_statuses
          @brands_config.brands.map do |brand_info|
            ssd_path = brand_info.locations.ssd_backup
            configured = ssd_path && !ssd_path.empty? && ssd_path != 'NOT-SET'
            mounted = configured && Dir.exist?(ssd_path)

            # Check if SSD volume is mounted but folder doesn't exist
            volume_mounted = false
            if configured && !mounted
              volume_name = extract_volume_name(ssd_path)
              volume_mounted = volume_name && Dir.exist?("/Volumes/#{volume_name}")
            end

            {
              brand: brand_info,
              ssd_path: ssd_path,
              configured: configured,
              mounted: mounted,
              volume_mounted: volume_mounted
            }
          end
        end

        def display_brand_row(result)
          brand_col = result[:brand].key.ljust(14)

          if result[:configured]
            path_col = truncate_path(result[:ssd_path], 38).ljust(38)
            status_col = if result[:mounted]
                           '✅ Ready'
                         elsif result[:volume_mounted]
                           '⚠️ No folder'
                         else
                           '❌ Not mounted'
                         end
          else
            path_col = '(not configured)'.ljust(38)
            status_col = '⚠️ N/A'
          end

          puts "| #{brand_col} | #{path_col} | #{status_col.ljust(12)} |"
        end

        def display_mounted_details(_brand_info, ssd_path)
          puts '✅ SSD is mounted'
          puts ''

          # Count projects on SSD
          project_dirs = Dir.glob(File.join(ssd_path, '*')).select { |f| File.directory?(f) }
          project_count = project_dirs.size

          # Calculate total size (quick estimate from directory count)
          puts "Projects on SSD: #{project_count}"

          # Show disk space info if available
          show_disk_space(ssd_path)

          # Show recent projects
          return unless project_count.positive?

          puts ''
          puts 'Recent projects (last 5 modified):'
          recent = project_dirs.sort_by { |d| File.mtime(d) }.reverse.first(5)
          recent.each do |dir|
            name = File.basename(dir)
            age = FileHelper.format_age(File.mtime(dir))
            puts "  #{name} (#{age} ago)"
          end
        end

        def display_unmounted_details(ssd_path)
          # Try to identify the volume
          volume_name = extract_volume_name(ssd_path)
          volume_path = "/Volumes/#{volume_name}" if volume_name

          if volume_name && Dir.exist?(volume_path)
            # SSD is mounted, but specific folder doesn't exist
            puts '⚠️  SSD is mounted but backup folder does NOT exist'
            puts ''
            puts "Volume '#{volume_name}' is connected, but the expected backup folder is missing."
            puts ''
            puts 'To create the backup folder:'
            puts "  mkdir -p #{ssd_path}"
            puts ''
            puts 'Or update brands.json with the correct path.'
          else
            # SSD is not mounted at all
            puts '❌ SSD is NOT mounted'
            puts ''
            puts 'Expected path does not exist.'
            puts ''

            if volume_name
              puts "Volume expected: #{volume_name}"
              puts ''
              puts 'To mount:'
              puts "  1. Connect the '#{volume_name}' drive"
              puts '  2. Verify it appears in /Volumes/'
              puts "  3. Run: ls #{ssd_path}"
            end
          end
        end

        def show_disk_space(ssd_path)
          # Use df to get disk space info
          output = `df -h "#{ssd_path}" 2>/dev/null`
          return if output.empty?

          lines = output.lines
          return unless lines.size >= 2

          # Parse df output (header + data line)
          parts = lines[1].split
          return unless parts.size >= 4

          size = parts[1]
          used = parts[2]
          avail = parts[3]
          capacity = parts[4] if parts.size >= 5

          puts ''
          puts 'Disk Space:'
          puts "  Total:     #{size}"
          puts "  Used:      #{used} (#{capacity})" if capacity
          puts "  Available: #{avail}"
        end

        def extract_volume_name(path)
          # Extract volume name from /Volumes/VolumeName/...
          match = path.match(%r{^/Volumes/([^/]+)})
          match[1] if match
        end

        def truncate_path(path, max_length)
          return path if path.nil? || path.length <= max_length

          # Keep the end of the path (more useful)
          "...#{path[-(max_length - 3)..]}"
        end
      end
    end
  end
end
