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
            return format_summary if summary_result?
            return format_groups unless groups.empty?
            return format_empty if results.empty?
            return format_definition_report if definition_report?
            return format_count_report if count_report?
            return format_category_report if category_report?

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
            message = case data[:report]
                      when 'brands'
                        'No brands defined in config.'
                      when 'clients'
                        'No clients defined in config.'
                      else
                        'No locations found.'
                      end

            colorize(message, :yellow)
          end

          def info_result?
            data.key?(:config_path)
          end

          def summary_result?
            data.key?(:total_locations) && data.key?(:by_type)
          end

          def count_report?
            return false if results.empty?

            first = results.first
            first.key?(:location_count) && (first.key?(:tag) || first.key?(:type))
          end

          def definition_report?
            return false if results.empty?

            first = results.first
            first.key?(:key) && first.key?(:description) && first.key?(:aliases) && first.key?(:location_count)
          end

          def category_report?
            return false if results.empty?

            first = results.first
            first.key?(:name) && first.key?(:description) && first.key?(:values)
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

          def format_summary
            lines = []
            lines << colorize('Jump Locations Summary', :bold)
            lines << ''
            lines << "#{colorize('Total Locations:', :cyan)} #{data[:total_locations]}"
            lines << ''

            # By Type
            lines << colorize('By Type:', :bold)
            data[:by_type].sort_by { |_, count| -count }.each do |type, count|
              lines << "  #{pad(type, 15)} #{colorize(count.to_s.rjust(3), :green)}"
            end
            lines << ''

            # By Brand
            lines << colorize('By Brand:', :bold)
            data[:by_brand].sort_by { |_, count| -count }.each do |brand, count|
              lines << "  #{pad(brand, 15)} #{colorize(count.to_s.rjust(3), :green)}"
            end
            lines << ''

            # By Client
            lines << colorize('By Client:', :bold)
            data[:by_client].sort_by { |_, count| -count }.each do |client, count|
              lines << "  #{pad(client, 15)} #{colorize(count.to_s.rjust(3), :green)}"
            end

            lines.join("\n")
          end

          def format_definition_report
            lines = []
            report_type = data[:report] || 'items'

            lines << colorize("#{report_type.capitalize} Definitions", :bold)
            lines << header_separator
            lines << ''

            results.each do |item|
              lines << colorize(item[:key], :cyan)
              lines << "  #{item[:description]}" if item[:description]
              lines << "  Aliases: #{item[:aliases].join(', ')}" if item[:aliases]&.any?
              lines << "  Locations: #{colorize(item[:location_count].to_s, :green)}"
              lines << ''
            end

            lines << colorize("Total: #{count} #{report_type}", :dim)

            lines.join("\n")
          end

          def format_count_report
            lines = []
            report_type = data[:report] || 'items'

            lines << colorize("#{report_type.capitalize} Report", :bold)
            lines << header_separator
            lines << ''

            results.each do |item|
              name = item[:tag] || item[:type] || 'unknown'
              count = item[:location_count] || 0
              lines << "#{pad(name, 20)} #{colorize(count.to_s.rjust(4), :green)}"
            end

            lines << ''

            # Show truncation message if data was limited
            if data[:truncated]
              total = data[:total_count] || data[:count]
              shown = results.size
              remaining = total - shown
              lines << colorize("Showing top #{shown} of #{total} (#{remaining} more)", :dim)
            else
              lines << colorize("Total: #{data[:total_count] || count} #{report_type}", :dim)
            end

            lines.join("\n")
          end

          def format_category_report
            lines = []

            lines << colorize('Location Categories', :bold)
            lines << header_separator
            lines << ''

            results.each do |category|
              lines << colorize(category[:name], :cyan)
              lines << "  #{category[:description]}" if category[:description]
              lines << "  Values: #{category[:values].join(', ')}" if category[:values]
              lines << ''
            end

            lines.join("\n")
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

          def format_groups
            lines = []
            total_locations = 0
            total_groups = 0

            groups.each do |group_name, group_data|
              # Handle both old format (array) and new format (hash with items/total/truncated)
              locations, total_in_group, truncated = if group_data.is_a?(Hash) && group_data.key?(:items)
                                                       [group_data[:items], group_data[:total], group_data[:truncated]]
                                                     else
                                                       [group_data, group_data.length, false]
                                                     end

              next if locations.empty?

              # Group header
              lines << ''
              lines << colorize("#{group_name.upcase} (#{total_in_group} location#{'s' unless total_in_group == 1})", :bold)
              lines << header_separator

              # Add index to each location for display
              locations.each_with_index do |location, idx|
                location[:index] = idx + 1
                lines << format_row(location)
              end

              # Show truncation message if group was limited
              if truncated
                remaining = total_in_group - locations.length
                lines << colorize("  ... and #{remaining} more", :dim)
              end

              total_locations += total_in_group
              total_groups += 1
            end

            # Footer
            lines << ''
            footer = "Total: #{total_locations} location(s) in #{total_groups} group(s)"
            footer += ' (unassigned hidden)' if data[:skip_unassigned]
            lines << colorize(footer, :dim)

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
