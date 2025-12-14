# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Commands
        # Base command class for Jump CLI commands
        class Base
          attr_reader :config, :path_validator, :options

          def initialize(config, path_validator: PathValidator.new, **options)
            @config = config
            @path_validator = path_validator
            @options = options
          end

          # Execute the command
          #
          # @return [Hash] Result hash with success status
          def run
            raise NotImplementedError, 'Subclasses must implement #run'
          end

          protected

          def success_result(data = {})
            { success: true }.merge(data)
          end

          def error_result(message, code: 'ERROR', suggestion: nil)
            result = {
              success: false,
              error: message,
              code: code
            }
            result[:suggestion] = suggestion if suggestion
            result
          end
        end
      end
    end
  end
end
