# frozen_string_literal: true

require 'json'

module Appydave
  module Tools
    # Queries brains-index.json to find brain files
    class BrainQuery
      def initialize(options)
        @options = options
        @index = nil
        @alias_map = nil
      end

      def find
        return [] unless @options.brain_query?

        load_index!
        paths = []

        # Active brains: return all high-activity brains
        paths.concat(find_active) if @options.active

        # Handle brain name/tag/alias queries (unified)
        @options.brain_names.each do |name|
          paths.concat(find_by_name(name))
        end

        # Handle category queries
        @options.categories.each do |category|
          paths.concat(find_by_category(category))
        end

        paths.uniq.sort
      end

      private

      def load_index!
        return if @index

        index_path = @options.brains_index_path
        unless File.exist?(index_path)
          raise "brains-index.json not found at #{index_path}. Run: python ~/dev/ad/brains/.claude/skills/brain-librarian/scripts/build_brain_index.py build --all ~/dev/ad/brains"
        end

        @index = JSON.parse(File.read(index_path))
        build_alias_map!
      end

      def build_alias_map!
        @alias_map = {}
        @index['alias_index']&.each { |alias_name, brain_name| @alias_map[alias_name.downcase] = brain_name }
      end

      def find_by_name(name)
        load_index!

        # Step 1: Exact match on brain key
        brain_entry = find_brain_in_index(name)
        return brain_entries_to_paths([brain_entry]) if brain_entry

        # Step 2: Alias match
        if @alias_map && @alias_map[name.downcase]
          brain_name = @alias_map[name.downcase]
          brain_entry = find_brain_in_index(brain_name)
          return brain_entries_to_paths([brain_entry]) if brain_entry
        end

        # Step 3: Substring match on brain key (case-insensitive)
        matches = []
        @index['categories'].each_value do |category_data|
          category_data['brains'].each do |brain_name, brain_data|
            matches << brain_data if brain_name.downcase.include?(name.downcase)
          end
        end
        return brain_entries_to_paths(matches) if matches.any?

        # Step 4: Tag match (so --find works for tags too)
        find_by_tag(name)
      end

      def find_by_tag(tag)
        load_index!
        tag = tag.downcase.gsub('_', '-')

        brain_names = @index['tag_index']&.[](tag) || []
        brain_entries = []

        brain_names.each do |brain_name|
          entry = find_brain_in_index(brain_name)
          brain_entries << entry if entry
        end

        brain_entries_to_paths(brain_entries)
      end

      def find_by_category(category)
        load_index!
        category_data = @index['categories'][category] || @index['categories'][category.downcase]

        return [] unless category_data

        brain_entries = category_data['brains'].values
        brain_entries_to_paths(brain_entries)
      end

      def find_brain_in_index(brain_name)
        @index['categories'].each_value do |category_data|
          return category_data['brains'][brain_name] if category_data['brains'][brain_name]
        end
        nil
      end

      def brain_entries_to_paths(brain_entries)
        paths = []

        brain_entries.each do |entry|
          next unless entry

          # Add files from files[] array
          entry['files']&.each do |file|
            # File entry is relative to the brain directory
            brain_name = extract_brain_name(entry)
            full_path = File.join(@options.brains_root, brain_name, file)
            paths << full_path if File.exist?(full_path)
          end

          # Add INDEX.md if requested
          if @options.include_index
            index_path = File.join(@options.brains_root, entry['index_path'])
            paths << index_path if File.exist?(index_path)
          end
        end

        paths
      end

      def extract_brain_name(entry)
        # index_path is like "brain-name/INDEX.md"
        entry['index_path'].split('/')[0]
      end

      def find_active
        brain_entries = []
        @index['categories'].each_value do |category_data|
          category_data['brains'].each_value do |brain_data|
            brain_entries << brain_data if brain_data['activity_level'] == 'high'
          end
        end
        brain_entries_to_paths(brain_entries)
      end
    end
  end
end
