# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # S3 operations for VAT (upload, download, status, cleanup).
      # Inherits shared infrastructure and helpers from S3Base.
      # Will become a thin delegation facade as focused classes are extracted (B020).
      class S3Operations < S3Base
        # Upload files from s3-staging/ to S3
        def upload(dry_run: false)
          S3Uploader.new(brand, project_id, **delegated_opts).upload(dry_run: dry_run)
        end

        # Download files from S3 to s3-staging/
        def download(dry_run: false)
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          # Ensure project directory exists before download
          unless Dir.exist?(project_dir)
            puts "📁 Creating project directory: #{project_id}"
            FileUtils.mkdir_p(project_dir) unless dry_run
          end

          s3_files = list_s3_files

          if s3_files.empty?
            puts "❌ No files found in S3 for #{brand}/#{project_id}"
            return
          end

          total_size = s3_files.sum { |f| f['Size'] || 0 }
          puts "📦 Downloading #{s3_files.size} file(s) (#{file_size_human(total_size)}) from S3 to #{project_id}/s3-staging/..."
          puts ''

          downloaded = 0
          skipped = 0
          failed = 0

          # rubocop:disable Metrics/BlockLength
          s3_files.each do |s3_file|
            key = s3_file['Key']
            relative_path = extract_relative_path(key)
            local_file = File.join(staging_dir, relative_path)

            # Check if file already exists and compare
            s3_etag = s3_file['ETag'].gsub('"', '')
            s3_size = s3_file['Size']

            if File.exist?(local_file)
              match_status = compare_files(local_file: local_file, s3_etag: s3_etag, s3_size: s3_size)

              if match_status == :synced
                comparison_method = multipart_etag?(s3_etag) ? 'size match' : 'unchanged'
                puts "  ⏭️  Skipped: #{relative_path} (#{comparison_method})"
                skipped += 1
                next
              end

              # File exists but content differs - warn before overwriting
              puts "  ⚠️  Warning: #{relative_path} exists locally with different content"
              puts '     (multipart upload detected - comparing by size)' if multipart_etag?(s3_etag)

              if s3_file['LastModified']
                s3_time = s3_file['LastModified']
                local_time = File.mtime(local_file)
                puts "     S3: #{s3_time.strftime('%Y-%m-%d %H:%M')} | Local: #{local_time.strftime('%Y-%m-%d %H:%M')}"

                puts '     ⚠️  Local file is NEWER than S3 - you may be overwriting recent changes!' if local_time > s3_time
              end
              puts '     Downloading will overwrite local version...'
            end

            if download_file(key, local_file, dry_run: dry_run)
              downloaded += 1
            else
              failed += 1
            end
          end
          # rubocop:enable Metrics/BlockLength
          puts ''
          puts '✅ Download complete!'
          puts "   Downloaded: #{downloaded}, Skipped: #{skipped}, Failed: #{failed}"
        end

        # Show sync status
        def status
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          # Check if project directory exists
          unless Dir.exist?(project_dir)
            puts "❌ Project not found: #{brand}/#{project_id}"
            puts ''
            puts '   This project does not exist locally.'
            puts '   Possible causes:'
            puts '     - Project name might be misspelled'
            puts '     - Project may not exist in this brand'
            puts ''
            puts "   Try: dam list #{brand}   # See all projects for this brand"
            return
          end

          s3_files = list_s3_files
          local_files = list_local_files(staging_dir)

          # Build a map of S3 files for quick lookup
          s3_files_map = s3_files.each_with_object({}) do |file, hash|
            relative_path = extract_relative_path(file['Key'])
            hash[relative_path] = file
          end

          if s3_files.empty? && local_files.empty?
            puts "ℹ️  No files in S3 or s3-staging/ for #{brand}/#{project_id}"
            puts ''
            puts '   This project exists but has no heavy files ready for S3 sync.'
            puts ''
            puts '   Next steps:'
            puts "     1. Add video files to: #{staging_dir}/"
            puts "     2. Upload to S3: dam s3-up #{brand} #{project_id}"
            return
          end

          puts "📊 S3 Sync Status for #{brand}/#{project_id}"

          # Show last sync time
          if s3_files.any?
            most_recent = s3_files.map { |f| f['LastModified'] }.compact.max
            if most_recent
              time_ago = format_time_ago(Time.now - most_recent)
              puts "   Last synced: #{time_ago} ago (#{most_recent.strftime('%Y-%m-%d %H:%M')})"
            end
          end
          puts ''

          # Combine all file paths (S3 + local)
          all_paths = (s3_files_map.keys + local_files.keys).uniq.sort

          total_s3_size = 0
          total_local_size = 0

          all_paths.each do |relative_path|
            s3_file = s3_files_map[relative_path]
            local_file = File.join(staging_dir, relative_path)

            if s3_file && File.exist?(local_file)
              # File exists in both S3 and local
              s3_size = s3_file['Size']
              local_size = File.size(local_file)
              total_s3_size += s3_size
              total_local_size += local_size

              s3_etag = s3_file['ETag'].gsub('"', '')
              match_status = compare_files(local_file: local_file, s3_etag: s3_etag, s3_size: s3_size)

              if match_status == :synced
                status_label = multipart_etag?(s3_etag) ? 'synced*' : 'synced'
                puts "  ✓ #{relative_path} (#{file_size_human(s3_size)}) [#{status_label}]"
              else
                puts "  ⚠️  #{relative_path} (#{file_size_human(s3_size)}) [modified]"
              end
            elsif s3_file
              # File only in S3
              s3_size = s3_file['Size']
              total_s3_size += s3_size
              puts "  ☁️  #{relative_path} (#{file_size_human(s3_size)}) [S3 only]"
            else
              # File only local
              local_size = File.size(local_file)
              total_local_size += local_size
              puts "  📁 #{relative_path} (#{file_size_human(local_size)}) [local only]"
            end
          end

          puts ''
          puts "S3 files: #{s3_files.size}, Local files: #{local_files.size}"
          puts "S3 size: #{file_size_human(total_s3_size)}, Local size: #{file_size_human(total_local_size)}"
        end

        # Cleanup S3 files
        def cleanup(force: false, dry_run: false)
          s3_files = list_s3_files

          if s3_files.empty?
            puts "❌ No files found in S3 for #{brand}/#{project_id}"
            return
          end

          puts "🗑️  Found #{s3_files.size} file(s) in S3 for #{brand}/#{project_id}"
          puts ''

          unless force
            puts '⚠️  This will DELETE all files from S3 for this project.'
            puts 'Use --force to confirm deletion.'
            return
          end

          deleted = 0
          failed = 0

          s3_files.each do |s3_file|
            key = s3_file['Key']
            relative_path = extract_relative_path(key)

            if delete_s3_file(key, dry_run: dry_run)
              puts "  ✓ Deleted: #{relative_path}"
              deleted += 1
            else
              puts "  ✗ Failed: #{relative_path}"
              failed += 1
            end
          end

          puts ''
          puts '✅ Cleanup complete!'
          puts "   Deleted: #{deleted}, Failed: #{failed}"
        end

        # Cleanup local s3-staging files
        def cleanup_local(force: false, dry_run: false)
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          unless Dir.exist?(staging_dir)
            puts "❌ No s3-staging directory found: #{staging_dir}"
            return
          end

          files = Dir.glob("#{staging_dir}/**/*").select { |f| File.file?(f) }

          if files.empty?
            puts '❌ No files found in s3-staging/'
            return
          end

          puts "🗑️  Found #{files.size} file(s) in local s3-staging/"
          puts ''

          unless force
            puts '⚠️  This will DELETE all files from s3-staging/ for this project.'
            puts 'Use --force to confirm deletion.'
            return
          end

          deleted = 0
          failed = 0

          files.each do |file|
            relative_path = file.sub("#{staging_dir}/", '')

            if delete_local_file(file, dry_run: dry_run)
              puts "  ✓ Deleted: #{relative_path}"
              deleted += 1
            else
              puts "  ✗ Failed: #{relative_path}"
              failed += 1
            end
          end

          # Remove empty directories
          Dir.glob("#{staging_dir}/**/*").select { |d| File.directory?(d) }.sort.reverse.each do |dir|
            Dir.rmdir(dir) if Dir.empty?(dir)
          rescue StandardError
            nil
          end

          puts ''
          puts '✅ Local cleanup complete!'
          puts "   Deleted: #{deleted}, Failed: #{failed}"
        end

        # Archive project to SSD
        def archive(force: false, dry_run: false)
          ssd_backup = brand_info.locations.ssd_backup

          unless ssd_backup && !ssd_backup.empty?
            puts "❌ SSD backup location not configured for brand '#{brand}'"
            return
          end

          unless Dir.exist?(ssd_backup)
            puts "❌ SSD not mounted at #{ssd_backup}"
            puts '   Please connect the SSD before archiving.'
            return
          end

          project_dir = project_directory_path

          unless Dir.exist?(project_dir)
            puts "❌ Project not found: #{project_dir}"
            puts ''
            puts "   Try: dam list #{brand}  # See available projects"
            return
          end

          # Determine SSD destination path
          ssd_project_dir = File.join(ssd_backup, project_id)

          puts "📦 Archive: #{brand}/#{project_id}"
          puts ''

          # Step 1: Copy to SSD
          if copy_to_ssd(project_dir, ssd_project_dir, dry_run: dry_run)
            # Step 2: Delete local project (if force is true)
            if force
              delete_local_project(project_dir, dry_run: dry_run)
            else
              puts ''
              puts '⚠️  Project copied to SSD but NOT deleted locally.'
              puts '   Use --force to delete local copy after archiving.'
            end
          end

          puts ''
          puts dry_run ? '✅ Archive dry-run complete!' : '✅ Archive complete!'
        end

        # Calculate 3-state S3 sync status
        # @return [String] One of: '↑ upload', '↓ download', '✓ synced', 'none'
        def calculate_sync_status
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          # No s3-staging directory means no S3 intent
          return 'none' unless Dir.exist?(staging_dir)

          # Get S3 files (if S3 configured)
          begin
            s3_files = list_s3_files
          rescue StandardError
            # S3 not configured or not accessible
            return 'none'
          end

          local_files = list_local_files(staging_dir)

          # No files anywhere
          return 'none' if s3_files.empty? && local_files.empty?

          # Build S3 files map
          s3_files_map = s3_files.each_with_object({}) do |file, hash|
            relative_path = extract_relative_path(file['Key'])
            hash[relative_path] = file
          end

          # Check for differences
          needs_upload = false
          needs_download = false

          # Check all local files
          local_files.each_key do |relative_path|
            local_file = File.join(staging_dir, relative_path)
            s3_file = s3_files_map[relative_path]

            if s3_file
              # Compare using multipart-aware comparison
              s3_etag = s3_file['ETag'].gsub('"', '')
              s3_size = s3_file['Size']
              match_status = compare_files(local_file: local_file, s3_etag: s3_etag, s3_size: s3_size)
              needs_upload = true if match_status != :synced
            else
              # Local file not in S3
              needs_upload = true
            end
          end

          # Check for S3-only files
          s3_files_map.each_key do |relative_path|
            local_file = File.join(staging_dir, relative_path)
            needs_download = true unless File.exist?(local_file)
          end

          # Return status based on what's needed
          if needs_upload && needs_download
            '⚠️ both'
          elsif needs_upload
            '↑ upload'
          elsif needs_download
            '↓ download'
          else
            '✓ synced'
          end
        end

        # Calculate S3 sync timestamps (last upload/download times)
        # @return [Hash] { last_upload: Time|nil, last_download: Time|nil }
        def sync_timestamps
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          # No s3-staging directory means no S3 intent
          return { last_upload: nil, last_download: nil } unless Dir.exist?(staging_dir)

          # Get S3 files (if S3 configured)
          begin
            s3_files = list_s3_files
          rescue StandardError
            # S3 not configured or not accessible
            return { last_upload: nil, last_download: nil }
          end

          # Last upload time = most recent S3 file LastModified
          last_upload = s3_files.map { |f| f['LastModified'] }.compact.max if s3_files.any?

          # Last download time = most recent local file mtime (in s3-staging)
          last_download = if Dir.exist?(staging_dir)
                            local_files = Dir.glob(File.join(staging_dir, '**/*')).select { |f| File.file?(f) }
                            local_files.map { |f| File.mtime(f) }.max if local_files.any?
                          end

          { last_upload: last_upload, last_download: last_download }
        end

        private

        def delegated_opts
          { brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override }
        end

        # Download file from S3
        def download_file(s3_key, local_file, dry_run: false)
          if dry_run
            puts "  [DRY-RUN] Would download: s3://#{brand_info.aws.s3_bucket}/#{s3_key} → #{local_file}"
            return true
          end

          FileUtils.mkdir_p(File.dirname(local_file))

          start_time = Time.now

          s3_client.get_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_key,
            response_target: local_file
          )

          elapsed = Time.now - start_time
          elapsed_str = format_duration(elapsed)
          file_size = File.size(local_file)
          puts "  ✓ Downloaded: #{File.basename(local_file)} (#{file_size_human(file_size)}) in #{elapsed_str}"
          true
        rescue Aws::S3::Errors::ServiceError => e
          puts "  ✗ Failed: #{File.basename(local_file)}"
          puts "    Error: #{e.message}"
          false
        end

        # Delete file from S3
        def delete_s3_file(s3_key, dry_run: false)
          if dry_run
            puts "  [DRY-RUN] Would delete: s3://#{brand_info.aws.s3_bucket}/#{s3_key}"
            return true
          end

          s3_client.delete_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_key
          )

          true
        rescue Aws::S3::Errors::ServiceError => e
          puts "    Error: #{e.message}"
          false
        end

        # Delete local file
        def delete_local_file(file_path, dry_run: false)
          if dry_run
            puts "  [DRY-RUN] Would delete: #{file_path}"
            return true
          end

          File.delete(file_path)
          true
        rescue StandardError => e
          puts "    Error: #{e.message}"
          false
        end

        # Copy project to SSD
        def copy_to_ssd(source_dir, dest_dir, dry_run: false)
          if Dir.exist?(dest_dir)
            puts '⚠️  Already exists on SSD'
            puts "   Path: #{dest_dir}"
            puts '   Skipping copy step'
            return true
          end

          size = calculate_directory_size(source_dir)
          puts '📋 Copy to SSD (excluding generated files):'
          puts "   From: #{source_dir}"
          puts "   To:   #{dest_dir}"
          puts "   Size: #{file_size_human(size)}"
          puts ''

          if dry_run
            puts '   [DRY-RUN] Would copy project to SSD (excluding node_modules, .git, etc.)'
            return true
          end

          FileUtils.mkdir_p(dest_dir)

          # Copy files with exclusion filtering
          stats = copy_with_exclusions(source_dir, dest_dir)

          puts "   ✅ Copied to SSD (#{stats[:files]} files, excluded #{stats[:excluded]} generated files)"

          true
        rescue StandardError => e
          puts "   ✗ Failed to copy: #{e.message}"
          false
        end

        # Copy directory contents with exclusion filtering
        def copy_with_exclusions(source_dir, dest_dir)
          stats = { files: 0, excluded: 0 }

          Dir.glob(File.join(source_dir, '**', '*'), File::FNM_DOTMATCH).each do |source_path|
            next if File.directory?(source_path)
            next if ['.', '..'].include?(File.basename(source_path))

            relative_path = source_path.sub("#{source_dir}/", '')

            if excluded_path?(relative_path)
              stats[:excluded] += 1
              next
            end

            dest_path = File.join(dest_dir, relative_path)
            FileUtils.mkdir_p(File.dirname(dest_path))
            FileUtils.cp(source_path, dest_path, preserve: true)
            stats[:files] += 1
          end

          stats
        end

        # Delete local project directory
        def delete_local_project(project_dir, dry_run: false)
          size = calculate_directory_size(project_dir)

          puts ''
          puts '🗑️  Delete local project:'
          puts "   Path: #{project_dir}"
          puts "   Size: #{file_size_human(size)}"
          puts ''

          if dry_run
            puts '   [DRY-RUN] Would delete entire local folder'
            return true
          end

          FileUtils.rm_rf(project_dir)
          puts '   ✅ Deleted local folder'
          puts "   💾 Freed: #{file_size_human(size)}"

          true
        rescue StandardError => e
          puts "   ✗ Failed to delete: #{e.message}"
          false
        end

        # Calculate total size of a directory
        def calculate_directory_size(dir_path)
          FileHelper.calculate_directory_size(dir_path)
        end
      end
    end
  end
end
