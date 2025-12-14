# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Formatters
        # JSON formatter for programmatic access and Claude skill integration
        class JsonFormatter < Base
          # Format data as JSON
          #
          # @return [String] JSON string
          def format
            JSON.pretty_generate(data)
          end
        end
      end
    end
  end
end
