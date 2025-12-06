# frozen_string_literal: true

require 'find'

module Appydave
  module Tools
    module Dam
      # File utility methods for DAM operations
      # Provides reusable file and directory helpers
      module FileHelper
        module_function

        # Calculate total size of directory in bytes
        # @param path [String] Directory path
        # @return [Integer] Size in bytes
        def calculate_directory_size(path)
          return 0 unless Dir.exist?(path)

          total = 0
          Find.find(path) do |file_path|
            total += File.size(file_path) if File.file?(file_path)
          rescue StandardError
            # Skip files we can't read
          end
          total
        end

        # Format bytes into human-readable size
        # @param bytes [Integer] Size in bytes
        # @return [String] Formatted size (e.g., "1.5 GB")
        def format_size(bytes)
          return '0 B' if bytes.zero?

          units = %w[B KB MB GB TB]
          exp = (Math.log(bytes) / Math.log(1024)).to_i
          exp = [exp, units.length - 1].min

          format('%<size>.1f %<unit>s', size: bytes.to_f / (1024**exp), unit: units[exp])
        end

        # Format time as relative age (e.g., "3d", "2w", "1mo")
        # @param time [Time, nil] Time to format
        # @return [String] Relative age string
        def format_age(time)
          return 'N/A' if time.nil?

          seconds = Time.now - time
          return 'just now' if seconds < 60

          minutes = seconds / 60
          return "#{minutes.round}m" if minutes < 60

          hours = minutes / 60
          return "#{hours.round}h" if hours < 24

          days = hours / 24
          return "#{days.round}d" if days < 7

          weeks = days / 7
          return "#{weeks.round}w" if weeks < 4

          months = days / 30
          return "#{months.round}mo" if months < 12

          years = days / 365
          "#{years.round}y"
        end
      end
    end
  end
end
