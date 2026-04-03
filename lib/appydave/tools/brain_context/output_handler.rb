require 'clipboard'
require 'tempfile'

module Appydave::Tools
  class BrainContextOutputHandler
    def initialize(content, options)
      @content = content
      @output_targets = options.output_targets
      @working_directory = options.base_dir
    end

    def write
      @output_targets.each do |target|
        case target
        when 'clipboard'
          write_to_clipboard
        when 'temp'
          write_to_temp
        when 'stdout'
          write_to_stdout
        else
          write_to_file(target)
        end
      end
    end

    private

    def write_to_clipboard
      Clipboard.copy(@content)
    end

    def write_to_temp
      # Create temp file with timestamp
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%3N')
      filename = "brain_context-#{timestamp}.txt"
      temp_path = File.join(Dir.tmpdir, filename)

      File.write(temp_path, @content)
      # Copy the path to clipboard
      Clipboard.copy(temp_path)

      # Also print to stderr for visibility
      warn "Context saved to: #{temp_path}"
    end

    def write_to_stdout
      puts @content
    end

    def write_to_file(filename)
      # Resolve relative paths against working directory
      filepath = File.expand_path(filename, @working_directory)
      File.write(filepath, @content)
      warn "Context written to: #{filepath}"
    end
  end
end
