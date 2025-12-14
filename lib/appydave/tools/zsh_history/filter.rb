# frozen_string_literal: true

module Appydave
  module Tools
    module ZshHistory
      # Applies include/exclude patterns to categorize commands
      class Filter
        # Default patterns used when no config file exists
        DEFAULT_EXCLUDE_PATTERNS = [
          '^[a-z]$',           # Single letter commands (typos)
          '^[a-z]{2}$',        # Two letter commands (typos)
          '^ls$',
          '^ls -',
          '^pwd$',
          '^clear$',
          '^exit$',
          '^x$',
          '^cd$',
          '^cd -$',
          '^cd \\.\\.$',
          '^\\.\\.$',
          '^git status$',
          '^git diff$',
          '^git log$',
          '^git pull$',
          '^gs$',
          '^gd$',
          '^gl$',
          '^h$',
          '^history',
          '^which ',
          '^type ',
          '^cat ',
          '^head ',
          '^tail ',
          '^echo \\$',
          '^\\[\\d+\\]',              # Output like [1234]
          '^davidcruwys\\s+\\d+',     # Process listing output
          '^zsh: command not found',
          '^X Process completed',
          '^Coverage report',
          '^Line Coverage:',
          '^Finished in \\d',
          '^\\d+ examples, \\d+ failures'
        ].freeze

        DEFAULT_INCLUDE_PATTERNS = [
          '^j[a-z]',          # Jump aliases
          '^dam ',            # DAM tool
          '^vat ',            # VAT tool
          '^claude ',         # Claude CLI
          '^c-sonnet',        # Claude sonnet alias
          '^bun run ',
          '^bun dev$',
          '^bun web:',
          '^bun worker:',
          '^bun convex:',
          '^npm run ',
          '^rake ',
          '^bundle ',
          '^git commit',
          '^git push',
          '^git add',
          '^gac ',            # Git add & commit alias
          '^kfeat ',          # Semantic commit alias
          '^kfix ',           # Semantic commit alias
          '^docker ',
          '^docker-compose ',
          '^brew install',
          '^gem install',
          '^npm install'
        ].freeze

        attr_reader :exclude_patterns, :include_patterns, :profile_name

        # Initialize filter with patterns
        #
        # @param profile [String, nil] Profile name to load from config
        # @param exclude_patterns [Array<String>, nil] Override exclude patterns
        # @param include_patterns [Array<String>, nil] Override include patterns
        # @param config [Config, nil] Config instance (for testing)
        def initialize(profile: nil, exclude_patterns: nil, include_patterns: nil, config: nil)
          @profile_name = profile
          @config = config

          # Load patterns: explicit params > config > defaults
          exclude_list = exclude_patterns || load_exclude_patterns
          include_list = include_patterns || load_include_patterns

          @exclude_patterns = exclude_list.map { |p| Regexp.new(p, Regexp::IGNORECASE) }
          @include_patterns = include_list.map { |p| Regexp.new(p, Regexp::IGNORECASE) }
        end

        def apply(commands, days: nil)
          filtered = filter_by_date(commands, days)
          categorize(filtered)
        end

        def filter_by_date(commands, days)
          return commands if days.nil?

          cutoff = Time.now - (days * 24 * 60 * 60)
          commands.select { |cmd| cmd.datetime >= cutoff }
        end

        def categorize(commands)
          wanted = []
          unwanted = []
          unsure = []

          commands.each do |cmd|
            category, pattern = categorize_command(cmd)
            cmd.category = category
            cmd.matched_pattern = pattern

            case category
            when :wanted
              wanted << cmd
            when :unwanted
              unwanted << cmd
            else
              unsure << cmd
            end
          end

          FilterResult.new(
            wanted: wanted,
            unwanted: unwanted,
            unsure: unsure,
            stats: build_stats(wanted, unwanted, unsure, commands)
          )
        end

        private

        def config
          @config ||= Config.new(profile: profile_name)
        end

        def load_exclude_patterns
          # Try loading from config, fall back to defaults
          config_patterns = config.exclude_patterns
          config_patterns || DEFAULT_EXCLUDE_PATTERNS
        end

        def load_include_patterns
          # Try loading from config, fall back to defaults
          config_patterns = config.include_patterns
          config_patterns || DEFAULT_INCLUDE_PATTERNS
        end

        def categorize_command(cmd)
          text = cmd.text

          # Check exclude patterns first (noise removal)
          exclude_patterns.each do |pattern|
            return [:unwanted, pattern.source] if text.match?(pattern)
          end

          # Check include patterns
          include_patterns.each do |pattern|
            return [:wanted, pattern.source] if text.match?(pattern)
          end

          # Neither matched - unsure
          [:unsure, nil]
        end

        def build_stats(wanted, unwanted, unsure, all_commands)
          total = all_commands.size
          {
            total: total,
            wanted: wanted.size,
            unwanted: unwanted.size,
            unsure: unsure.size,
            wanted_pct: total.positive? ? (wanted.size.to_f / total * 100).round(1) : 0,
            unwanted_pct: total.positive? ? (unwanted.size.to_f / total * 100).round(1) : 0,
            unsure_pct: total.positive? ? (unsure.size.to_f / total * 100).round(1) : 0
          }
        end
      end
    end
  end
end
