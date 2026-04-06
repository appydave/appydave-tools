# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Installs bundled example configuration files into the user's config directory.
      #
      # Example files live at config/examples/*.example.json inside the gem.
      # Each file is installed without the `.example` segment in its name so that
      # `settings.example.json` becomes `settings.json` in the target directory.
      #
      # Files are never overwritten — existing files are skipped and reported.
      #
      # @example Install all examples
      #   result = ExampleInstaller.new.install
      #   result[:installed] #=> ["settings.json", "locations.json"]
      #   result[:skipped]   #=> []
      class ExampleInstaller
        EXAMPLES_PATH = File.expand_path('../../../../config/examples', __dir__)

        # @param target_path [String, nil] Directory to install into.
        #   Defaults to the active Config.config_path (~/.config/appydave).
        def initialize(target_path: nil)
          @target_path = target_path || Config.config_path
        end

        # Install all bundled example files that do not yet exist.
        #
        # @return [Hash] with keys :installed (Array<String>) and :skipped (Array<String>)
        def install
          FileUtils.mkdir_p(@target_path)
          results = { installed: [], skipped: [] }

          example_files.each do |src|
            dest = destination_for(src)
            basename = File.basename(dest)

            if File.exist?(dest)
              results[:skipped] << basename
            else
              FileUtils.cp(src, dest)
              results[:installed] << basename
            end
          end

          results
        end

        # List the filenames that would be installed (target names, not source names).
        #
        # @return [Array<String>]
        def available
          example_files.map { |f| target_name(f) }
        end

        private

        def example_files
          Dir.glob(File.join(EXAMPLES_PATH, '*.example.*')).sort
        end

        def destination_for(src)
          File.join(@target_path, target_name(src))
        end

        def target_name(src)
          File.basename(src).sub('.example', '')
        end
      end
    end
  end
end
