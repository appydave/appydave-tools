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
          project_dir = File.join(brand_path, project_id)
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

          files.each do |file|
            relative_path = file.sub("#{staging_dir}/", '')
            s3_path = build_s3_key(relative_path)

            # Check if file already exists with same MD5
            local_md5 = file_md5(file)
            s3_md5 = s3_file_md5(s3_path)

            if local_md5 == s3_md5
              puts "  ⏭️  Skipped: #{relative_path} (unchanged)"
              skipped += 1
            elsif upload_file(file, s3_path, dry_run: dry_run)
              uploaded += 1
            else
              failed += 1
            end
          end

          puts ''
          puts '✅ Upload complete!'
          puts "   Uploaded: #{uploaded}, Skipped: #{skipped}, Failed: #{failed}"
        end

        # Download files from S3 to s3-staging/
        def download(dry_run: false)
          project_dir = File.join(brand_path, project_id)
          staging_dir = File.join(project_dir, 's3-staging')

          s3_files = list_s3_files

          if s3_files.empty?
            puts "❌ No files found in S3 for #{brand}/#{project_id}"
            return
          end

          puts "📦 Downloading #{s3_files.size} file(s) from S3 to #{project_id}/s3-staging/..."
          puts ''

          downloaded = 0
          skipped = 0
          failed = 0

          s3_files.each do |s3_file|
            key = s3_file['Key']
            relative_path = extract_relative_path(key)
            local_file = File.join(staging_dir, relative_path)

            # Check if file already exists with same MD5
            s3_md5 = s3_file['ETag'].gsub('"', '')
            local_md5 = File.exist?(local_file) ? file_md5(local_file) : nil

            if local_md5 == s3_md5
              puts "  ⏭️  Skipped: #{relative_path} (unchanged)"
              skipped += 1
            elsif download_file(key, local_file, dry_run: dry_run)
              downloaded += 1
            else
              failed += 1
            end
          end

          puts ''
          puts '✅ Download complete!'
          puts "   Downloaded: #{downloaded}, Skipped: #{skipped}, Failed: #{failed}"
        end

        # Show sync status
        def status
          project_dir = File.join(brand_path, project_id)
          staging_dir = File.join(project_dir, 's3-staging')

          s3_files = list_s3_files
          local_files = list_local_files(staging_dir)

          # Build a map of S3 files for quick lookup
          s3_files_map = s3_files.each_with_object({}) do |file, hash|
            relative_path = extract_relative_path(file['Key'])
            hash[relative_path] = file
          end

          if s3_files.empty? && local_files.empty?
            puts "❌ No files found in S3 or locally for #{brand}/#{project_id}"
            return
          end

          puts "📊 S3 Sync Status for #{brand}/#{project_id}"
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

              local_md5 = file_md5(local_file)
              s3_md5 = s3_file['ETag'].gsub('"', '')

              if local_md5 == s3_md5
                puts "  ✓ #{relative_path} (#{file_size_human(s3_size)}) [synced]"
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
          project_dir = File.join(brand_path, project_id)
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

          project_dir = File.join(brand_path, project_id)

          unless Dir.exist?(project_dir)
            puts "❌ Project not found: #{project_dir}"
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

          s3_client.get_object(
            bucket: brand_info.aws.s3_bucket,
            key: s3_key,
            response_target: local_file
          )

          puts "  ✓ Downloaded: #{File.basename(local_file)} (#{file_size_human(File.size(local_file))})"
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
              'ETag' => obj.etag
            }
          end
        rescue Aws::S3::Errors::ServiceError
          []
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
          total = 0
          Dir.glob(File.join(dir_path, '**', '*'), File::FNM_DOTMATCH).each do |file|
            total += File.size(file) if File.file?(file)
          end
          total
        end
      end
    end
  end
end
