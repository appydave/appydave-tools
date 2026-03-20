# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'digest'
require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # Shared infrastructure and helpers for S3 operations.
      # All focused S3 operation classes inherit from this base.
      class S3Base
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

        # Build S3 key for a file
        def build_s3_key(relative_path)
          "#{brand_info.aws.s3_prefix}#{project_id}/#{relative_path}"
        end

        # Extract relative path from S3 key
        def extract_relative_path(s3_key)
          s3_key.sub("#{brand_info.aws.s3_prefix}#{project_id}/", '')
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
          return { ssl_verify_peer: false } if ENV['AWS_SDK_RUBY_SKIP_SSL_VERIFICATION'] == 'true'

          {}
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
      end
    end
  end
end
