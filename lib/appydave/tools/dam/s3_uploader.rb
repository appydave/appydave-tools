# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 upload operations.
      # Inherits shared infrastructure and helpers from S3Base.
      class S3Uploader < S3Base
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

        private

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
      end
    end
  end
end
