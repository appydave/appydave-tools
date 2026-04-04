# frozen_string_literal: true

require 'date'

module Appydave
  module Tools
    # Queries OMI transcript directory by enriched frontmatter
    class OmiQuery
      def initialize(options)
        @options = options
      end

      def find
        return [] unless @options.omi_query?

        resolve_days!
        paths = each_matching.map { |file_path, _frontmatter| file_path }
        paths = paths.last(@options.limit) if @options.limit
        paths
      end

      def find_meta
        return [] unless @options.omi_query?

        resolve_days!
        entries = each_matching.map do |file_path, frontmatter|
          build_omi_meta(file_path, frontmatter)
        end
        entries = entries.last(@options.limit) if @options.limit
        entries
      end

      private

      def each_matching
        results = []
        Dir.glob(File.join(@options.omi_dir, '*.md')).sort.each do |file_path|
          frontmatter = extract_frontmatter(file_path)
          next unless frontmatter
          next unless passes_filters?(frontmatter)

          results << [file_path, frontmatter]
        end
        results
      end

      def passes_filters?(frontmatter)
        return false if @options.enriched_only && (!frontmatter['signal'] || !frontmatter['extraction_summary'])
        return false unless routing_matches?(frontmatter)
        return false unless activity_matches?(frontmatter)
        return false unless date_matches?(frontmatter)
        return false unless brain_matches?(frontmatter)

        true
      end

      def build_omi_meta(file_path, frontmatter)
        {
          'file'               => File.basename(file_path),
          'extracted_at'       => frontmatter['extracted_at'],
          'extraction_summary' => frontmatter['extraction_summary'],
          'matched_brains'     => frontmatter['matched_brains'] || [],
          'activity'           => frontmatter['activity'],
          'routing'            => frontmatter['routing'],
          'entities_tools'     => frontmatter['entities_tools'] || [],
          'entities_projects'  => frontmatter['entities_projects'] || [],
          'entities_concepts'  => frontmatter['entities_concepts'] || []
        }
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
        # Parse date (YYYY-MM-DD) or other values as-is
        else
          value = value_str
        end

        [key, value]
      end

      def resolve_days!
        return unless @options.days

        @options.date_from = (Date.today - @options.days).to_s
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
        return true if extracted_at.nil? # No date field = include

        begin
          date = Date.parse(extracted_at)
        rescue StandardError
          return true # Can't parse = include
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
end
