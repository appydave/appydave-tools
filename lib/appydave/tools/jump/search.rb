# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      # Search provides fuzzy search across location metadata
      #
      # Scoring algorithm based on match type:
      # - Exact key match: 100 points
      # - Key contains term: 50 points
      # - Brand/client alias match: 40 points
      # - Tag match: 30 points
      # - Type match: 20 points
      # - Description contains: 10 points
      # - Path contains: 5 points
      #
      # @example Basic search
      #   search = Search.new(config)
      #   results = search.search('appydave ruby')
      #   results[:success]  # => true
      #   results[:results]  # => Array of scored location hashes
      class Search
        SCORE_EXACT_KEY = 100
        SCORE_KEY_CONTAINS = 50
        SCORE_BRAND_CLIENT_ALIAS = 40
        SCORE_TAG_MATCH = 30
        SCORE_TYPE_MATCH = 20
        SCORE_DESCRIPTION_CONTAINS = 10
        SCORE_PATH_CONTAINS = 5

        attr_reader :config

        def initialize(config)
          @config = config
        end

        # Search for locations matching query terms
        #
        # @param query [String] Space-separated search terms
        # @return [Hash] Search results with success, count, and results
        def search(query)
          terms = parse_query(query)

          return empty_result if terms.empty?

          scored_locations = config.locations.map do |location|
            score = calculate_score(location, terms)
            next if score.zero?

            location_to_result(location, score)
          end.compact

          # Sort by score descending, then by key alphabetically
          sorted = scored_locations.sort_by { |r| [-r[:score], r[:key]] }

          # Add index numbers
          sorted.each_with_index { |result, i| result[:index] = i + 1 }

          {
            success: true,
            count: sorted.size,
            results: sorted
          }
        end

        # Get a location by exact key
        #
        # @param key [String] Exact key to find
        # @return [Hash] Result with success and results array (consistent with search/list)
        def get(key)
          location = config.find(key)

          if location
            result = location_to_result(location, SCORE_EXACT_KEY)
            result[:index] = 1
            {
              success: true,
              count: 1,
              results: [result]
            }
          else
            suggestions = find_suggestions(key)
            {
              success: false,
              error: 'Location not found',
              code: 'NOT_FOUND',
              suggestion: suggestions.empty? ? nil : "Did you mean: #{suggestions.join(', ')}?"
            }
          end
        end

        # List all locations
        #
        # @return [Hash] All locations with success and count
        def list
          results = config.locations.map.with_index(1) do |location, index|
            result = location_to_result(location, 0)
            result[:index] = index
            result
          end

          {
            success: true,
            count: results.size,
            results: results
          }
        end

        private

        def parse_query(query)
          return [] if query.nil? || query.strip.empty?

          query.downcase.split(/\s+/).reject(&:empty?)
        end

        def empty_result
          {
            success: true,
            count: 0,
            results: []
          }
        end

        def calculate_score(location, terms)
          total_score = 0

          terms.each do |term|
            total_score += score_for_term(location, term)
          end

          total_score
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def score_for_term(location, term)
          score = 0

          # Exact key match
          if location.key == term
            score += SCORE_EXACT_KEY
          elsif location.key&.include?(term)
            score += SCORE_KEY_CONTAINS
          end

          # Brand/client alias match
          score += SCORE_BRAND_CLIENT_ALIAS if brand_alias_match?(location.brand, term)
          score += SCORE_BRAND_CLIENT_ALIAS if client_alias_match?(location.client, term)

          # Tag match
          score += SCORE_TAG_MATCH if location.tags.any? { |tag| tag.downcase == term }

          # Type match
          score += SCORE_TYPE_MATCH if location.type&.downcase == term

          # Description contains
          score += SCORE_DESCRIPTION_CONTAINS if location.description&.downcase&.include?(term)

          # Path contains
          score += SCORE_PATH_CONTAINS if location.path&.downcase&.include?(term)

          score
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def brand_alias_match?(brand_key, term)
          return false unless brand_key

          return true if brand_key.downcase == term

          brand_info = config.brands[brand_key]
          return false unless brand_info

          aliases = brand_info['aliases'] || brand_info[:aliases] || []
          aliases.any? { |a| a.downcase == term }
        end

        def client_alias_match?(client_key, term)
          return false unless client_key

          return true if client_key.downcase == term

          client_info = config.clients[client_key]
          return false unless client_info

          aliases = client_info['aliases'] || client_info[:aliases] || []
          aliases.any? { |a| a.downcase == term }
        end

        def location_to_result(location, score)
          {
            key: location.key,
            path: expand_path(location.path),
            jump: location.jump,
            brand: location.brand,
            client: location.client,
            type: location.type,
            tags: location.tags,
            description: location.description,
            score: score
          }.compact
        end

        def expand_path(path)
          return path unless path

          File.expand_path(path)
        end

        def find_suggestions(key)
          return [] unless key

          # Find keys that are similar (contain or start with same letters)
          config.locations
                .map(&:key)
                .select { |k| similar?(k, key) }
                .first(3)
        end

        def similar?(candidate, query)
          # Simple similarity: shares first 2 chars or contains query
          return true if candidate.start_with?(query[0..1])
          return true if candidate.include?(query)
          return true if query.include?(candidate)

          # Levenshtein-like: at least 50% chars in common
          common = (candidate.chars & query.chars).size
          common >= [candidate.length, query.length].min * 0.5
        end
      end
    end
  end
end
