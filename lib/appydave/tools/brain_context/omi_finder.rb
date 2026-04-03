require 'date'

module Appydave::Tools
  class OmiQuery
    def initialize(options)
      @options = options
    end

    def find
      return [] unless @options.omi_query?

      paths = []

      Dir.glob(File.join(@options.omi_dir, '*.md')).each do |file_path|
        next unless include_file?(file_path)

        paths << file_path
      end

      paths.sort
    end

    private

    def include_file?(file_path)
      frontmatter = extract_frontmatter(file_path)
      return false unless frontmatter

      # If enriched-only requested, skip raw files
      if @options.enriched_only
        return false unless frontmatter['signal'] && frontmatter['extraction_summary']
      end

      # Apply filters
      return false unless signal_matches?(frontmatter)
      return false unless routing_matches?(frontmatter)
      return false unless activity_matches?(frontmatter)
      return false unless date_matches?(frontmatter)
      return false unless brain_matches?(frontmatter)

      true
    end

    def extract_frontmatter(file_path)
      content = File.read(file_path, encoding: 'utf-8')
      lines = content.split("\n")

      return nil unless lines[0] == '---'

      frontmatter = {}
      i = 1
      while i < lines.length
        line = lines[i]
        break if line == '---'

        # Parse YAML-like: key: value
        if line.match?(/^[a-z_]+:/)
          key, value = parse_yaml_line(line)
          frontmatter[key] = value
        end

        i += 1
      end

      frontmatter.empty? ? nil : frontmatter
    end

    def parse_yaml_line(line)
      # Handle simple cases: key: value, key: [a, b, c]
      match = line.match(/^([a-z_]+):\s*(.*)$/)
      return [nil, nil] unless match

      key = match[1]
      value_str = match[2].strip

      # Parse array [a, b, c]
      if value_str.start_with?('[') && value_str.end_with?(']')
        array_content = value_str[1..-2]
        value = array_content.split(',').map { |v| v.strip.gsub(/^["']|["']$/, '') }
      # Parse quoted string
      elsif (value_str.start_with?('"') && value_str.end_with?('"')) ||
            (value_str.start_with?("'") && value_str.end_with?("'"))
        value = value_str[1..-2]
      # Parse date (YYYY-MM-DD)
      elsif value_str.match?(/^\d{4}-\d{2}-\d{2}$/)
        value = value_str
      # Parse other values as-is
      else
        value = value_str
      end

      [key, value]
    end

    def signal_matches?(frontmatter)
      return true if @options.omi_signals.empty?

      signal = frontmatter['signal']
      return false unless signal

      @options.omi_signals.include?(signal)
    end

    def routing_matches?(frontmatter)
      return true if @options.omi_routings.empty?

      routing = frontmatter['routing']
      return false unless routing

      # routing can be pipe-delimited
      routings = routing.split('|').map(&:strip)
      routings.any? { |r| @options.omi_routings.include?(r) }
    end

    def activity_matches?(frontmatter)
      return true if @options.omi_activities.empty?

      activity = frontmatter['activity']
      return false unless activity

      # activity can be pipe-delimited
      activities = activity.split('|').map(&:strip)
      activities.any? { |a| @options.omi_activities.include?(a) }
    end

    def date_matches?(frontmatter)
      extracted_at = frontmatter['extracted_at']
      return true if extracted_at.nil?  # No date field = include

      begin
        date = Date.parse(extracted_at)
      rescue StandardError
        return true  # Can't parse = include
      end

      from_ok = @options.date_from.nil? || date >= Date.parse(@options.date_from)
      to_ok = @options.date_to.nil? || date <= Date.parse(@options.date_to)

      from_ok && to_ok
    end

    def brain_matches?(frontmatter)
      return true if @options.brain_names.empty?

      matched_brains = frontmatter['matched_brains']
      return false unless matched_brains

      # matched_brains is an array
      matched_brains_list = matched_brains.is_a?(Array) ? matched_brains : [matched_brains]
      matched_brains_list.any? { |brain| @options.brain_names.include?(brain) }
    end
  end
end
