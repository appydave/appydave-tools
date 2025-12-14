# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Update command modifies an existing location entry
        class Update < Base
          attr_reader :key, :attrs

          def initialize(config, key, attrs, path_validator: PathValidator.new, **options)
            super(config, path_validator: path_validator, **options)
            @key = key
            @attrs = attrs
          end

          def run
            # Validate key exists
            return error_result("Location '#{key}' not found", code: 'NOT_FOUND') unless config.key_exists?(key)

            # Validate path if provided
            @path_warning = "Warning: Path '#{attrs[:path]}' does not exist" if attrs[:path] && !path_validator.exists?(attrs[:path])

            # Update
            config.update(key, attrs)
            config.save

            updated = config.find(key)
            result = success_result(
              message: "Location '#{key}' updated successfully",
              location: updated.to_h
            )
            result[:warning] = @path_warning if @path_warning
            result
          rescue ArgumentError => e
            error_result(e.message, code: 'INVALID_INPUT')
          end
        end
      end
    end
  end
end
