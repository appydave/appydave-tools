# frozen_string_literal: true

module Appydave
  module Tools
    module ZshHistory
      # Represents a single command from ZSH history
      Command = Struct.new(
        :timestamp,      # Integer - Unix timestamp from history
        :datetime,       # Time - Parsed datetime
        :text,           # String - Full command text (multi-line joined)
        :is_multiline,   # Boolean - Was this a continuation command?
        :category,       # Symbol - :wanted, :unwanted, :unsure
        :raw_lines,      # Array<String> - Original lines from file
        :matched_pattern, # String - Pattern that matched (for verbose output)
        keyword_init: true
      ) do
        def formatted_datetime(format = '%Y-%m-%d %H:%M:%S')
          datetime&.strftime(format) || 'unknown'
        end

        def to_history_format
          # Reconstruct in ZSH history format for writing back
          raw_lines.join("\n")
        end
      end

      # Result of filtering operations
      FilterResult = Struct.new(
        :wanted,    # Array<Command>
        :unwanted,  # Array<Command>
        :unsure,    # Array<Command>
        :stats,     # Hash - { total:, wanted:, unwanted:, unsure: }
        keyword_init: true
      )
    end
  end
end
