# frozen_string_literal: true

module Appydave
  module Tools
    module ZshHistory
      # Loads zsh_history configuration from ~/.config/appydave/zsh_history/
      #
      # Directory structure:
      #   ~/.config/appydave/zsh_history/
      #     config.txt                    # default_profile=crash-recovery
      #     base_exclude.txt              # Always excluded (typos, output lines)
      #     profiles/
      #       crash-recovery/
      #         exclude.txt               # Profile-specific excludes
      #         include.txt               # Profile-specific includes
      #
      # Pattern files: One regex pattern per line, # for comments, blank lines ignored
      #
      class Config
        DEFAULT_CONFIG_PATH = File.expand_path('~/.config/appydave/zsh_history')

        attr_reader :config_path, :profile_name

        def initialize(config_path: nil, profile: nil)
          @config_path = config_path || DEFAULT_CONFIG_PATH
          @profile_name = profile || default_profile
        end

        # Returns merged exclude patterns (base + profile)
        def exclude_patterns
          patterns = load_base_exclude
          patterns += load_profile_patterns('exclude') if profile_name
          patterns.empty? ? nil : patterns
        end

        # Returns profile include patterns
        def include_patterns
          patterns = load_profile_patterns('include')
          patterns.empty? ? nil : patterns
        end

        # Check if config directory exists
        def configured?
          Dir.exist?(config_path)
        end

        # Check if specific profile exists
        def profile_exists?(name = profile_name)
          return false unless name

          profile_path = File.join(config_path, 'profiles', name)
          Dir.exist?(profile_path)
        end

        # List available profiles
        def available_profiles
          profiles_dir = File.join(config_path, 'profiles')
          return [] unless Dir.exist?(profiles_dir)

          Dir.children(profiles_dir)
             .select { |f| File.directory?(File.join(profiles_dir, f)) }
             .sort
        end

        # Get default profile from config.txt
        def default_profile
          config_file = File.join(config_path, 'config.txt')
          return nil unless File.exist?(config_file)

          File.readlines(config_file).each do |line|
            line = line.strip
            next if line.empty? || line.start_with?('#')

            key, value = line.split('=', 2)
            return value.strip if key.strip == 'default_profile'
          end

          nil
        end

        # Create default config structure with example files
        def self.create_default_config(config_path = DEFAULT_CONFIG_PATH)
          FileUtils.mkdir_p(config_path)
          FileUtils.mkdir_p(File.join(config_path, 'profiles', 'crash-recovery'))

          # Create config.txt
          write_if_missing(File.join(config_path, 'config.txt'), <<~CONFIG)
            # ZSH History Configuration
            # Set default profile (used when --profile not specified)
            default_profile=crash-recovery
          CONFIG

          # Create base_exclude.txt
          write_if_missing(File.join(config_path, 'base_exclude.txt'), <<~PATTERNS)
            # Base exclude patterns - always applied
            # These are noise in ANY scenario

            # Typos and single-letter commands
            ^[a-z]$
            ^[a-z]{2}$

            # Output lines accidentally captured
            ^\\[\\d+\\]
            ^zsh: command not found
            ^X Process completed
            ^Coverage report
            ^Line Coverage:
            ^Finished in \\d
            ^\\d+ examples, \\d+ failures

            # Process listing output
            ^davidcruwys\\s+\\d+
          PATTERNS

          # Create crash-recovery profile
          profile_path = File.join(config_path, 'profiles', 'crash-recovery')

          write_if_missing(File.join(profile_path, 'exclude.txt'), <<~PATTERNS)
            # Crash Recovery - Exclude patterns
            # Navigation and quick-check commands (noise when finding what you were working on)

            # Basic navigation
            ^ls$
            ^ls -
            ^pwd$
            ^clear$
            ^exit$
            ^x$
            ^cd$
            ^cd -$
            ^cd \\.\\.
            ^\\.\\.

            # Git quick checks (not actual work)
            ^git status$
            ^git diff$
            ^git log$
            ^git pull$
            ^gs$
            ^gd$
            ^gl$

            # History and lookups
            ^h$
            ^history
            ^which
            ^type

            # File viewing
            ^cat
            ^head
            ^tail
            ^echo \\$
          PATTERNS

          write_if_missing(File.join(profile_path, 'include.txt'), <<~PATTERNS)
            # Crash Recovery - Include patterns
            # Commands that represent actual work

            # Jump aliases (navigation to projects)
            ^j[a-z]

            # Tools
            ^dam
            ^vat
            ^claude
            ^c-sonnet

            # JavaScript/Node
            ^bun run
            ^bun dev$
            ^bun web:
            ^bun worker:
            ^bun convex:
            ^npm run

            # Ruby
            ^rake
            ^bundle

            # Git commits (actual work, not checks)
            ^git commit
            ^git push
            ^git add
            ^gac
            ^kfeat
            ^kfix

            # Docker
            ^docker
            ^docker-compose

            # Package installation
            ^brew install
            ^gem install
            ^npm install
          PATTERNS

          config_path
        end

        class << self
          private

          def write_if_missing(path, content)
            return if File.exist?(path)

            File.write(path, content)
          end
        end

        private

        def load_base_exclude
          load_patterns_file(File.join(config_path, 'base_exclude.txt'))
        end

        def load_profile_patterns(type)
          return [] unless profile_name

          file_path = File.join(config_path, 'profiles', profile_name, "#{type}.txt")
          load_patterns_file(file_path)
        end

        def load_patterns_file(file_path)
          return [] unless File.exist?(file_path)

          File.readlines(file_path)
              .map(&:strip)
              .reject { |line| line.empty? || line.start_with?('#') }
        end
      end
    end
  end
end
