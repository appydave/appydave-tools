# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Sync (git pull) brand repositories
      class RepoSync
        attr_reader :brand, :brand_info, :brand_path

        def initialize(brand = nil)
          return unless brand

          @brand_info = load_brand_info(brand)
          @brand = @brand_info.key
          @brand_path = Config.brand_path(@brand)
        end

        # Sync single brand
        def sync
          puts "🔄 Syncing: v-#{brand}"
          puts ''

          unless git_repo?
            puts "❌ Not a git repository: #{brand_path}"
            return
          end

          perform_sync
        end

        # Sync all brands
        def sync_all
          puts '🔄 Syncing All Brands'
          puts ''

          Appydave::Tools::Configuration::Config.configure
          brands_config = Appydave::Tools::Configuration::Config.brands

          results = []

          brands_config.brands.each do |brand_info|
            @brand_info = brand_info
            @brand = brand_info.key
            @brand_path = Config.brand_path(@brand)

            next unless git_repo?

            puts "📦 v-#{brand}"
            result = perform_sync(indent: '  ')
            results << result
            puts ''
          end

          show_summary(results)
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

        def perform_sync(indent: '')
          # Check for uncommitted changes
          if uncommitted_changes?
            puts "#{indent}⚠️  Uncommitted changes detected"
            puts "#{indent}   Skipping pull (would cause conflicts)"
            return { brand: brand, status: 'skipped', reason: 'uncommitted changes' }
          end

          # Perform git pull
          output = `git -C "#{brand_path}" pull 2>&1`
          exit_code = $CHILD_STATUS.exitstatus

          if exit_code.zero?
            if output.include?('Already up to date')
              puts "#{indent}✓ Already up to date"
              { brand: brand, status: 'current' }
            else
              puts "#{indent}✓ Updated successfully"
              puts "#{indent}  #{output.lines.first.strip}" if output.lines.any?
              { brand: brand, status: 'updated' }
            end
          else
            puts "#{indent}❌ Pull failed: #{output.strip}"
            { brand: brand, status: 'error', reason: output.strip }
          end
        end

        def uncommitted_changes?
          output = `git -C "#{brand_path}" status --porcelain 2>/dev/null`.strip
          !output.empty?
        rescue StandardError
          false
        end

        def show_summary(results)
          puts '=' * 60
          puts '📊 Sync Summary:'
          puts ''

          updated = results.count { |r| r[:status] == 'updated' }
          current = results.count { |r| r[:status] == 'current' }
          skipped = results.count { |r| r[:status] == 'skipped' }
          errors = results.count { |r| r[:status] == 'error' }

          puts "  Total repos checked: #{results.size}"
          puts "  Updated: #{updated}"
          puts "  Already current: #{current}"
          puts "  Skipped: #{skipped}" if skipped.positive?
          puts "  Errors: #{errors}" if errors.positive?
        end
      end
    end
  end
end
