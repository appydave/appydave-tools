# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleMaster
      class Clean
        def initialize(file_path)
          @file_path = file_path
        end

        def clean
          content = File.read(@file_path)
          content = remove_underscores(content)
          content = normalize_lines(content)
          content
        end

        private

        def remove_underscores(content)
          content.gsub(/<\/?u>/, '')
        end

        def normalize_lines(content)
          lines = content.split("\n")
          grouped_subtitles = []
          current_subtitle = { text: '', start_time: nil, end_time: nil }

          lines.each do |line|
            if line =~ /^\d+$/
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
              current_subtitle[:end_time] = current_subtitle[:end_time]
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
            normalized_content << ""
          end

          normalized_content.join("\n")
        end
      end
    end
  end
end
