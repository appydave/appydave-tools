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
          # Fetch latest from remote to ensure accurate status
          fetch_from_remote

          status = git_status_info

          puts "#{indent}🌿 Branch: #{status[:branch]}"
          puts "#{indent}📡 Remote: #{status[:remote]}" if status[:remote]

          # Priority logic: Show EITHER changes with file list OR sync status
          # Check if repo has uncommitted changes (matches old script: git diff-index --quiet HEAD --)
          if uncommitted_changes?
            puts "#{indent}⚠️  Has uncommitted changes:"
            show_file_list(indent: indent)
          elsif status[:ahead].positive? || status[:behind].positive?
            puts "#{indent}🔄 Sync: #{sync_status_text(status[:ahead], status[:behind])}"
          else
            puts "#{indent}✓ Clean - up to date with remote"
          end
        end

        def sync_status_text(ahead, behind)
          parts = []
          if ahead.positive?
            commit_word = ahead == 1 ? 'commit' : 'commits'
            parts << "#{ahead} #{commit_word} to push"
          end
          if behind.positive?
            commit_word = behind == 1 ? 'commit' : 'commits'
            parts << "#{behind} #{commit_word} to pull"
          end
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

        # Check if repo has uncommitted changes (matches old script: git diff-index --quiet HEAD --)
        def uncommitted_changes?
          # git diff-index returns 0 if clean, 1 if there are changes
          system("git -C \"#{brand_path}\" diff-index --quiet HEAD -- 2>/dev/null")
          !$CHILD_STATUS.success?
        rescue StandardError
          false
        end

        # Show file list using git status --short (matches old script)
        def show_file_list(indent: '')
          output = `git -C "#{brand_path}" status --short 2>/dev/null`.strip
          return if output.empty?

          # Add indentation to each line (matches old script: sed 's/^/      /')
          file_indent = "#{indent}     "
          output.lines.each do |line|
            puts "#{file_indent}#{line.strip}"
          end
        rescue StandardError
          # Silently fail if git status fails
        end

        # Fetch latest changes from remote to ensure accurate sync status
        def fetch_from_remote
          `git -C "#{brand_path}" fetch origin 2>/dev/null`
        rescue StandardError
          # Silently fail if fetch fails (e.g., no network, no remote)
        end
      end
    end
  end
end
