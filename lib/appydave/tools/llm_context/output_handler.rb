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
          @smart = options.smart
          @smart_limit = options.smart_limit
        end

        def execute
          if @smart
            execute_smart
          else
            @output_targets.each { |target| route(target) }
          end
        end

        private

        attr_reader :content, :output_targets, :working_directory

        def execute_smart
          token_estimate = (@content.length / 4.0).ceil
          if token_estimate <= @smart_limit
            Clipboard.copy(@content)
            warn "→ clipboard (#{format_tokens(token_estimate)})"
          else
            file_path = write_to_temp_file
            Clipboard.copy(file_path)
            warn "→ temp file: #{file_path} (#{format_tokens(token_estimate)})"
            warn '  Path copied to clipboard.'
          end
        end

        def format_tokens(n)
          "#{(n / 1000.0).round.to_i}k tokens"
        end

        def route(target)
          case target
          when 'clipboard'
            Clipboard.copy(@content)
          when 'temp'
            write_to_temp
          when /^.+$/
            write_to_file(target)
          end
        end

        def write_to_file(target)
          resolved_path = Pathname.new(target).absolute? ? target : File.join(working_directory, target)
          File.write(resolved_path, content)
        end

        def write_to_temp
          file_path = write_to_temp_file
          Clipboard.copy(file_path)
          warn "Context saved to: #{file_path}"
        end

        def write_to_temp_file
          tmp_dir = Dir.tmpdir
          timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%N')[0..18] # millisecond precision
          file_path = File.join(tmp_dir, "llm_context-#{timestamp}.txt")
          File.write(file_path, @content)
          file_path
        end
      end
    end
  end
end
