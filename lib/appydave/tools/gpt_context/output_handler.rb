# frozen_string_literal: true

module Appydave
  module Tools
    module GptContext
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
      end
    end
  end
end
