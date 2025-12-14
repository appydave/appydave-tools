# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Add command creates a new location entry
        class Add < Base
          attr_reader :attrs

          def initialize(config, attrs, path_validator: PathValidator.new, **options)
            super(config, path_validator: path_validator, **options)
            @attrs = attrs
          end

          def run
            # Validate required fields
            return error_result('Key is required', code: 'INVALID_INPUT') if attrs[:key].nil? || attrs[:key].empty?
            return error_result('Path is required', code: 'INVALID_INPUT') if attrs[:path].nil? || attrs[:path].empty?

            # Check for duplicate
            return error_result("Location '#{attrs[:key]}' already exists", code: 'DUPLICATE_KEY') if config.key_exists?(attrs[:key])

            # Validate path exists (optional warning)
            unless path_validator.exists?(attrs[:path])
              # Just warn, don't fail - path might be created later
              @path_warning = "Warning: Path '#{attrs[:path]}' does not exist"
            end

            # Create and validate location
            location = Location.new(attrs)
            errors = location.validate
            return error_result("Invalid location: #{errors.join(', ')}", code: 'INVALID_INPUT') unless errors.empty?

            # Add to config
            config.add(location)
            config.save

            result = success_result(
              message: "Location '#{attrs[:key]}' added successfully",
              location: location.to_h
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
