# frozen_string_literal: true

module Appydave
  module Tools
    module ZshHistory
      # Parses ZSH history file, handling multi-line commands with \ continuations
      class Parser
        # ZSH history line format: : timestamp:duration;command
        HISTORY_LINE_PATTERN = /^: (\d+):\d+;(.*)$/.freeze

        attr_reader :file_path, :commands

        def initialize(file_path = nil)
          @file_path = file_path || default_history_path
          @commands = []
        end

        def parse
          return [] unless File.exist?(file_path)

          lines = read_file
          @commands = parse_lines(lines)
        end

        private

        def default_history_path
          File.expand_path('~/.zsh_history')
        end

        def read_file
          # ZSH history files often contain binary/non-UTF-8 data
          # Read as binary first, then force UTF-8 with invalid byte replacement
          content = File.binread(file_path)
          content.force_encoding('UTF-8')
          content.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
          content.split("\n")
        rescue Errno::ENOENT
          []
        rescue StandardError => e
          warn "Warning: Error reading history file: #{e.message}"
          []
        end

        def parse_lines(lines)
          commands = []
          current_command = nil

          lines.each do |line|
            if (match = line.match(HISTORY_LINE_PATTERN))
              commands << current_command if current_command
              current_command = process_history_line(match, line, commands)
            elsif current_command
              current_command = process_continuation_line(current_command, line, commands)
            end
          end

          commands << current_command if current_command
          commands
        end

        def process_history_line(match, line, commands)
          timestamp = match[1].to_i
          command_text = match[2]

          if command_text.end_with?('\\')
            build_command(timestamp: timestamp, text: command_text.chomp('\\'), is_multiline: true, raw_lines: [line])
          else
            commands << build_command(timestamp: timestamp, text: command_text, is_multiline: false, raw_lines: [line])
            nil
          end
        end

        def process_continuation_line(current_command, line, commands)
          current_command.raw_lines << line

          if line.end_with?('\\')
            current_command.text += "\n#{line.chomp('\\')}"
            current_command
          else
            current_command.text += "\n#{line}"
            commands << current_command
            nil
          end
        end

        def build_command(timestamp:, text:, is_multiline:, raw_lines:)
          Command.new(
            timestamp: timestamp,
            datetime: Time.at(timestamp),
            text: text.strip,
            is_multiline: is_multiline,
            category: nil,
            raw_lines: raw_lines,
            matched_pattern: nil
          )
        end
      end
    end
  end
end
