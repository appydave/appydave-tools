# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Brands configuration for video project management
        class BrandsConfig < ConfigBase
          # Retrieve brand information by brand key (string or symbol)
          def get_brand(brand_key)
            brand_key_str = brand_key.to_s

            # Try direct key lookup first (case-insensitive)
            brand_entry = data['brands'].find { |key, _info| key.downcase == brand_key_str.downcase }
            if brand_entry
              actual_key = brand_entry[0]
              return BrandInfo.new(actual_key, brand_entry[1])
            end

            # Try lookup by shortcut (case-insensitive)
            brand_entry = data['brands'].find { |_key, info| info['shortcut']&.downcase == brand_key_str.downcase }
            if brand_entry
              actual_key = brand_entry[0]
              return BrandInfo.new(actual_key, brand_entry[1])
            end

            # Return default if not found (use normalized lowercase key)
            BrandInfo.new(brand_key_str.downcase, default_brand_info)
          end

          # Set brand information
          def set_brand(brand_key, brand_info)
            data['brands'] ||= {}
            data['brands'][brand_key.to_s] = brand_info.to_h
          end

          # Retrieve a list of all brands
          def brands
            data['brands'].map do |key, info|
              BrandInfo.new(key, info)
            end
          end

          # Get brands for a specific user
          def get_brands_for_user(user_key)
            user_key = user_key.to_s
            brands.select { |brand| brand.team.include?(user_key) }
          end

          # Get user information
          def get_user(user_key)
            user_key = user_key.to_s
            info = data['users'][user_key] || default_user_info
            UserInfo.new(user_key, info)
          end

          # Set user information
          def set_user(user_key, user_info)
            data['users'] ||= {}
            data['users'][user_key.to_s] = user_info.to_h
          end

          # Retrieve a list of all users
          def users
            data['users'].map do |key, info|
              UserInfo.new(key, info)
            end
          end

          def key?(key)
            key = key.to_s
            data['brands'].key?(key)
          end

          def shortcut?(shortcut)
            shortcut = shortcut.to_s
            data['brands'].values.any? { |info| info['shortcut'] == shortcut }
          end

          def print
            log.heading 'Brands Configuration'

            print_brands = brands.map do |brand|
              {
                key: brand.key,
                name: brand.name,
                shortcut: brand.shortcut,
                type: brand.type,
                youtube_channels: brand.youtube_channels.join(', '),
                team: brand.team.join(', '),
                video_projects: print_location(brand.locations.video_projects),
                ssd_backup: print_location(brand.locations.ssd_backup),
                aws_profile: brand.aws.profile
              }
            end

            tp print_brands, :key, :name, :shortcut, :type, :youtube_channels, :team, :video_projects, :ssd_backup, :aws_profile
          end

          private

          def print_location(location)
            return 'Not Set' unless location
            return 'Not Set' if location.empty?

            File.exist?(location) ? 'TRUE' : 'false'
          end

          def default_data
            { 'brands' => {}, 'users' => {} }
          end

          def default_brand_info
            {
              'name' => '',
              'shortcut' => '',
              'type' => 'owned',
              'youtube_channels' => [],
              'team' => [],
              'git_remote' => nil,
              'locations' => {
                'video_projects' => '',
                'ssd_backup' => ''
              },
              'aws' => {
                'profile' => '',
                'region' => 'ap-southeast-1',
                's3_bucket' => '',
                's3_prefix' => ''
              },
              'settings' => {
                's3_cleanup_days' => 90
              }
            }
          end

          def default_user_info
            {
              'name' => '',
              'email' => '',
              'role' => 'team_member',
              'default_aws_profile' => ''
            }
          end

          # Type-safe class to access brand properties
          class BrandInfo
            attr_accessor :key, :name, :shortcut, :type, :youtube_channels, :team, :git_remote, :locations, :aws, :settings

            def initialize(key, data)
              @key = key
              @name = data['name']
              @shortcut = data['shortcut']
              @type = data['type'] || 'owned'
              @youtube_channels = data['youtube_channels'] || []
              @team = data['team'] || []
              @git_remote = data['git_remote']
              @locations = BrandLocation.new(data['locations'] || {})
              @aws = BrandAws.new(data['aws'] || {})
              @settings = BrandSettings.new(data['settings'] || {})
            end

            def to_h
              {
                'name' => @name,
                'shortcut' => @shortcut,
                'type' => @type,
                'youtube_channels' => @youtube_channels,
                'team' => @team,
                'git_remote' => @git_remote,
                'locations' => @locations.to_h,
                'aws' => @aws.to_h,
                'settings' => @settings.to_h
              }
            end
          end

          # Type-safe class to access brand location properties
          class BrandLocation
            attr_accessor :video_projects, :ssd_backup

            def initialize(data)
              @video_projects = data['video_projects']
              @ssd_backup = data['ssd_backup']
            end

            def to_h
              {
                'video_projects' => @video_projects,
                'ssd_backup' => @ssd_backup
              }
            end
          end

          # Type-safe class to access brand AWS properties
          class BrandAws
            attr_accessor :profile, :region, :s3_bucket, :s3_prefix

            def initialize(data)
              @profile = data['profile']
              @region = data['region'] || 'ap-southeast-1'
              @s3_bucket = data['s3_bucket']
              @s3_prefix = data['s3_prefix']
            end

            def to_h
              {
                'profile' => @profile,
                'region' => @region,
                's3_bucket' => @s3_bucket,
                's3_prefix' => @s3_prefix
              }
            end
          end

          # Type-safe class to access brand settings
          class BrandSettings
            attr_accessor :s3_cleanup_days, :projects_subfolder

            def initialize(data)
              @s3_cleanup_days = data['s3_cleanup_days'] || 90
              @projects_subfolder = data['projects_subfolder'] || ''
            end

            def to_h
              {
                's3_cleanup_days' => @s3_cleanup_days,
                'projects_subfolder' => @projects_subfolder
              }
            end
          end

          # Type-safe class to access user properties
          class UserInfo
            attr_accessor :key, :name, :email, :role, :default_aws_profile

            def initialize(key, data)
              @key = key
              @name = data['name']
              @email = data['email']
              @role = data['role'] || 'team_member'
              @default_aws_profile = data['default_aws_profile']
            end

            def to_h
              {
                'name' => @name,
                'email' => @email,
                'role' => @role,
                'default_aws_profile' => @default_aws_profile
              }
            end
          end
        end
      end
    end
  end
end
