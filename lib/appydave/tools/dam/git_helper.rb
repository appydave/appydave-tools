# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Git operations helper for DAM classes
      # Provides reusable git command wrappers
      module GitHelper
        module_function

        # Get current branch name
        # @param repo_path [String] Path to git repository
        # @return [String] Branch name or 'unknown' if error
        def current_branch(repo_path)
          result = `git -C "#{repo_path}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
          result.empty? ? 'unknown' : result
        rescue StandardError
          'unknown'
        end

        # Get git remote URL
        # @param repo_path [String] Path to git repository
        # @return [String, nil] Remote URL or nil if not configured
        def remote_url(repo_path)
          result = `git -C "#{repo_path}" remote get-url origin 2>/dev/null`.strip
          result.empty? ? nil : result
        rescue StandardError
          nil
        end

        # Count commits ahead of remote
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of commits ahead
        def commits_ahead(repo_path)
          `git -C "#{repo_path}" rev-list --count @{upstream}..HEAD 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        # Count commits behind remote
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of commits behind
        def commits_behind(repo_path)
          `git -C "#{repo_path}" rev-list --count HEAD..@{upstream} 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        # Count modified files
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of modified files
        def modified_files_count(repo_path)
          `git -C "#{repo_path}" status --porcelain 2>/dev/null | grep -E "^.M|^M" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        # Count untracked files
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of untracked files
        def untracked_files_count(repo_path)
          `git -C "#{repo_path}" status --porcelain 2>/dev/null | grep -E "^\\?\\?" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        # Check if repository has uncommitted changes
        # @param repo_path [String] Path to git repository
        # @return [Boolean] true if changes exist
        def uncommitted_changes?(repo_path)
          system("git -C \"#{repo_path}\" diff-index --quiet HEAD -- 2>/dev/null")
          !$CHILD_STATUS.success?
        rescue StandardError
          false
        end

        # Fetch from remote
        # @param repo_path [String] Path to git repository
        # @return [Boolean] true if successful
        def fetch(repo_path)
          system("git -C \"#{repo_path}\" fetch 2>/dev/null")
          $CHILD_STATUS.success?
        rescue StandardError
          false
        end
      end
    end
  end
end
