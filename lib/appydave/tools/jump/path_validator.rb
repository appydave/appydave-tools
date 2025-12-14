# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      # PathValidator checks if filesystem paths exist
      #
      # This class is designed for dependency injection in tests.
      # Production code uses the real filesystem, while tests inject
      # a mock that returns predetermined results.
      #
      # @example Production usage
      #   validator = PathValidator.new
      #   validator.exists?('~/dev/project')  # => true/false based on real filesystem
      #
      # @example Test usage (see spec/support/jump_test_helpers.rb)
      #   validator = TestPathValidator.new(valid_paths: ['~/dev/project'])
      #   validator.exists?('~/dev/project')  # => true
      #   validator.exists?('~/dev/other')    # => false
      class PathValidator
        # Check if a path exists as a directory
        #
        # @param path [String] Path to check (supports ~ expansion)
        # @return [Boolean] true if directory exists
        def exists?(path)
          File.directory?(expand(path))
        end

        # Check if a path exists as a file
        #
        # @param path [String] Path to check (supports ~ expansion)
        # @return [Boolean] true if file exists
        def file_exists?(path)
          File.exist?(expand(path))
        end

        # Expand a path (resolve ~ and relative paths)
        #
        # @param path [String] Path to expand
        # @return [String] Absolute path
        def expand(path)
          File.expand_path(path)
        end
      end
    end
  end
end
