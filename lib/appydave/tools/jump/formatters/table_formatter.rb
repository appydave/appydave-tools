# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      module Formatters
        # Table formatter for human-readable terminal output with colors
        class TableFormatter < Base
          # ANSI color codes
          COLORS = {
            reset: "\e[0m",
            bold: "\e[1m",
            dim: "\e[2m",
            red: "\e[31m",
            green: "\e[32m",
            yellow: "\e[33m",
            blue: "\e[34m",
            magenta: "\e[35m",
            cyan: "\e[36m",
            white: "\e[37m"
          }.freeze

          # Format data as a colored table
          #
          # @return [String] Formatted table
          def format
            return format_error unless success?
            return format_info if info_result?
            return format_empty if results.empty?

            format_results
          end

          private

          def format_error
            lines = []
            lines << colorize("Error: #{error_message}", :red)
            lines << colorize(suggestion, :yellow) if suggestion
            lines.join("\n")
          end

          def format_empty
            colorize('No locations found.', :yellow)
          end

          def info_result?
            data.key?(:config_path)
          end

          def format_info
            [
              format_info_header,
              format_info_details,
              format_info_statistics
            ].join("\n")
          end

          def format_info_header
            [
              colorize('Jump Location Tool - Configuration Info', :bold),
              ''
            ]
          end

          def format_info_details
            exists_value = data[:exists] ? colorize('Yes', :green) : colorize('No', :red)
            [
              "#{colorize('Config Path:', :cyan)}  #{data[:config_path]}",
              "#{colorize('Config Exists:', :cyan)} #{exists_value}",
              "#{colorize('Version:', :cyan)}       #{data[:version] || 'N/A'}",
              "#{colorize('Last Updated:', :cyan)}  #{data[:last_updated] || 'Never'}",
              "#{colorize('Last Validated:', :cyan)} #{data[:last_validated] || 'Never'}",
              ''
            ]
          end

          def format_info_statistics
            [
              colorize('Statistics:', :bold),
              "  Locations: #{data[:location_count] || 0}",
              "  Brands:    #{data[:brand_count] || 0}",
              "  Clients:   #{data[:client_count] || 0}"
            ]
          end

          def format_results
            lines = []

            # Header
            lines << format_header
            lines << header_separator

            # Results
            results.each do |result|
              lines << format_row(result)
            end

            # Footer
            lines << ''
            lines << colorize("Total: #{count} location(s)", :dim)

            lines.join("\n")
          end

          def format_header
            cols = [
              pad('#', 3),
              pad('KEY', key_width),
              pad('JUMP', jump_width),
              pad('TYPE', 10),
              pad('BRAND/CLIENT', 15),
              'DESCRIPTION'
            ]
            colorize(cols.join('  '), :bold)
          end

          def header_separator
            '-' * terminal_width
          end

          # rubocop:disable Metrics/AbcSize
          def format_row(result)
            index = result[:index].to_s.rjust(3)
            key = pad(result[:key] || '', key_width)
            jump = pad(result[:jump] || '', jump_width)
            type = pad(result[:type] || '', 10)
            owner = pad(result[:brand] || result[:client] || '', 15)
            desc = truncate(result[:description] || '', description_width)

            # Color the score indicator
            score_indicator = if result[:score]&.positive?
                                colorize("[#{result[:score]}]", :cyan)
                              else
                                ''
                              end

            "#{colorize(index, :dim)}  #{colorize(key, :green)}  #{colorize(jump, :blue)}  " \
              "#{type}  #{colorize(owner, :magenta)}  #{desc} #{score_indicator}"
          end
          # rubocop:enable Metrics/AbcSize

          def key_width
            @key_width ||= [results.map { |r| (r[:key] || '').length }.max || 10, 20].min
          end

          def jump_width
            @jump_width ||= [results.map { |r| (r[:jump] || '').length }.max || 10, 15].min
          end

          def description_width
            @description_width ||= [terminal_width - 60, 30].max
          end

          def terminal_width
            @terminal_width ||= begin
              width = ENV.fetch('COLUMNS', nil)&.to_i
              width = `tput cols 2>/dev/null`.to_i if width.nil? || width.zero?
              width = 120 if width.zero?
              width
            end
          end

          def pad(str, width)
            str.to_s.ljust(width)[0...width]
          end

          def truncate(str, width)
            return str if str.length <= width

            "#{str[0...(width - 3)]}..."
          end

          def colorize(text, color)
            return text unless options[:color] != false && $stdout.tty?

            "#{COLORS[color]}#{text}#{COLORS[:reset]}"
          end
        end
      end
    end
  end
end
