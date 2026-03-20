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
          S3Downloader.new(brand, project_id, **delegated_opts).download(dry_run: dry_run)
        end

        # Show sync status
        def status
          S3StatusChecker.new(brand, project_id, **delegated_opts).status
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
          S3StatusChecker.new(brand, project_id, **delegated_opts).calculate_sync_status
        end

        # Calculate S3 sync timestamps (last upload/download times)
        # @return [Hash] { last_upload: Time|nil, last_download: Time|nil }
        def sync_timestamps
          S3StatusChecker.new(brand, project_id, **delegated_opts).sync_timestamps
        end

        private

        def delegated_opts
          { brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override }
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
