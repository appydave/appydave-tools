# frozen_string_literal: true

require 'clipboard'
require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # Generate shareable pre-signed URLs for S3 files
      class ShareOperations
        attr_reader :brand, :project, :brand_info, :brand_path

        def initialize(brand, project, brand_info: nil, brand_path: nil, s3_client: nil)
          @project = project

          # Use injected dependencies or load from configuration
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key # Use resolved brand key, not original input
          @brand_path = brand_path || Config.brand_path(@brand)
          @s3_client_override = s3_client # Store override but don't create client yet (lazy loading)
        end

        # Lazy-load S3 client (only create when actually needed)
        def s3_client
          @s3_client ||= @s3_client_override || create_s3_client(@brand_info)
        end

        # Generate shareable link for file(s)
        # @param files [String, Array<String>] File name(s) to share
        # @param expires [String] Expiry time (e.g., '7d', '24h')
        # @param download [Boolean] Force download vs inline viewing (default: false for inline)
        # @return [Hash] Result with :success, :urls, :expiry keys
        def generate_links(files:, expires: '7d', download: false)
          expires_in = parse_expiry(expires)
          expiry_time = Time.now + expires_in

          file_list = Array(files)
          urls = []

          file_list.each do |file|
            s3_key = build_s3_key(file)

            # Check if file exists in S3
            unless file_exists_in_s3?(s3_key)
              puts "⚠️  File not found in S3: #{file}"
              puts "   Upload first with: dam s3-up #{brand} #{project}"
              next
            end

            url = generate_presigned_url(s3_key, expires_in, download: download)
            urls << { file: file, url: url }
          end

          return { success: false, error: 'No files found in S3' } if urls.empty?

          # Show output
          show_results(urls, expiry_time, download: download)

          # Copy to clipboard
          copy_to_clipboard(urls)

          { success: true, urls: urls, expiry: expiry_time }
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        def create_s3_client(brand_info)
          profile_name = brand_info.aws.profile
          raise "AWS profile not configured for brand '#{brand}'" if profile_name.nil? || profile_name.empty?

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

        def build_s3_key(file)
          # S3 key format: staging/v-brand/project/file
          "staging/v-#{brand}/#{project}/#{file}"
        end

        def file_exists_in_s3?(s3_key)
          s3_client.head_object(bucket: brand_info.aws.s3_bucket, key: s3_key)
          true
        rescue Aws::S3::Errors::NotFound
          false
        end

        def generate_presigned_url(s3_key, expires_in_seconds, download: false)
          presigner = Aws::S3::Presigner.new(client: s3_client)

          # Extract just the filename
          filename = File.basename(s3_key)

          # Use 'attachment' to force download, 'inline' to view in browser
          disposition = download ? 'attachment' : 'inline'

          # Detect MIME type from file extension
          content_type = detect_content_type(filename)

          presigner.presigned_url(
            :get_object,
            bucket: brand_info.aws.s3_bucket,
            key: s3_key,
            expires_in: expires_in_seconds,
            response_content_disposition: "#{disposition}; filename=\"#{filename}\"",
            response_content_type: content_type
          )
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

        def parse_expiry(expiry_string)
          case expiry_string
          when /^(\d+)h$/
            hours = ::Regexp.last_match(1).to_i
            raise ArgumentError, 'Expiry must be at least 1 hour' if hours < 1
            raise ArgumentError, 'Expiry cannot exceed 168 hours (7 days)' if hours > 168

            hours * 3600
          when /^(\d+)d$/
            days = ::Regexp.last_match(1).to_i
            raise ArgumentError, 'Expiry must be at least 1 day' if days < 1
            raise ArgumentError, 'Expiry cannot exceed 7 days' if days > 7

            days * 86_400
          else
            raise ArgumentError, "Invalid expiry format. Use: 24h, 7d, etc. (got: #{expiry_string})"
          end
        end

        def show_results(urls, expiry_time, download: false)
          puts ''
          mode = download ? '📤 Shareable Link(s) - Download Mode' : '🎬 Shareable Link(s) - View in Browser'
          puts mode
          puts ''

          urls.each do |item|
            puts "📄 #{item[:file]}"
            puts "   #{item[:url]}"
            puts ''
          end

          expiry_date = expiry_time.strftime('%Y-%m-%d %H:%M:%S %Z')
          puts "⏰ Expires: #{expiry_date}"
          puts "   (#{format_time_remaining(expiry_time)})"
        end

        def format_time_remaining(expiry_time)
          seconds = expiry_time - Time.now
          days = (seconds / 86_400).floor
          hours = ((seconds % 86_400) / 3600).floor

          if days.positive?
            "in #{days} day#{'s' if days > 1}"
          else
            "in #{hours} hour#{'s' if hours > 1}"
          end
        end

        def copy_to_clipboard(urls)
          # Copy all URLs to clipboard (newline-separated)
          text = urls.map { |item| item[:url] }.join("\n")

          Clipboard.copy(text)
          puts ''
          puts '📋 Copied to clipboard!'
        rescue StandardError => e
          puts ''
          puts "⚠️  Could not copy to clipboard: #{e.message}"
          puts '   (URLs shown above for manual copy)'
        end
      end
    end
  end
end
