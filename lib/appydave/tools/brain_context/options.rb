require 'ostruct'

module Appydave::Tools
  class BrainContextOptions
    attr_accessor :brain_names, :tags, :categories, :activity_levels, :status,
                  :omi, :omi_signals, :omi_routings, :omi_activities,
                  :date_from, :date_to, :enriched_only,
                  :include_index, :output_targets, :formats, :line_limit,
                  :debug_level, :dry_run, :tokens, :base_dir, :omi_dir

    def initialize
      @brain_names = []
      @tags = []
      @categories = []
      @activity_levels = []
      @status = 'active'  # default: exclude deprecated

      @omi = false
      @omi_signals = []
      @omi_routings = []
      @omi_activities = []
      @date_from = nil
      @date_to = nil
      @enriched_only = false

      @include_index = true
      @output_targets = ['clipboard']  # default to clipboard
      @formats = ['content']
      @line_limit = nil
      @debug_level = 'none'
      @dry_run = false
      @tokens = false
      @base_dir = Dir.pwd

      @omi_dir = File.expand_path('~/dev/raw-intake/omi')
    end

    def brains_root
      @brains_root ||= File.expand_path('~/dev/ad/brains')
    end

    def brains_index_path
      File.join(brains_root, 'audit', 'brains-index.json')
    end

    def brain_query?
      brain_names.any? || tags.any? || categories.any? || activity_levels.any?
    end

    def omi_query?
      omi
    end
  end
end
