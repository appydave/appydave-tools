# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Parses and validates CLI arguments for S3-related dam commands
      # Handles brand resolution, project lookup, flag extraction, and ENV setup
      module S3ArgParser
        module_function

        def parse_s3(args, command)
          dry_run = args.include?('--dry-run')
          force = args.include?('--force')
          args = args.reject { |arg| arg.start_with?('--') }

          brand_arg = args[0]
          project_arg = args[1]

          if brand_arg.nil?
            # Auto-detect from PWD
            brand, project_id = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
            if brand.nil? || project_id.nil?
              raise Appydave::Tools::Dam::UsageError,
                    "Could not auto-detect brand/project from current directory. Usage: dam #{command} <brand> <project> [--dry-run]"
            end
            brand_key = brand # Already detected, use as-is
          else
            # Validate brand exists before trying to resolve project
            unless valid_brand?(brand_arg)
              raise Appydave::Tools::Dam::UsageError,
                    "Invalid brand: '#{brand_arg}'. Valid brands: appydave, voz, aitldr, kiros, joy, ss. Usage: dam #{command} <brand> <project> [--dry-run]"
            end

            brand_key = brand_arg # Use the shortcut/key (e.g., 'appydave')
            brand = Appydave::Tools::Dam::Config.expand_brand(brand_arg) # Expand for path resolution
            project_id = Appydave::Tools::Dam::ProjectResolver.resolve(brand_arg, project_arg)
          end

          # Set ENV for compatibility with ConfigLoader
          ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)

          { brand: brand_key, project: project_id, dry_run: dry_run, force: force }
        end

        def parse_share(args)
          # Extract --expires flag
          expires = '7d' # default
          if (expires_index = args.index('--expires'))
            expires = args[expires_index + 1]
            args.delete_at(expires_index + 1)
            args.delete_at(expires_index)
          end

          # Extract --download flag
          download = args.include?('--download')

          # Remove other flags
          args = args.reject { |arg| arg.start_with?('--') }

          brand_arg = args[0]
          project_arg = args[1]
          file_arg = args[2]

          raise_share_usage_error if brand_arg.nil? || project_arg.nil? || file_arg.nil?

          brand_key = brand_arg
          brand = Appydave::Tools::Dam::Config.expand_brand(brand_arg)
          project_id = Appydave::Tools::Dam::ProjectResolver.resolve(brand_arg, project_arg)

          # Set ENV for compatibility with ConfigLoader
          ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)

          { brand: brand_key, project: project_id, file: file_arg, expires: expires, download: download }
        end

        def parse_discover(args)
          shareable = args.include?('--shareable')
          args = args.reject { |arg| arg.start_with?('--') }

          brand_arg = args[0]
          project_arg = args[1]

          if brand_arg.nil? || project_arg.nil?
            raise Appydave::Tools::Dam::UsageError,
                  'Usage: dam s3-discover <brand> <project> [--shareable]'
          end

          brand_key = brand_arg
          brand = Appydave::Tools::Dam::Config.expand_brand(brand_arg)
          project_id = Appydave::Tools::Dam::ProjectResolver.resolve(brand_arg, project_arg)

          # Set ENV for compatibility with ConfigLoader
          ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)

          { brand_key: brand_key, project_id: project_id, shareable: shareable }
        end

        def valid_brand?(brand_key)
          Appydave::Tools::Configuration::Config.configure
          brands = Appydave::Tools::Configuration::Config.brands
          brands.key?(brand_key) || brands.shortcut?(brand_key)
        end

        def raise_share_usage_error
          raise Appydave::Tools::Dam::UsageError,
                'Usage: dam s3-share <brand> <project> <file> [--expires 7d] [--download]'
        end
      end
    end
  end
end
