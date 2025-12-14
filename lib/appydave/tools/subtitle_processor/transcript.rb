# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleProcessor
      # Convert SRT to plain text transcript
      # Strips timestamps and indices, keeping only the spoken text
      class Transcript
        attr_reader :content

        def initialize(file_path: nil, srt_content: nil)
          if file_path && srt_content
            raise ArgumentError, 'You cannot provide both a file path and an SRT content stream.'
          elsif file_path.nil? && srt_content.nil?
            raise ArgumentError, 'You must provide either a file path or an SRT content stream.'
          end

          @content = if file_path
                       File.read(file_path, encoding: 'UTF-8')
                     else
                       srt_content
                     end
        end

        # Convert SRT to plain text transcript
        # @param paragraph_gap [Integer] Number of newlines between subtitle blocks (default: 1 = single newline)
        # @return [String] Plain text transcript
        def extract(paragraph_gap: 1)
          parser = Join::SRTParser.new
          subtitles = parser.parse(@content)

          separator = "\n" * paragraph_gap
          subtitles.map(&:text).join(separator)
        end

        # Write transcript to file
        # @param output_file [String] Path to output file
        # @param paragraph_gap [Integer] Number of newlines between subtitle blocks
        def write(output_file, paragraph_gap: 1)
          transcript = extract(paragraph_gap: paragraph_gap)
          File.write(output_file, transcript, encoding: 'UTF-8')
          puts "Transcript written to #{output_file}"
        rescue Errno::EACCES
          puts "Permission denied: Unable to write to #{output_file}"
        rescue StandardError => e
          puts "An error occurred while writing to the file: #{e.message}"
        end
      end
    end
  end
end
