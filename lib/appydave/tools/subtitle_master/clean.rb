# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleMaster
      # Clean and normalize subtitles
      class Clean
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

        def clean
          content = remove_underscores(@content)
          normalize_lines(content)
        end

        def write(output_file)
          File.write(output_file, content)
          puts "Processed file written to #{output_file}"
        rescue Errno::EACCES
          puts "Permission denied: Unable to write to #{output_file}"
        rescue StandardError => e
          puts "An error occurred while writing to the file: #{e.message}"
        end

        private

        def remove_underscores(content)
          content.gsub(%r{</?u>}, '')
        end

        def normalize_lines(content)
          lines = content.split("\n")
          grouped_subtitles = []
          current_subtitle = { text: '', start_time: nil, end_time: nil }

          lines.each do |line|
            if line =~ /^\d+$/ || line.strip.empty?
              next
            elsif line =~ /^\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$/
              if current_subtitle[:start_time]
                grouped_subtitles << current_subtitle.clone
                current_subtitle = { text: '', start_time: nil, end_time: nil }
              end

              times = line.split(' --> ')
              current_subtitle[:start_time] = times[0]
              current_subtitle[:end_time] = times[1]
            else
              current_subtitle[:text] += ' ' unless current_subtitle[:text].empty?
              current_subtitle[:text] += line.strip
            end
          end

          grouped_subtitles << current_subtitle unless current_subtitle[:text].empty?

          grouped_subtitles = merge_subtitles(grouped_subtitles)

          build_normalized_content(grouped_subtitles)
        end

        def merge_subtitles(subtitles)
          merged_subtitles = []
          subtitles.each do |subtitle|
            if merged_subtitles.empty? || merged_subtitles.last[:text] != subtitle[:text]
              merged_subtitles << subtitle
            else
              merged_subtitles.last[:end_time] = subtitle[:end_time]
            end
          end
          merged_subtitles
        end

        def build_normalized_content(grouped_subtitles)
          normalized_content = []
          grouped_subtitles.each_with_index do |subtitle, index|
            normalized_content << (index + 1).to_s
            normalized_content << "#{subtitle[:start_time]} --> #{subtitle[:end_time]}"
            normalized_content << subtitle[:text]
            normalized_content << ''
          end

          normalized_content.join("\n")
        end
      end
    end
  end
end
