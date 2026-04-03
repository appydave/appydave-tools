require 'json'

module Appydave::Tools
  class BrainFinder
    def initialize(options)
      @options = options
      @index = nil
      @alias_map = nil
    end

    def find
      return [] unless @options.brain_query?

      load_index!
      paths = []

      # Handle brain name queries
      @options.brain_names.each do |name|
        paths.concat(find_by_name(name))
      end

      # Handle tag queries
      @options.tags.each do |tag|
        paths.concat(find_by_tag(tag))
      end

      # Handle category queries
      @options.categories.each do |category|
        paths.concat(find_by_category(category))
      end

      # Handle activity level filters
      if @options.activity_levels.any?
        paths.select! { |p| matches_activity_level?(p) }
      end

      # Remove duplicates and return
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
      @index['categories'].each do |_category, category_data|
        category_data['brains'].each do |brain_name, brain_data|
          matches << brain_data if brain_name.downcase.include?(name.downcase)
        end
      end
      return brain_entries_to_paths(matches) if matches.length == 1
      return brain_entries_to_paths(matches) if matches.any?

      # Not found
      []
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
      @index['categories'].each do |_category, category_data|
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

    def matches_activity_level?(file_path)
      # Extract brain name from path
      brain_name = file_path.match(%r{#{Regexp.escape(@options.brains_root)}/([^/]+)})&.[](1)
      return false unless brain_name

      # Find the brain entry
      entry = find_brain_in_index(brain_name)
      return false unless entry

      # Check if activity level matches filter
      @options.activity_levels.include?(entry['activity_level'])
    end
  end
end
