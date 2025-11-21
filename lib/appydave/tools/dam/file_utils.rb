# frozen_string_literal: true

require 'find'

module Appydave
  module Tools
    module Dam
      # File utility methods for DAM operations
      # Provides reusable file and directory helpers
      module FileUtils
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

          format('%.1f %s', bytes.to_f / (1024**exp), units[exp])
        end
      end
    end
  end
end
