# frozen_string_literal: true

module Appydave
  module Tools
    module RandomContext
      # Represents one entry in the random-queries.yml config file
      class QueryEntry
        attr_reader :label, :command, :min_results, :max_results

        def initialize(data)
          @label = data['label']
          @command = data['command']
          @min_results = data.fetch('min_results', 1)
          @max_results = data.fetch('max_results', 15)
        end

        def good_count?(count)
          count.between?(min_results, max_results)
        end
      end
    end
  end
end
