# frozen_string_literal: true

require 'json'

module Appydave
  module Tools
    module Dam
      # Show unified status for video project (local, S3, SSD, git)
      class Status
        attr_reader :brand, :project_id, :brand_info, :brand_path, :project_path

        def initialize(brand, project_id = nil)
          @brand_info = load_brand_info(brand)
          @brand = @brand_info.key
          @brand_path = Config.brand_path(@brand)
          @project_id = project_id
          @project_path = project_id ? resolve_project_path(project_id) : nil
        end

        # Show status for project or brand
        def show
          if project_id
            show_project_status
          else
            show_brand_status
          end
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        def resolve_project_path(project_id)
          # Resolve short name if needed (b65 -> b65-full-name)
          resolved = ProjectResolver.resolve(brand, project_id)
          Config.project_path(brand, resolved)
        end

        def show_project_status
          project_size = calculate_project_size
          last_modified = File.mtime(project_path)
          age = FileHelper.format_age(last_modified)

          puts "📊 Status: v-#{brand}/#{File.basename(project_path)} (#{format_size(project_size)})"
          puts "   Last modified: #{age} ago"
          puts ''

          manifest = load_manifest
          project_entry = find_project_in_manifest(manifest)

          unless project_entry
            puts '❌ Project not found in manifest'
            puts ''
            puts '   This project exists locally but is not in the manifest.'
            puts ''
            puts "   Try: dam manifest #{brand}  # Regenerate manifest"
            puts "   Or:  dam list #{brand}      # See tracked projects"
            return
          end

          show_storage_status(project_entry)
        end

        def show_brand_status
          puts "📊 Brand Status: v-#{brand}"
          puts ''

          # Show git status
          if git_repo?
            show_brand_git_status
          else
            puts 'Git: Not a git repository'
          end
          puts ''

          # Show manifest summary
          manifest = load_manifest
          if manifest
            show_manifest_summary(manifest)
            puts ''
            show_brand_suggestions(manifest)
          else
            puts '❌ Manifest not found'
            puts "   Run: dam manifest #{brand}"
          end
        end

        def show_storage_status(project_entry)
          puts 'Storage:'

          # Local storage
          show_local_status(project_entry)

          # S3 staging (inferred - only show if exists)
          show_s3_status(project_entry) if project_entry[:storage][:s3][:exists]

          # SSD backup (inferred - only show if configured and exists)
          show_ssd_status(project_entry) if brand_info.locations.ssd_backup &&
                                            brand_info.locations.ssd_backup != 'NOT-SET' &&
                                            project_entry[:storage][:ssd][:exists]

          puts ''
        end

        def show_local_status(project_entry)
          local = project_entry[:storage][:local]

          if local[:exists]
            puts '  📁 Local: ✓ exists'

            # Show heavy files with count and size
            if local[:has_heavy_files]
              heavy_info = count_and_size_heavy_files
              puts "     Heavy files: #{heavy_info[:count]} (#{format_size(heavy_info[:size])})"
            else
              puts '     Heavy files: none'
            end

            # Show light files with count and size
            if local[:has_light_files]
              light_info = count_and_size_light_files
              puts "     Light files: #{light_info[:count]} (#{format_size(light_info[:size])})"
            else
              puts '     Light files: none'
            end
          else
            puts '  📁 Local: ✗ does not exist'
          end
          puts ''
        end

        def show_s3_status(_project_entry)
          puts '  ☁️  S3 Staging: ✓ exists'

          # TODO: Query S3 for detailed status (files needing sync)
          # For now, just show that s3-staging folder exists locally
          s3_staging_path = File.join(project_path, 's3-staging')
          if Dir.exist?(s3_staging_path)
            file_count = Dir.glob(File.join(s3_staging_path, '*')).count
            puts "     Local staging files: #{file_count}"
          end
          puts ''
        end

        def show_ssd_status(project_entry)
          puts '  💾 SSD Backup: ✓ exists'

          ssd_path = project_entry[:storage][:ssd][:path]
          if ssd_path
            ssd_full_path = File.join(brand_info.locations.ssd_backup, ssd_path)
            puts "     Path: #{ssd_path}"

            if Dir.exist?(ssd_full_path)
              last_modified = File.mtime(ssd_full_path)
              age = FileHelper.format_age(last_modified)
              puts "     Last synced: #{age} ago"
            end
          end

          puts ''
        end

        def show_brand_git_status
          status = git_status_info

          puts "🌿 Branch: #{status[:branch]}"
          puts "📡 Remote: #{status[:remote]}" if status[:remote]

          if status[:modified_count].positive? || status[:untracked_count].positive?
            puts "↕️  Changes: #{status[:modified_count]} modified, #{status[:untracked_count]} untracked"
          else
            puts '✓ Working directory clean'
          end

          if status[:ahead].positive? || status[:behind].positive?
            puts "🔄 Sync: #{sync_status_text(status[:ahead], status[:behind])}"
          else
            puts '✓ Up to date with remote'
          end
        end

        def show_manifest_summary(manifest)
          puts '📋 Manifest Summary:'

          # Show manifest age
          if manifest[:config] && manifest[:config][:last_updated]
            age = calculate_manifest_age(manifest[:config][:last_updated])
            age_indicator = manifest_age_indicator(age)
            puts "   Last updated: #{format_manifest_age(age)} #{age_indicator}"
          end

          # Count active (flat/local) vs archived projects
          active_count = manifest[:projects].count do |p|
            p[:storage][:local][:exists] && p[:storage][:local][:structure] == 'flat'
          end
          archived_count = manifest[:projects].count do |p|
            p[:storage][:local][:exists] && p[:storage][:local][:structure] == 'archived'
          end
          total = manifest[:projects].size

          puts "   Total: #{total} (Active: #{active_count}, Archived: #{archived_count})"

          local_count = manifest[:projects].count { |p| p[:storage][:local][:exists] }
          s3_count = manifest[:projects].count { |p| p[:storage][:s3][:exists] }
          ssd_count = manifest[:projects].count { |p| p[:storage][:ssd][:exists] }

          puts "   Local: #{local_count}"
          puts "   S3 staging: #{s3_count}"

          # Show last S3 sync time if S3 is configured
          show_last_s3_sync_time if s3_configured?

          puts "   SSD backup: #{ssd_count}"

          # Project types
          storyline_count = manifest[:projects].count { |p| p[:type] == 'storyline' }
          flivideo_count = manifest[:projects].count { |p| p[:type] == 'flivideo' }
          general_count = manifest[:projects].count { |p| p[:type] == 'general' }

          puts ''
          puts "   Storyline: #{storyline_count}"
          puts "   FliVideo: #{flivideo_count}"
          puts "   General: #{general_count}" if general_count.positive?
        end

        def sync_status_text(ahead, behind)
          parts = []
          parts << "#{ahead} ahead" if ahead.positive?
          parts << "#{behind} behind" if behind.positive?
          parts.join(', ')
        end

        def load_manifest
          manifest_path = File.join(brand_path, 'projects.json')
          return nil unless File.exist?(manifest_path)

          JSON.parse(File.read(manifest_path), symbolize_names: true)
        rescue JSON::ParserError
          nil
        end

        def find_project_in_manifest(manifest)
          return nil unless manifest

          project_name = File.basename(project_path)
          manifest[:projects].find { |p| p[:id] == project_name }
        end

        def git_repo?
          git_dir = File.join(brand_path, '.git')
          Dir.exist?(git_dir)
        end

        def git_status_info
          {
            branch: current_branch,
            remote: remote_url,
            modified_count: modified_files_count,
            untracked_count: untracked_files_count,
            ahead: commits_ahead,
            behind: commits_behind
          }
        end

        def current_branch
          GitHelper.current_branch(brand_path)
        end

        def remote_url
          GitHelper.remote_url(brand_path)
        end

        def modified_files_count
          GitHelper.modified_files_count(brand_path)
        end

        def untracked_files_count
          GitHelper.untracked_files_count(brand_path)
        end

        def commits_ahead
          GitHelper.commits_ahead(brand_path)
        end

        def commits_behind
          GitHelper.commits_behind(brand_path)
        end

        def calculate_project_size
          FileHelper.calculate_directory_size(project_path)
        end

        def count_and_size_heavy_files
          count = 0
          size = 0
          Dir.glob(File.join(project_path, '*.{mp4,mov,avi,mkv,webm}')).each do |file|
            count += 1
            size += File.size(file)
          end
          { count: count, size: size }
        end

        def count_and_size_light_files
          count = 0
          size = 0
          Dir.glob(File.join(project_path, '**/*.{srt,vtt,jpg,png,md,txt,json,yml}')).each do |file|
            count += 1
            size += File.size(file)
          end
          { count: count, size: size }
        end

        def format_size(bytes)
          FileHelper.format_size(bytes)
        end

        def calculate_manifest_age(last_updated_str)
          last_updated = Time.parse(last_updated_str)
          Time.now - last_updated
        rescue ArgumentError
          nil
        end

        def format_manifest_age(age_seconds)
          return 'Unknown' if age_seconds.nil?

          days = age_seconds / 86_400
          if days < 1
            hours = age_seconds / 3600
            "#{hours.round}h ago"
          else
            "#{days.round}d ago"
          end
        end

        def manifest_age_indicator(age_seconds)
          return '' if age_seconds.nil?

          days = age_seconds / 86_400
          if days < 3
            '✓ Fresh'
          elsif days < 7
            'ℹ️ Aging'
          else
            '⚠️ Stale'
          end
        end

        def show_brand_suggestions(manifest)
          suggestions = []

          # Check manifest age
          if manifest[:config] && manifest[:config][:last_updated]
            age = calculate_manifest_age(manifest[:config][:last_updated])
            days = age / 86_400 if age
            suggestions << "dam manifest #{brand}  # Manifest is stale (#{days.round}d old)" if days && days > 7
          end

          # Check git status if repo exists
          if git_repo?
            status = git_status_info
            if status[:modified_count].positive? || status[:untracked_count].positive?
              suggestions << "git add . && git commit -m 'Update'  # Uncommitted changes (#{status[:modified_count]} modified, #{status[:untracked_count]} untracked)"
            end
            if status[:ahead].positive?
              suggestions << "git push  # Push #{status[:ahead]} commit#{'s' if status[:ahead] != 1} to remote"
            end
            if status[:behind].positive?
              suggestions << "git pull  # Pull #{status[:behind]} commit#{'s' if status[:behind] != 1} from remote"
            end
          end

          # Check for projects not backed up to SSD (task #43)
          ssd_configured = brand_info.locations.ssd_backup &&
                           brand_info.locations.ssd_backup != 'NOT-SET'
          if ssd_configured
            projects_without_ssd = manifest[:projects].select do |p|
              p[:storage][:local][:exists] && !p[:storage][:ssd][:exists]
            end
            if projects_without_ssd.any?
              count = projects_without_ssd.size
              suggestions << "dam archive #{brand} <project>  # #{count} project#{'s' if count != 1} not backed up to SSD"
            end
          end

          # Show suggestions if any
          return unless suggestions.any?

          puts '💡 Suggestions:'
          suggestions.each { |s| puts "   #{s}" }
        end

        # Check if S3 is configured for this brand
        def s3_configured?
          s3_bucket = brand_info.aws.s3_bucket
          s3_bucket && !s3_bucket.empty? && s3_bucket != 'NOT-SET'
        end

        # Show last S3 sync time for the brand
        def show_last_s3_sync_time
          # Find most recent S3 file across all projects with s3-staging
          projects = ProjectResolver.list_projects(brand)
          latest_sync = nil

          projects.each do |project|
            project_path = Config.project_path(brand, project)
            staging_dir = File.join(project_path, 's3-staging')
            next unless Dir.exist?(staging_dir)

            # Get most recent file modification time in s3-staging
            files = Dir.glob(File.join(staging_dir, '*')).select { |f| File.file?(f) }
            next if files.empty?

            project_latest = files.map { |f| File.mtime(f) }.max
            latest_sync = project_latest if latest_sync.nil? || project_latest > latest_sync
          end

          return unless latest_sync

          age = FileHelper.format_age(latest_sync)
          puts "   Last S3 sync: #{age} ago"
        end
      end
    end
  end
end
