# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Fuzzy matching for brand names using Levenshtein distance
      class FuzzyMatcher
        class << self
          # Find closest matches to input string
          # @param input [String] Input string to match
          # @param candidates [Array<String>] List of valid options
          # @param threshold [Integer] Maximum distance to consider a match (default: 3)
          # @return [Array<String>] Sorted list of closest matches
          def find_matches(input, candidates, threshold: 3)
            return [] if input.nil? || input.empty? || candidates.empty?

            # Calculate distances and filter by threshold
            matches = candidates.map do |candidate|
              distance = levenshtein_distance(input.downcase, candidate.downcase)
              { candidate: candidate, distance: distance }
            end

            # Filter by threshold
            matches = matches.select { |m| m[:distance] <= threshold }

            # Sort by distance (closest first)
            matches.sort_by { |m| m[:distance] }.map { |m| m[:candidate] }
          end

          # Calculate Levenshtein distance between two strings
          # @param str1 [String] First string
          # @param str2 [String] Second string
          # @return [Integer] Edit distance
          def levenshtein_distance(str1, str2)
            return str2.length if str1.empty?
            return str1.length if str2.empty?

            # Create distance matrix
            matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

            # Initialize first row and column
            (0..str1.length).each { |i| matrix[i][0] = i }
            (0..str2.length).each { |j| matrix[0][j] = j }

            # Calculate distances
            (1..str1.length).each do |i|
              (1..str2.length).each do |j|
                cost = str1[i - 1] == str2[j - 1] ? 0 : 1
                matrix[i][j] = [
                  matrix[i - 1][j] + 1,      # deletion
                  matrix[i][j - 1] + 1,      # insertion
                  matrix[i - 1][j - 1] + cost # substitution
                ].min
              end
            end

            matrix[str1.length][str2.length]
          end
        end
      end
    end
  end
end
