# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Query command provides scriptable location lookup
        #
        # Designed for pipeline use — default output is bare paths, one per line.
        # Use --meta for structured JSON output.
        #
        # @example Find by term
        #   cmd = Commands::Query.new(config, find: ['flivideo'])
        #   result = cmd.run
        #   result[:results]  # => Array of matching location hashes
        #
        # @example Filter by type
        #   cmd = Commands::Query.new(config, type: 'product')
        #   result = cmd.run
        class Query < Base
          attr_reader :find_terms, :type_filter, :brand_filter

          def initialize(config, **options)
            super
            @find_terms  = Array(options[:find]).map { |t| t.to_s.downcase.strip }.reject(&:empty?)
            @type_filter = normalize_option(options[:type])
            @brand_filter = normalize_option(options[:brand])
          end

          def run
            matches = config.locations.select { |loc| matches?(loc) }

            if matches.empty?
              return error_result(
                'No locations found matching the given criteria',
                code: 'NOT_FOUND'
              )
            end

            results = matches.map.with_index(1) do |location, index|
              location_to_result(location, index)
            end

            success_result(
              count: results.size,
              results: results
            )
          end

          private

          def matches?(location)
            return false if type_filter && location.type&.downcase != type_filter
            return false if brand_filter && location.brand&.downcase != brand_filter
            return false unless find_terms_match?(location)

            true
          end

          def find_terms_match?(location)
            return true if find_terms.empty?

            # All find terms must match (AND logic) — each term matches if it appears
            # in any of the searchable fields of the location
            find_terms.all? { |term| term_matches_location?(term, location) }
          end

          def term_matches_location?(term, location)
            fields = [
              location.key,
              location.type,
              location.brand,
              location.client,
              location.description,
              location.path
            ].compact.map(&:downcase)

            tag_fields = location.tags.map(&:downcase)

            fields.any? { |f| f.include?(term) } || tag_fields.any? { |t| t.include?(term) }
          end

          def normalize_option(value)
            return nil unless value

            value.to_s.downcase.strip
          end

          def location_to_result(location, index)
            {
              index: index,
              key: location.key,
              path: expand_path(location.path),
              description: location.description,
              type: location.type,
              brand: location.brand,
              client: location.client,
              tags: location.tags,
              status: 'active'
            }.compact
          end

          def expand_path(path)
            return path unless path

            File.expand_path(path)
          end
        end
      end
    end
  end
end
