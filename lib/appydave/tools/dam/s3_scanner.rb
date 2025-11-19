# frozen_string_literal: true

require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # Scan S3 bucket for project files
      class S3Scanner
        attr_reader :brand_info, :brand, :s3_client

        def initialize(brand, brand_info: nil, s3_client: nil)
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key
          @s3_client = s3_client || create_s3_client(@brand_info)
        end

        # Scan S3 for a specific project
        # @param project_id [String] Project ID (e.g., "b65-guy-monroe-marketing-plan")
        # @return [Hash] S3 file data with :file_count, :total_bytes, :last_modified
        def scan_project(project_id)
          bucket = @brand_info.aws.s3_bucket
          prefix = File.join(@brand_info.aws.s3_prefix, project_id, '')

          puts "  🔍 Scanning #{project_id}..."

          files = list_s3_objects(bucket, prefix)

          if files.empty?
            return {
              exists: false,
              file_count: 0,
              total_bytes: 0,
              last_modified: nil
            }
          end

          total_bytes = files.sum(&:size)
          last_modified = files.map(&:last_modified).max

          {
            exists: true,
            file_count: files.size,
            total_bytes: total_bytes,
            last_modified: last_modified.utc.iso8601
          }
        rescue Aws::S3::Errors::ServiceError => e
          puts "  ⚠️  S3 scan failed for #{project_id}: #{e.message}"
          { exists: false, file_count: 0, total_bytes: 0, last_modified: nil, error: e.message }
        end

        # Scan all projects in brand's S3 bucket
        # @return [Hash] Map of project_id => scan result
        def scan_all_projects
          bucket = @brand_info.aws.s3_bucket
          prefix = @brand_info.aws.s3_prefix

          puts "🔍 Scanning all projects in S3: s3://#{bucket}/#{prefix}"
          puts ''

          # List all "directories" (prefixes) under brand prefix
          project_prefixes = list_s3_prefixes(bucket, prefix)

          if project_prefixes.empty?
            puts '  📭 No projects found in S3'
            return {}
          end

          puts "  Found #{project_prefixes.size} projects in S3"
          puts ''

          results = {}
          project_prefixes.each do |project_id|
            results[project_id] = scan_project(project_id)
          end

          results
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        # Determine which AWS profile to use based on current user
        # Priority: current user's default_aws_profile > brand's aws.profile
        def determine_aws_profile(brand_info)
          # Get current user from settings
          current_user_key = Appydave::Tools::Configuration::Config.settings.current_user

          if current_user_key
            # Look up current user's default AWS profile
            users = Appydave::Tools::Configuration::Config.brands.data['users']
            user_info = users[current_user_key]

            return user_info['default_aws_profile'] if user_info && user_info['default_aws_profile']
          end

          # Fallback to brand's AWS profile
          brand_info.aws.profile
        end

        def create_s3_client(brand_info)
          profile_name = determine_aws_profile(brand_info)
          raise "AWS profile not configured for current user or brand '#{@brand}'" if profile_name.nil? || profile_name.empty?

          credentials = Aws::SharedCredentials.new(profile_name: profile_name)

          Aws::S3::Client.new(
            credentials: credentials,
            region: brand_info.aws.region,
            http_wire_trace: false,
            ssl_verify_peer: false
          )
        end

        # List all objects under a prefix
        def list_s3_objects(bucket, prefix)
          objects = []
          continuation_token = nil

          loop do
            resp = s3_client.list_objects_v2(
              bucket: bucket,
              prefix: prefix,
              continuation_token: continuation_token
            )

            objects.concat(resp.contents)
            break unless resp.is_truncated

            continuation_token = resp.next_continuation_token
          end

          objects
        end

        # List project-level prefixes (directories) under brand prefix
        def list_s3_prefixes(bucket, prefix)
          resp = s3_client.list_objects_v2(
            bucket: bucket,
            prefix: prefix,
            delimiter: '/'
          )

          # common_prefixes returns array of prefixes like "staging/v-appydave/b65-guy-monroe/"
          resp.common_prefixes.map do |cp|
            # Extract project ID from prefix
            File.basename(cp.prefix.chomp('/'))
          end
        end
      end
    end
  end
end
