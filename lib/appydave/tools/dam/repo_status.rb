# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Show git status for brand repositories
      class RepoStatus
        attr_reader :brand, :brand_info, :brand_path

        def initialize(brand = nil)
          return unless brand

          @brand_info = load_brand_info(brand)
          @brand = @brand_info.key
          @brand_path = Config.brand_path(@brand)
        end

        # Show status for single brand
        def show
          puts "🔍 Git Status: v-#{brand}"
          puts ''

          unless git_repo?
            puts "❌ Not a git repository: #{brand_path}"
            return
          end

          show_git_info
        end

        # Show status for all brands
        def show_all
          puts '🔍 Git Status - All Brands'
          puts ''

          Appydave::Tools::Configuration::Config.configure
          brands_config = Appydave::Tools::Configuration::Config.brands

          brands_config.brands.each do |brand_info|
            @brand_info = brand_info
            @brand = brand_info.key
            @brand_path = Config.brand_path(@brand)

            next unless git_repo?

            puts "📦 v-#{brand}"
            show_git_info(indent: '  ')
            puts ''
          end
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        def git_repo?
          git_dir = File.join(brand_path, '.git')
          Dir.exist?(git_dir)
        end

        def show_git_info(indent: '')
          status = git_status_info

          puts "#{indent}🌿 Branch: #{status[:branch]}"
          puts "#{indent}📡 Remote: #{status[:remote]}" if status[:remote]

          if status[:modified_count].positive? || status[:untracked_count].positive?
            puts "#{indent}↕️  Changes: #{status[:modified_count]} modified, #{status[:untracked_count]} untracked"
          else
            puts "#{indent}✓ Working directory clean"
          end

          if status[:ahead].positive? || status[:behind].positive?
            puts "#{indent}🔄 Sync: #{sync_status_text(status[:ahead], status[:behind])}"
          else
            puts "#{indent}✓ Up to date with remote"
          end
        end

        def sync_status_text(ahead, behind)
          parts = []
          parts << "#{ahead} ahead" if ahead.positive?
          parts << "#{behind} behind" if behind.positive?
          parts.join(', ')
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
          `git -C "#{brand_path}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
        rescue StandardError
          'unknown'
        end

        def remote_url
          result = `git -C "#{brand_path}" remote get-url origin 2>/dev/null`.strip
          result.empty? ? nil : result
        rescue StandardError
          nil
        end

        def modified_files_count
          `git -C "#{brand_path}" status --porcelain 2>/dev/null | grep -E "^.M|^M" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        def untracked_files_count
          `git -C "#{brand_path}" status --porcelain 2>/dev/null | grep -E "^\\?\\?" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        def commits_ahead
          `git -C "#{brand_path}" rev-list --count @{upstream}..HEAD 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        def commits_behind
          `git -C "#{brand_path}" rev-list --count HEAD..@{upstream} 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end
      end
    end
  end
end
