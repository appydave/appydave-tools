# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 status and sync state operations.
      # Inherits shared infrastructure and helpers from S3Base.
      class S3StatusChecker < S3Base
        # Show sync status
        def status
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

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

          if s3_files.any?
            most_recent = s3_files.map { |f| f['LastModified'] }.compact.max
            if most_recent
              time_ago = format_time_ago(Time.now - most_recent)
              puts "   Last synced: #{time_ago} ago (#{most_recent.strftime('%Y-%m-%d %H:%M')})"
            end
          end
          puts ''

          all_paths = (s3_files_map.keys + local_files.keys).uniq.sort

          total_s3_size = 0
          total_local_size = 0

          all_paths.each do |relative_path|
            s3_file = s3_files_map[relative_path]
            local_file = File.join(staging_dir, relative_path)

            if s3_file && File.exist?(local_file)
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
              s3_size = s3_file['Size']
              total_s3_size += s3_size
              puts "  ☁️  #{relative_path} (#{file_size_human(s3_size)}) [S3 only]"
            else
              local_size = File.size(local_file)
              total_local_size += local_size
              puts "  📁 #{relative_path} (#{file_size_human(local_size)}) [local only]"
            end
          end

          puts ''
          puts "S3 files: #{s3_files.size}, Local files: #{local_files.size}"
          puts "S3 size: #{file_size_human(total_s3_size)}, Local size: #{file_size_human(total_local_size)}"
        end

        # Calculate 3-state S3 sync status
        # @return [String] One of: '↑ upload', '↓ download', '✓ synced', 'none'
        def calculate_sync_status
          project_dir = project_directory_path
          staging_dir = File.join(project_dir, 's3-staging')

          return 'none' unless Dir.exist?(staging_dir)

          begin
            s3_files = list_s3_files
          rescue StandardError
            return 'none'
          end

          local_files = list_local_files(staging_dir)

          return 'none' if s3_files.empty? && local_files.empty?

          s3_files_map = s3_files.each_with_object({}) do |file, hash|
            relative_path = extract_relative_path(file['Key'])
            hash[relative_path] = file
          end

          needs_upload = false
          needs_download = false

          local_files.each_key do |relative_path|
            local_file = File.join(staging_dir, relative_path)
            s3_file = s3_files_map[relative_path]

            if s3_file
              s3_etag = s3_file['ETag'].gsub('"', '')
              s3_size = s3_file['Size']
              match_status = compare_files(local_file: local_file, s3_etag: s3_etag, s3_size: s3_size)
              needs_upload = true if match_status != :synced
            else
              needs_upload = true
            end
          end

          s3_files_map.each_key do |relative_path|
            local_file = File.join(staging_dir, relative_path)
            needs_download = true unless File.exist?(local_file)
          end

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

          return { last_upload: nil, last_download: nil } unless Dir.exist?(staging_dir)

          begin
            s3_files = list_s3_files
          rescue StandardError
            return { last_upload: nil, last_download: nil }
          end

          last_upload = s3_files.map { |f| f['LastModified'] }.compact.max if s3_files.any?

          last_download = if Dir.exist?(staging_dir)
                            local_files = Dir.glob(File.join(staging_dir, '**/*')).select { |f| File.file?(f) }
                            local_files.map { |f| File.mtime(f) }.max if local_files.any?
                          end

          { last_upload: last_upload, last_download: last_download }
        end
      end
    end
  end
end
