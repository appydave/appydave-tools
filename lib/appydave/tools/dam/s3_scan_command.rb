# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Encapsulates S3 scan logic: single-brand and all-brands scanning
      class S3ScanCommand
        # Scan a single brand's S3 bucket and update its manifest
        def scan_single(brand_key)
          puts "🔄 Scanning S3 for #{brand_key}..."
          puts ''

          scanner = Appydave::Tools::Dam::S3Scanner.new(brand_key)

          # Get brand info for S3 path
          Appydave::Tools::Configuration::Config.configure
          brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_key)
          bucket = brand_info.aws.s3_bucket
          prefix = brand_info.aws.s3_prefix
          region = brand_info.aws.region

          # Spinner characters for progress
          spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
          spinner_index = 0

          print "🔍 Scanning s3://#{bucket}/#{prefix}\n"
          print '    Scanning projects... '

          # Scan all projects with progress callback
          results = scanner.scan_all_projects(show_progress: false) do |current, total|
            print "\r    Scanning projects... #{spinner_chars[spinner_index]} (#{current}/#{total})"
            spinner_index = (spinner_index + 1) % spinner_chars.length
          end

          print "\r    Scanning projects... ✓ (#{results.size} found)\n"
          puts ''

          if results.empty?
            puts "⚠️  No projects found in S3 for #{brand_key}"
            puts '   This may indicate:'
            puts '   - No files uploaded to S3 yet'
            puts '   - S3 bucket or prefix misconfigured'
            puts '   - AWS credentials issue'
            return
          end

          # Load existing manifest
          brand_path = Appydave::Tools::Dam::Config.brand_path(brand_key)
          manifest_path = File.join(brand_path, 'projects.json')

          unless File.exist?(manifest_path)
            puts "❌ Manifest not found: #{manifest_path}"
            puts "   Run: dam manifest #{brand_key}"
            puts "   Then retry: dam s3-scan #{brand_key}"
            exit 1
          end

          manifest = JSON.parse(File.read(manifest_path), symbolize_names: true)

          # Identify matched and orphaned S3 projects
          local_project_ids = manifest[:projects].map { |p| p[:id] }
          matched_projects = results.slice(*local_project_ids)
          orphaned_projects = results.reject { |project_id, _| local_project_ids.include?(project_id) }

          # Merge S3 scan data into manifest for matched projects
          updated_count = 0
          manifest[:projects].each do |project|
            project_id = project[:id]
            s3_data = results[project_id]
            next unless s3_data

            project[:storage][:s3] = s3_data
            updated_count += 1
          end

          # Update timestamp and note
          manifest[:config][:last_updated] = Time.now.utc.iso8601
          manifest[:config][:note] = 'Auto-generated manifest with S3 scan data. Regenerate with: dam s3-scan'

          # Write updated manifest
          File.write(manifest_path, JSON.pretty_generate(manifest))

          # Add local sync status to matched projects
          Appydave::Tools::Dam::LocalSyncStatus.enrich!(matched_projects, brand_key)

          # Display table
          display_table(matched_projects, orphaned_projects, bucket, prefix, region)

          # Summary
          total_manifest_projects = manifest[:projects].size
          missing_count = total_manifest_projects - matched_projects.size

          puts ''
          puts 'ℹ️  Summary:'
          puts "   • Updated #{updated_count} projects in manifest"
          puts "   • #{missing_count} local project(s) not yet uploaded to S3" if missing_count.positive?
          puts "   • Manifest: #{manifest_path}"
          puts ''
        end

        # Scan all brands' S3 buckets
        def scan_all
          Appydave::Tools::Configuration::Config.configure
          brands_config = Appydave::Tools::Configuration::Config.brands

          results = []
          brands_config.brands.each do |brand_info|
            brand_key = brand_info.key
            puts ''
            puts '=' * 60

            begin
              scan_single(brand_key)
              results << { brand: brand_key, success: true }
            rescue StandardError => e
              puts "❌ Failed to scan #{brand_key}: #{e.message}"
              results << { brand: brand_key, success: false, error: e.message }
            end
          end

          puts ''
          puts '=' * 60
          puts '📋 Summary - S3 Scans:'
          puts ''

          successful, failed = results.partition { |r| r[:success] }

          successful.each do |result|
            brand_display = result[:brand].ljust(15)
            puts "✅ #{brand_display} Scanned successfully"
          end

          failed.each do |result|
            brand_display = result[:brand].ljust(15)
            puts "❌ #{brand_display} #{result[:error]}"
          end

          puts ''
          puts "Total brands scanned: #{successful.size}/#{results.size}"
        end

        private

        # Display S3 scan results in table format
        # rubocop:disable Style/FormatStringToken
        def display_table(matched_projects, orphaned_projects, bucket, prefix, region)
          puts '✅ S3 Projects Report'
          puts ''
          puts 'PROJECT                              FILES    SIZE        LOCAL      S3 MODIFIED'
          puts '-' * 92

          # Display matched projects first (sorted alphabetically)
          matched_projects.sort.each do |project_id, data|
            files = data[:file_count].to_s.rjust(5)
            size = Appydave::Tools::Dam::FileHelper.format_size(data[:total_bytes]).rjust(10)
            local_status = Appydave::Tools::Dam::LocalSyncStatus.format(data[:local_status], data[:local_file_count], data[:file_count])
            modified = data[:last_modified] ? Time.parse(data[:last_modified]).strftime('%Y-%m-%d %H:%M') : 'N/A'

            puts format('%-36s %5s %10s  %-9s  %s', project_id, files, size, local_status, modified)
          end

          # Display orphaned projects (sorted alphabetically)
          return if orphaned_projects.empty?

          puts '-' * 92
          orphaned_projects.sort.each do |project_id, data|
            files = data[:file_count].to_s.rjust(5)
            size = Appydave::Tools::Dam::FileHelper.format_size(data[:total_bytes]).rjust(10)
            local_status = 'N/A'
            modified = data[:last_modified] ? Time.parse(data[:last_modified]).strftime('%Y-%m-%d %H:%M') : 'N/A'

            puts format('%-36s %5s %10s  %-9s  %s', project_id, files, size, local_status, modified)
          end

          puts ''
          folder_word = orphaned_projects.size > 1 ? 'folders' : 'folder'
          puts "⚠️  #{orphaned_projects.size} orphaned #{folder_word} found (no local project)"

          orphaned_projects.sort.each do |project_id, _data|
            # Build AWS Console URL
            project_prefix = "#{prefix}#{project_id}/"
            console_url = "https://#{region}.console.aws.amazon.com/s3/buckets/#{bucket}?prefix=#{project_prefix}&region=#{region}"
            puts "   → #{project_id}"
            puts "     #{console_url}"
          end
        end
        # rubocop:enable Style/FormatStringToken
      end
    end
  end
end
