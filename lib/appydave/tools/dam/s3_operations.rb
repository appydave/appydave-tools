# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Thin delegation facade for S3 operations.
      # Each method delegates to a focused class that handles one concern.
      # Inherits shared infrastructure and helpers from S3Base.
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
          S3Archiver.new(brand, project_id, **delegated_opts).cleanup(force: force, dry_run: dry_run)
        end

        # Cleanup local s3-staging files
        def cleanup_local(force: false, dry_run: false)
          S3Archiver.new(brand, project_id, **delegated_opts).cleanup_local(force: force, dry_run: dry_run)
        end

        # Archive project to SSD
        def archive(force: false, dry_run: false)
          S3Archiver.new(brand, project_id, **delegated_opts).archive(force: force, dry_run: dry_run)
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
      end
    end
  end
end
