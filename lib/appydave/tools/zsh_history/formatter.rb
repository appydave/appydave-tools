# frozen_string_literal: true

module Appydave
  module Tools
    module ZshHistory
      # Handles output formatting and file writing
      class Formatter
        DEFAULT_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
        MAX_COMMAND_LENGTH = 200

        attr_reader :datetime_format, :max_length

        def initialize(datetime_format: nil, max_length: nil)
          @datetime_format = datetime_format || DEFAULT_DATETIME_FORMAT
          @max_length = max_length || MAX_COMMAND_LENGTH
        end

        def format_commands(commands, verbose: false)
          commands.map { |cmd| format_command(cmd, verbose: verbose) }.join("\n")
        end

        def format_command(cmd, verbose: false)
          datetime_str = cmd.formatted_datetime(datetime_format)
          text = truncate(cmd.text)

          if verbose && cmd.matched_pattern
            category = cmd.category.to_s.upcase
            "#{datetime_str}  [#{category}: #{cmd.matched_pattern}]  #{text}"
          else
            "#{datetime_str}  #{text}"
          end
        end

        def format_stats(stats, date_range: nil)
          lines = []
          lines << 'ZSH History Statistics'
          lines << ('=' * 50)

          lines << format('Total commands:    %<total>d', stats)
          lines << format('Wanted:            %<wanted>d  (%<wanted_pct>.1f%%)', stats)
          lines << format('Unwanted:          %<unwanted>d  (%<unwanted_pct>.1f%%)', stats)
          lines << format('Unsure:            %<unsure>d  (%<unsure_pct>.1f%%)', stats)

          if date_range
            lines << ''
            lines << "Date range: #{date_range[:from]} to #{date_range[:to]} (#{date_range[:days]} days)"
          end

          lines.join("\n")
        end

        def write_history(commands, output_path, backup: true)
          if backup && File.exist?(output_path)
            backup_path = "#{output_path}.backup.#{Time.now.strftime('%Y%m%d-%H%M%S')}"
            FileUtils.cp(output_path, backup_path)
            puts "Backup created: #{backup_path}"
          end

          content = commands.map(&:to_history_format).join("\n")
          File.write(output_path, "#{content}\n")

          puts "Wrote #{commands.size} commands to #{output_path}"
        end

        private

        def truncate(text)
          return text if text.length <= max_length

          "#{text[0, max_length - 3]}..."
        end
      end
    end
  end
end
