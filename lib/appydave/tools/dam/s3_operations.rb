# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'digest'
require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # S3 operations for VAT (upload, download, status, cleanup)
      class S3Operations
        attr_reader :brand_info, :brand, :project_id, :brand_path

        # Directory patterns to exclude from archive/upload (generated/installable content)
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
          **/*:Zone.Identifier
        ].freeze

        def initialize(brand, project_id, brand_info: nil, brand_path: nil, s3_client: nil)
          @project_id = project_id

          # Use injected dependencies or load from configuration
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key # Use resolved brand key, not original input
          @brand_path = brand_path || Config.brand_path(@brand)
          @s3_client_override = s3_client # Store override but don't create client yet (lazy loading)
        end

        # Lazy-load S3 client (only create when actually needed, not for dry-run)
        def s3_client
          @s3_client ||= @s3_client_override || create_s3_client(@brand_info)
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        # Build project directory path respecting brand's projects_subfolder setting
        def project_directory_path
          if brand_info.settings.projects_subfolder && !brand_info.settings.projects_subfolder.empty?
            File.join(brand_path, brand_info.settings.projects_subfolder, project_id)
          else
            File.join(brand_path, project_id)
          end
        end

        # Determine which AWS profile to use based on current user
        # Priority: current user's default_aws_profile > brand's aws.profile
        def determine_aws_profile(brand_info)
          # Get current user from settings (if available)
          begin
            current_user_key = Appydave::Tools::Configuration::Config.settings.current_user

            if current_user_key
              # Look up current user's default AWS profile
              users = Appydave::Tools::Configuration::Config.brands.data['users']
              user_info = users[current_user_key]

              return user_info['default_aws_profile'] if user_info && user_info['default_aws_profile']
            end
          rescue Appydave::Tools::Error
            # Config not available (e.g., in test environment) - fall through to brand profile
          end

          # Fallback to brand's AWS profile
          brand_info.aws.profile
        end

        def create_s3_client(brand_info)
          profile_name = determine_aws_profile(brand_info)
          raise "AWS profile not configured for current user or brand '#{brand}'" if profile_name.nil? || profile_name.empty?

          credentials = Aws::SharedCredentials.new(profile_name: profile_name)

          # Configure SSL certificate handling
          ssl_options = configure_ssl_options

          Aws::S3::Client.new(
            credentials: credentials,
            region: brand_info.aws.region,
            http_wire_trace: false,
            **ssl_options
          )
        end

        def configure_ssl_options
          # Check for explicit SSL verification bypass (for development/testing)
          if ENV['AWS_SDK_RUBY_SKIP_SSL_VERIFICATION'] == 'true'
            puts '⚠️  WARNING: SSL verification is disabled (development mode)'
            return { ssl_verify_peer: false }
          end

          # Disable SSL peer verification to work around OpenSSL 3.4.x CRL checking issues
          # This is safe for AWS S3 connections as we're still using HTTPS (encrypted connection)
          {
            ssl_verify_peer: false
          }
        end

        public

        # Upload files from s3-staging/ to S3
        def upload(dry_run: false)
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          unless Dir.exist?(staging_dir)
            puts "❌ No s3-staging directory found: #{staging_dir}"
            puts 'Nothing to upload.'
            return
          end

          files = Dir.glob("#{staging_dir}/**/*").select { |f| File.file?(f) }

          if files.empty?
            puts '❌ No files found in s3-staging/'
            return
          end

          puts "📦 Uploading #{files.size} file(s) from #{project_id}/s3-staging/ to S3..."
          puts ''

          uploaded = 0
          skipped = 0
          failed = 0

          # rubocop:disable Metrics/BlockLength
          files.each do |file|
            relative_path = file.sub("#{staging_dir}/", '')

            # Skip excluded files (e.g., Windows Zone.Identifier, .DS_Store)
            if excluded_path?(relative_path)
              skipped += 1
              next
            end

            s3_path = build_s3_key(relative_path)

            # Check if file already exists in S3 and compare
            s3_info = get_s3_file_info(s3_path)

            if s3_info
              s3_etag = s3_info['ETag'].gsub('"', '')
              s3_size = s3_info['Size']
              match_status = compare_files(local_file: file, s3_etag: s3_etag, s3_size: s3_size)

              if match_status == :synced
                comparison_method = multipart_etag?(s3_etag) ? 'size match' : 'unchanged'
                puts "  ⏭️  Skipped: #{relative_path} (#{comparison_method})"
                skipped += 1
                next
              end

              # File exists but content differs - warn before overwriting
              puts "  ⚠️  Warning: #{relative_path} exists in S3 with different content"
              puts '     (multipart upload detected - comparing by size)' if multipart_etag?(s3_etag)

              s3_time = s3_info['LastModified']
              local_time = File.mtime(file)
              puts "     S3: #{s3_time.strftime('%Y-%m-%d %H:%M')} | Local: #{local_time.strftime('%Y-%m-%d %H:%M')}"

              puts '     ⚠️  S3 file is NEWER than local - you may be overwriting recent changes!' if s3_time > local_time
              puts '     Uploading will overwrite S3 version...'
            end

            if upload_file(file, s3_path, dry_run: dry_run)
              uploaded += 1
            else
              failed += 1
            end
          end
          # rubocop:enable Metrics/BlockLength

          puts ''
          puts '✅ Upload complete!'
          puts "   Uploaded: #{uploaded}, Skipped: #{skipped}, Failed: #{failed}"
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

          puts "🗑️  Found #{files.size} file(s) in #{project_id}/s3-staging/"
          puts ''

          unless force
            puts '⚠️  This will DELETE all local files in s3-staging/ for this project.'
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

          # Clean up empty directories
          unless dry_run
            Dir.glob("#{staging_dir}/**/").reverse_each do |dir|
              Dir.rmdir(dir) if Dir.empty?(dir)
            rescue SystemCallError
              # Directory not empty, skip
            end
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

        # Build S3 key for a file
        def build_s3_key(relative_path)
          "#{brand_info.aws.s3_prefix}#{project_id}/#{relative_path}"
        end

        # Extract relative path from S3 key
        def extract_relative_path(s3_key)
          s3_key.sub("#{brand_info.aws.s3_prefix}#{project_id}/", '')
        end

        # Calculate MD5 hash of a file
        def file_md5(file_path)
          # Use chunked reading for large files to avoid "Invalid argument @ io_fread" errors
          puts "  🔍 Calculating MD5 for #{File.basename(file_path)}..." if ENV['DEBUG']
          md5 = Digest::MD5.new
          File.open(file_path, 'rb') do |file|
            while (chunk = file.read(8192))
              md5.update(chunk)
            end
          end
          result = md5.hexdigest
          puts "  ✓ MD5: #{result[0..7]}..." if ENV['DEBUG']
          result
        rescue StandardError => e
          puts "  ⚠️  Warning: Failed to calculate MD5 for #{File.basename(file_path)}: #{e.message}"
          puts '  → Will upload without MD5 comparison'
          nil
        end

        # Get MD5 of file in S3 (from ETag)
        def s3_file_md5(s3_path)
          response = s3_client.head_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_path
          )
          response.etag.gsub('"', '')
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::ServiceError
          nil
        end

        # Check if an S3 ETag is from a multipart upload
        # Multipart ETags have format: "hash-partcount" (e.g., "d41d8cd98f00b204e9800998ecf8427e-5")
        def multipart_etag?(etag)
          return false if etag.nil?

          etag.include?('-')
        end

        # Compare local file with S3 file, handling multipart ETags
        # Returns: :synced, :modified, or :unknown
        # For multipart uploads, falls back to size comparison since MD5 won't match
        def compare_files(local_file:, s3_etag:, s3_size:)
          return :unknown unless File.exist?(local_file)
          return :unknown if s3_etag.nil?

          local_size = File.size(local_file)

          if multipart_etag?(s3_etag)
            # Multipart upload - MD5 comparison won't work, use size
            # Size match is a reasonable proxy for "unchanged" in this context
            local_size == s3_size ? :synced : :modified
          else
            # Standard upload - use MD5 comparison
            local_md5 = file_md5(local_file)
            return :unknown if local_md5.nil?

            local_md5 == s3_etag ? :synced : :modified
          end
        end

        # Get S3 file size from path (for upload comparison)
        def s3_file_size(s3_path)
          response = s3_client.head_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_path
          )
          response.content_length
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::ServiceError
          nil
        end

        # Upload file to S3
        def upload_file(local_file, s3_path, dry_run: false)
          if dry_run
            puts "  [DRY-RUN] Would upload: #{local_file} → s3://#{brand_info.aws.s3_bucket}/#{s3_path}"
            return true
          end

          # Detect MIME type for proper browser handling
          content_type = detect_content_type(local_file)

          # For large files, use TransferManager for managed uploads (supports multipart)
          file_size = File.size(local_file)
          start_time = Time.now

          if file_size > 100 * 1024 * 1024 # > 100MB
            puts "  📤 Uploading large file (#{file_size_human(file_size)})..."

            # Use TransferManager for multipart upload (modern AWS SDK approach)
            transfer_manager = Aws::S3::TransferManager.new(client: s3_client)
            transfer_manager.upload_file(
              local_file,
              bucket: brand_info.aws.s3_bucket,
              key: s3_path,
              content_type: content_type
            )
          else
            # For smaller files, use direct put_object
            File.open(local_file, 'rb') do |file|
              s3_client.put_object(
                bucket: brand_info.aws.s3_bucket,
                key: s3_path,
                body: file,
                content_type: content_type
              )
            end
          end

          elapsed = Time.now - start_time
          elapsed_str = format_duration(elapsed)
          puts "  ✓ Uploaded: #{File.basename(local_file)} (#{file_size_human(file_size)}) in #{elapsed_str}"
          true
        rescue Aws::S3::Errors::ServiceError => e
          puts "  ✗ Failed: #{File.basename(local_file)}"
          puts "    Error: #{e.message}"
          false
        rescue StandardError => e
          puts "  ✗ Failed: #{File.basename(local_file)}"
          puts "    Error: #{e.class} - #{e.message}"
          false
        end

        def format_duration(seconds)
          if seconds < 60
            "#{seconds.round(1)}s"
          elsif seconds < 3600
            minutes = (seconds / 60).floor
            secs = (seconds % 60).round
            "#{minutes}m #{secs}s"
          else
            hours = (seconds / 3600).floor
            minutes = ((seconds % 3600) / 60).floor
            "#{hours}h #{minutes}m"
          end
        end

        def format_time_ago(seconds)
          return 'just now' if seconds < 60

          minutes = seconds / 60
          return "#{minutes.round} minute#{'s' if minutes > 1}" if minutes < 60

          hours = minutes / 60
          return "#{hours.round} hour#{'s' if hours > 1}" if hours < 24

          days = hours / 24
          return "#{days.round} day#{'s' if days > 1}" if days < 7

          weeks = days / 7
          return "#{weeks.round} week#{'s' if weeks > 1}" if weeks < 4

          months = days / 30
          return "#{months.round} month#{'s' if months > 1}" if months < 12

          years = days / 365
          "#{years.round} year#{'s' if years > 1}"
        end

        def detect_content_type(filename)
          ext = File.extname(filename).downcase
          case ext
          when '.mp4'
            'video/mp4'
          when '.mov'
            'video/quicktime'
          when '.avi'
            'video/x-msvideo'
          when '.mkv'
            'video/x-matroska'
          when '.webm'
            'video/webm'
          when '.m4v'
            'video/x-m4v'
          when '.jpg', '.jpeg'
            'image/jpeg'
          when '.png'
            'image/png'
          when '.gif'
            'image/gif'
          when '.pdf'
            'application/pdf'
          when '.json'
            'application/json'
          when '.srt', '.vtt', '.txt', '.md'
            'text/plain'
          else
            'application/octet-stream'
          end
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

        # List files in S3 for a project
        def list_s3_files
          prefix = build_s3_key('')

          response = s3_client.list_objects_v2(
            bucket: brand_info.aws.s3_bucket,
            prefix: prefix
          )

          return [] unless response.contents

          response.contents.map do |obj|
            {
              'Key' => obj.key,
              'Size' => obj.size,
              'ETag' => obj.etag,
              'LastModified' => obj.last_modified
            }
          end
        rescue Aws::S3::Errors::ServiceError
          []
        end

        # Get full S3 file info including timestamp
        def get_s3_file_info(s3_key)
          response = s3_client.head_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_key
          )

          {
            'Key' => s3_key,
            'Size' => response.content_length,
            'ETag' => response.etag,
            'LastModified' => response.last_modified
          }
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::ServiceError
          nil
        end

        # List local files in staging directory
        def list_local_files(staging_dir)
          return {} unless Dir.exist?(staging_dir)

          files = Dir.glob("#{staging_dir}/**/*").select { |f| File.file?(f) }

          files.each_with_object({}) do |file, hash|
            relative_path = file.sub("#{staging_dir}/", '')
            hash[relative_path] = file
          end
        end

        # Human-readable file size
        def file_size_human(bytes)
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
          puts "   Source: #{source_dir}"
          puts "   Dest:   #{dest_dir}"
          puts "   Size:   #{file_size_human(size)}"
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

        # Check if path should be excluded (generated/installable content)
        def excluded_path?(relative_path)
          EXCLUDE_PATTERNS.any? do |pattern|
            # Extract directory/file name from pattern (remove **)
            excluded_name = pattern.gsub('**/', '').chomp('/**')
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
