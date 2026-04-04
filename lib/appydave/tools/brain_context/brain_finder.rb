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

      def find_meta
        return [] unless @options.brain_query?

        load_index!
        entries = []

        entries.concat(active_meta_entries) if @options.active
        @options.brain_names.each { |name| entries.concat(meta_entries_by_name(name)) }
        @options.categories.each { |cat| entries.concat(meta_entries_by_category(cat)) }

        entries.uniq { |e| e['name'] }.sort_by { |e| e['name'] }
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

      # --- find_meta helpers ---

      def active_meta_entries
        result = []
        @index['categories'].each do |category_name, category_data|
          category_data['brains'].each do |brain_name, brain_data|
            result << build_meta_entry(brain_name, category_name, brain_data) if brain_data['activity_level'] == 'high'
          end
        end
        result
      end

      def meta_entries_by_category(category)
        category_key = @index['categories'].keys.find { |k| k.casecmp(category).zero? }
        return [] unless category_key

        @index['categories'][category_key]['brains'].map do |brain_name, brain_data|
          build_meta_entry(brain_name, category_key, brain_data)
        end
      end

      def meta_entries_by_name(name)
        # Exact match
        brain_name, category, data = find_brain_with_context(name)
        return [build_meta_entry(brain_name, category, data)] if data

        # Alias match
        if @alias_map&.[](name.downcase)
          brain_name, category, data = find_brain_with_context(@alias_map[name.downcase])
          return [build_meta_entry(brain_name, category, data)] if data
        end

        # Substring match
        matches = []
        @index['categories'].each do |category_name, category_data|
          category_data['brains'].each do |bname, bdata|
            matches << build_meta_entry(bname, category_name, bdata) if bname.downcase.include?(name.downcase)
          end
        end
        return matches if matches.any?

        # Tag match
        tag = name.downcase.gsub('_', '-')
        (@index['tag_index']&.[](tag) || []).filter_map do |bname|
          brain_name, category, data = find_brain_with_context(bname)
          build_meta_entry(brain_name, category, data) if data
        end
      end

      def find_brain_with_context(brain_name)
        @index['categories'].each do |category_name, category_data|
          data = category_data['brains'][brain_name]
          return [brain_name, category_name, data] if data
        end
        [nil, nil, nil]
      end

      def build_meta_entry(name, category, data)
        {
          'name' => name,
          'category' => category,
          'activity_level' => data['activity_level'],
          'status' => data['status'],
          'tags' => data['tags'] || [],
          'file_count' => data['file_count'] || 0
        }
      end
    end
  end
end
