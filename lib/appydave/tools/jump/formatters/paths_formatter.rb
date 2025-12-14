# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Formatters
        # Paths formatter outputs one path per line for scripting
        class PathsFormatter < Base
          # Format data as one path per line
          #
          # @return [String] Newline-separated paths
          def format
            return '' unless success?

            results.map { |r| r[:path] }.compact.join("\n")
          end
        end
      end
    end
  end
end
