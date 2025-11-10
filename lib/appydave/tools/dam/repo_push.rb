# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Push brand repository changes
      class RepoPush
        attr_reader :brand, :project_id, :brand_info, :brand_path

        def initialize(brand, project_id = nil)
          @brand_info = load_brand_info(brand)
          @brand = @brand_info.key
          @brand_path = Config.brand_path(@brand)
          @project_id = project_id
        end

        # Push changes
        def push
          puts "📤 Pushing: v-#{brand}"
          puts ''

          unless git_repo?
            puts "❌ Not a git repository: #{brand_path}"
            return
          end

          # If project specified, validate it exists in manifest
          if project_id
            validate_project
          end

          perform_push
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

        def validate_project
          manifest = load_manifest
          unless manifest
            puts "⚠️  Warning: Manifest not found"
            puts "   Continuing with push (manifest is optional for validation)"
            return
          end

          # Resolve short name if needed (b65 -> b65-full-name)
          resolved = ProjectResolver.new.resolve(brand, project_id)

          project_entry = manifest[:projects].find { |p| p[:id] == resolved }
          if project_entry
            puts "✓ Project validated: #{resolved}"
            puts ''
          else
            puts "⚠️  Warning: Project '#{resolved}' not found in manifest"
            puts "   Continuing with push (manifest may be outdated)"
            puts ''
          end
        end

        def load_manifest
          manifest_path = File.join(brand_path, 'projects.json')
          return nil unless File.exist?(manifest_path)

          JSON.parse(File.read(manifest_path), symbolize_names: true)
        rescue JSON::ParserError
          nil
        end

        def perform_push
          # Check for uncommitted changes
          if has_uncommitted_changes?
            puts "⚠️  Warning: Uncommitted changes detected"
            puts ''
          end

          # Check if ahead of remote
          ahead = commits_ahead
          if ahead.zero?
            puts "✓ Nothing to push (up to date with remote)"
            return
          end

          puts "📤 Pushing #{ahead} commit(s)..."
          puts ''

          # Perform git push
          output = `git -C "#{brand_path}" push 2>&1`
          exit_code = $CHILD_STATUS.exitstatus

          if exit_code.zero?
            puts "✓ Push successful"
            puts ''
            show_push_summary(output)
          else
            puts "❌ Push failed:"
            puts output
            exit 1
          end
        end

        def has_uncommitted_changes?
          output = `git -C "#{brand_path}" status --porcelain 2>/dev/null`.strip
          !output.empty?
        rescue StandardError
          false
        end

        def commits_ahead
          `git -C "#{brand_path}" rev-list --count @{upstream}..HEAD 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        def show_push_summary(output)
          # Extract useful info from git push output
          lines = output.lines.map(&:strip).reject(&:empty?)

          lines.each do |line|
            puts "  #{line}" if line.include?('->') || line.include?('branch')
          end
        end
      end
    end
  end
end
