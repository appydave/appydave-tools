# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Formatters
        # Base formatter class providing common functionality
        class Base
          attr_reader :data, :options

          def initialize(data, options = {})
            @data = data
            @options = options
          end

          # Format the data
          #
          # @return [String] Formatted output
          def format
            raise NotImplementedError, 'Subclasses must implement #format'
          end

          protected

          def results
            data[:results] || []
          end

          def success?
            data[:success]
          end

          def error_message
            data[:error]
          end

          def suggestion
            data[:suggestion]
          end

          def count
            data[:count] || 0
          end
        end
      end
    end
  end
end
