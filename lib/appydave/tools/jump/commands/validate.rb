# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Validate command checks if location paths exist
        class Validate < Base
          attr_reader :key

          def initialize(config, key: nil, path_validator: PathValidator.new, **options)
            super(config, path_validator: path_validator, **options)
            @key = key
          end

          def run
            locations_to_validate = if key
                                      location = config.find(key)
                                      return error_result("Location '#{key}' not found", code: 'NOT_FOUND') unless location

                                      [location]
                                    else
                                      config.locations
                                    end

            results = locations_to_validate.map do |loc|
              {
                key: loc.key,
                path: loc.path,
                expanded_path: path_validator.expand(loc.path),
                valid: path_validator.exists?(loc.path),
                jump: loc.jump
              }
            end

            valid_count = results.count { |r| r[:valid] }
            invalid_count = results.count { |r| !r[:valid] }

            # Update validation timestamp
            config.touch_validated
            config.save

            success_result(
              count: results.size,
              valid_count: valid_count,
              invalid_count: invalid_count,
              results: results
            )
          end
        end
      end
    end
  end
end
