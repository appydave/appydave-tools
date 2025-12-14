# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Remove command deletes a location entry
        class Remove < Base
          attr_reader :key, :force

          def initialize(config, key, force: false, path_validator: PathValidator.new, **options)
            super(config, path_validator: path_validator, **options)
            @key = key
            @force = force
          end

          def run
            # Validate key exists
            location = config.find(key)
            unless location
              suggestions = find_suggestions(key)
              suggestion = suggestions.empty? ? nil : "Did you mean: #{suggestions.join(', ')}?"
              return error_result("Location '#{key}' not found", code: 'NOT_FOUND', suggestion: suggestion)
            end

            # Require --force
            unless force
              return error_result(
                "Use --force to confirm removal of '#{key}'",
                code: 'CONFIRMATION_REQUIRED'
              )
            end

            # Remove
            config.remove(key)
            config.save

            success_result(
              message: "Location '#{key}' removed successfully",
              removed: location.to_h
            )
          rescue ArgumentError => e
            error_result(e.message, code: 'NOT_FOUND')
          end

          private

          def find_suggestions(query)
            config.locations
                  .map(&:key)
                  .select { |k| k.include?(query) || query.include?(k) || k.start_with?(query[0..1]) }
                  .first(3)
          end
        end
      end
    end
  end
end
