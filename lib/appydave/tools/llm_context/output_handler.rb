# frozen_string_literal: true

module Appydave
  module Tools
    module LlmContext
      # OutputHandler is responsible for writing the output to the desired target
      class OutputHandler
        def initialize(content, options)
          @content = content
          @output_targets = options.output_target
          @working_directory = options.working_directory
        end

        def execute
          @output_targets.each do |target|
            case target
            when 'clipboard'
              Clipboard.copy(@content)
            when 'temp'
              write_to_temp
            when /^.+$/
              write_to_file(target)
            end
          end
        end

        private

        attr_reader :content, :output_targets, :working_directory

        def write_to_file(target)
          resolved_path = Pathname.new(target).absolute? ? target : File.join(working_directory, target)
          File.write(resolved_path, content)
        end

        def write_to_temp
          # Create in system temp directory with descriptive name
          tmp_dir = Dir.tmpdir
          timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%N')[0..18] # millisecond precision
          file_path = File.join(tmp_dir, "llm_context-#{timestamp}.txt")

          # Write content to file
          File.write(file_path, @content)

          # Copy path to clipboard
          Clipboard.copy(file_path)
          warn "Context saved to: #{file_path}"
        end
      end
    end
  end
end
