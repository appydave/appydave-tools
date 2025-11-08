# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleProcessor
      # Join multiple SRT files into one
      # - Supports folder, wildcards, sorting via FileResolver
      class Join
        # Handles file resolution (folder, wildcards, sorting)
        class FileResolver
          def initialize(folder:, files:, sort:)
            raise ArgumentError, 'folder is required' if folder.nil?
            raise ArgumentError, 'files is required' if files.nil?

            @folder = folder
            @files = files
            @sort = sort
          end

          def process
            # Check if folder exists before processing
            raise Errno::ENOENT, "No such directory - #{@folder}" unless Dir.exist?(@folder)

            file_patterns = @files.split(',').map(&:strip)
            resolved_files = file_patterns.flat_map { |pattern| resolve_pattern(pattern) }
            sort_files(resolved_files)
          end

          private

          def resolve_pattern(pattern)
            if pattern.include?('*')
              Dir.glob(File.join(@folder, pattern))
            else
              file_path = File.join(@folder, pattern)
              File.exist?(file_path) ? [file_path] : []
            end
          end

          def sort_files(files)
            case @sort
            when 'asc'
              files.sort
            when 'desc'
              files.sort.reverse
            else # 'inferred'
              # If explicit files were provided (no wildcards), maintain order
              return files unless @files.include?('*')

              files.sort
            end
          end
        end

        # Parses SRT files into structured subtitle objects
        class SRTParser
          # Represents a single subtitle entry
          class Subtitle
            attr_reader :index, :start_time, :end_time, :text

            def initialize(index:, start_time:, end_time:, text:)
              @index = index
              @start_time = parse_timestamp(start_time)
              @end_time = parse_timestamp(end_time)
              @text = text.strip
            end

            private

            # Converts SRT timestamp (00:00:00,000) to seconds (float)
            def parse_timestamp(timestamp)
              hours, minutes, seconds_ms = timestamp.split(':')
              seconds, milliseconds = seconds_ms.split(',')

              (hours.to_i * 3600) +
                (minutes.to_i * 60) +
                seconds.to_i +
                (milliseconds.to_i / 1000.0)
            end
          end

          def parse(content)
            validate_content!(content)

            subtitles = []
            current_block = { text: [] }

            content.split("\n").each do |line|
              line = line.strip

              if line.empty?
                process_block(current_block, subtitles) if current_block[:index]
                current_block = { text: [] }
                next
              end

              if current_block[:index].nil?
                current_block[:index] = line.to_i
              elsif current_block[:timestamp].nil? && line.include?(' --> ')
                start_time, end_time = line.split(' --> ')
                current_block[:timestamp] = { start: start_time, end: end_time }
              else
                current_block[:text] << line
              end
            end

            # Process the last block if it exists
            process_block(current_block, subtitles) if current_block[:index]

            subtitles
          end

          private

          def validate_content!(content)
            raise ArgumentError, 'Content cannot be nil' if content.nil?
            raise ArgumentError, 'Content cannot be empty' if content.strip.empty?

            # Basic structure validation - should have numbers and timestamps
            return if content.match?(/\d+\s*\n\d{2}:\d{2}:\d{2},\d{3}\s*-->\s*\d{2}:\d{2}:\d{2},\d{3}/)

            raise ArgumentError, 'Invalid SRT format: missing required timestamp format'
          end

          def process_block(block, subtitles)
            return unless block[:index] && block[:timestamp] && !block[:text].empty?

            subtitles << Subtitle.new(
              index: block[:index],
              start_time: block[:timestamp][:start],
              end_time: block[:timestamp][:end],
              text: block[:text].join("\n")
            )
          end
        end

        # Merges multiple subtitle arrays while maintaining timing and adding buffers
        class SRTMerger
          def initialize(buffer_ms: 100)
            @buffer_ms = buffer_ms.to_f
          end

          def merge(subtitle_arrays)
            return [] if subtitle_arrays.empty?

            merged = []
            current_end_time = 0.0

            subtitle_arrays.each do |subtitles|
              next if subtitles.empty?

              # Calculate offset needed for this batch of subtitles
              first_subtitle = subtitles.first
              offset_seconds = calculate_offset(current_end_time, first_subtitle.start_time)

              # Add adjusted subtitles to merged array
              subtitles.each do |subtitle|
                adjusted_subtitle = adjust_subtitle_timing(subtitle, offset_seconds)
                merged << adjusted_subtitle
              end

              # Update current_end_time for next batch
              current_end_time = merged.last.end_time
            end

            # Renumber subtitles sequentially
            merged.each_with_index do |subtitle, index|
              subtitle.instance_variable_set(:@index, index + 1)
            end

            merged
          end

          private

          def calculate_offset(current_end_time, next_start_time)
            return 0.0 if current_end_time.zero?

            buffer_seconds = @buffer_ms / 1000.0
            needed_offset = current_end_time + buffer_seconds - next_start_time
            [needed_offset, 0].max
          end

          def adjust_subtitle_timing(subtitle, offset_seconds)
            # Create new Subtitle instance with adjusted timing
            SRTParser::Subtitle.new(
              index: subtitle.index,
              start_time: format_time(subtitle.start_time + offset_seconds),
              end_time: format_time(subtitle.end_time + offset_seconds),
              text: subtitle.text
            )
          end

          def format_time(seconds)
            # Convert seconds back to SRT timestamp format (00:00:00,000)
            hours = (seconds / 3600).floor
            minutes = ((seconds % 3600) / 60).floor
            seconds_remaining = seconds % 60
            milliseconds = ((seconds_remaining % 1) * 1000).round

            format(
              '%<hours>02d:%<minutes>02d:%<seconds>02d,%<milliseconds>03d',
              hours: hours,
              minutes: minutes,
              seconds: seconds_remaining.floor,
              milliseconds: milliseconds
            )
          end
        end

        # Converts subtitle objects back to SRT format and writes to disk
        class SRTWriter
          def initialize(output_file)
            @output_file = output_file
          end

          def write(subtitles)
            content = format_subtitles(subtitles)
            File.write(@output_file, content, encoding: 'UTF-8')
          end

          private

          def format_subtitles(subtitles)
            subtitles.each_with_index.map do |subtitle, index|
              [
                index + 1, # Force sequential numbering
                format_timestamp_line(subtitle),
                subtitle.text,
                '' # Empty line between subtitle blocks
              ].join("\n")
            end.join("\n")
          end

          def format_timestamp_line(subtitle)
            "#{format_timestamp(subtitle.start_time)} --> #{format_timestamp(subtitle.end_time)}"
          end

          def format_timestamp(seconds)
            hours = (seconds / 3600).floor
            minutes = ((seconds % 3600) / 60).floor
            seconds_remaining = seconds % 60
            milliseconds = ((seconds_remaining % 1) * 1000).round

            format(
              '%<hours>02d:%<minutes>02d:%<seconds>02d,%<milliseconds>03d',
              hours: hours,
              minutes: minutes,
              seconds: seconds_remaining.floor,
              milliseconds: milliseconds
            )
          end
        end

        # Simple logger for debugging
        class Logger
          LEVELS = { none: 0, info: 1, detail: 2 }.freeze

          def initialize(level = :info)
            @level = LEVELS[level] || LEVELS[:info]
          end

          def log(level, message)
            puts message if LEVELS[level] <= @level
          end
        end

        # rubocop:disable Metrics/ParameterLists
        def initialize(folder: './', files: '*.srt', sort: 'inferred', buffer: 100, output: 'merged.srt',
                       log_level: :info)
          # rubocop:enable Metrics/ParameterLists
          @folder = folder
          @files = files
          @sort = sort
          @buffer = buffer
          @output = output
          @logger = Logger.new(log_level)
        end

        def join
          @logger.log(:info, "Starting join operation in folder: #{@folder} with files: #{@files}")
          resolved_files = resolve_files
          @logger.log(:info, "Resolved files: #{resolved_files.join(', ')}")

          subtitle_groups = parse_files(resolved_files)
          @logger.log(:detail, "Parsed subtitles: #{subtitle_groups.map(&:size)} from files.")

          merged_subtitles = merge_subtitles(subtitle_groups)
          @logger.log(:info, "Merged #{subtitle_groups.flatten.size} subtitles into #{merged_subtitles.size} blocks.")

          write_output(merged_subtitles)
          @logger.log(:info, "Output written to #{@output}")
        end

        private

        def resolve_files
          resolver = FileResolver.new(
            folder: @folder,
            files: @files,
            sort: @sort
          )
          resolver.process
        end

        def parse_files(files)
          files.map do |file|
            content = File.read(file, encoding: 'UTF-8')
            parse_srt_content(content)
          end
        end

        def parse_srt_content(content)
          parser = SRTParser.new
          parser.parse(content)
        end

        def merge_subtitles(subtitle_groups)
          merger = SRTMerger.new(buffer_ms: @buffer)
          merger.merge(subtitle_groups)
        end

        def write_output(subtitles)
          writer = SRTWriter.new(@output)
          writer.write(subtitles)
        end
      end
    end
  end
end
