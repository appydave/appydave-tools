module Appydave::Tools
  class ContentBuilder
    def initialize(file_paths, options)
      @file_paths = file_paths
      @options = options
    end

    def build
      content_parts = []

      @file_paths.each do |file_path|
        next unless File.exist?(file_path)

        # Read file content
        file_content = File.read(file_path, encoding: 'utf-8')

        # Apply line limit if set
        file_content = apply_line_limit(file_content) if @options.line_limit

        # Add file header
        relative_path = make_relative_path(file_path)
        content_parts << "# file: #{relative_path}\n#{file_content}"
      end

      # Join all parts with double newline separator
      content_parts.join("\n\n")
    end

    def token_estimate
      content = build
      # Rough estimate: 4 characters per token
      (content.length / 4.0).ceil
    end

    private

    def apply_line_limit(content)
      lines = content.split("\n")
      return content if lines.length <= @options.line_limit

      truncated = lines[0..(@options.line_limit - 1)].join("\n")
      truncated + "\n... (truncated after #{@options.line_limit} lines)"
    end

    def make_relative_path(file_path)
      # Try to make relative to home or brains root
      home = File.expand_path('~')
      brains_root = File.expand_path('~/dev/ad/brains')
      omi_root = File.expand_path('~/dev/raw-intake/omi')

      case file_path
      when /^#{Regexp.escape(brains_root)}/
        file_path.sub(brains_root + '/', '')
      when /^#{Regexp.escape(omi_root)}/
        file_path.sub(omi_root + '/', '')
      when /^#{Regexp.escape(home)}/
        file_path.sub(home + '/', '~/')
      else
        file_path
      end
    end
  end
end
