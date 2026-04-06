# frozen_string_literal: true

module Appydave
  module Tools
    # Options struct for brain/OMI query tools
    class BrainContextOptions
      attr_accessor :brain_names, :categories, :active, :meta,
                    :omi, :omi_routings, :omi_activities,
                    :date_from, :date_to, :enriched_only, :days, :limit,
                    :include_index, :output_targets, :formats, :line_limit,
                    :debug_level, :dry_run, :tokens, :base_dir, :omi_dir

      def initialize
        @brain_names = []
        @categories = []
        @active = false
        @meta = false

        @omi = false
        @omi_routings = []
        @omi_activities = []
        @date_from = nil
        @date_to = nil
        @enriched_only = true
        @days = nil
        @limit = nil

        @include_index = true
        @output_targets = ['clipboard'] # default to clipboard
        @formats = ['content']
        @line_limit = nil
        @debug_level = 'none'
        @dry_run = false
        @tokens = false
        @base_dir = Dir.pwd

        configured_omi = read_setting('omi-directory-path')
        @omi_dir = configured_omi || File.expand_path('~/dev/raw-intake/omi')
      end

      def brains_root
        @brains_root ||= begin
          configured = read_setting('brains-root-path')
          configured || File.expand_path('~/dev/ad/brains')
        end
      end

      def brains_index_path
        File.join(brains_root, 'audit', 'brains-index.json')
      end

      def brain_query?
        brain_names.any? || categories.any? || active
      end

      def omi_query?
        omi
      end

      private

      # Read a path value from settings config, expanding ~ if set.
      # Returns nil if config is unavailable or key is absent/blank.
      def read_setting(key)
        value = Appydave::Tools::Configuration::Config.settings.get(key)
        return nil if value.nil? || value.to_s.strip.empty?

        File.expand_path(value)
      rescue StandardError
        nil
      end
    end
  end
end
