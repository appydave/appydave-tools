# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 download operations.
      # Inherits shared infrastructure and helpers from S3Base.
      class S3Downloader < S3Base
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

        private

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
      end
    end
  end
end
