# frozen_string_literal: true

RSpec.describe Appydave::Tools::SubtitleProcessor::Join::SRTParser do
  let(:valid_srt_content) do
    <<~SRT
      1
      00:00:01,000 --> 00:00:04,000
      First subtitle

      2
      00:00:05,000 --> 00:00:09,500
      Second subtitle
      with multiple lines

      3
      00:01:00,000 --> 00:01:30,000
      Third subtitle
    SRT
  end

  describe '#parse' do
    context 'with valid SRT content' do
      it 'parses subtitle blocks into structured objects' do
        parser = described_class.new
        subtitles = parser.parse(valid_srt_content)

        expect(subtitles.length).to eq(3)
        expect(subtitles.first).to be_a(described_class::Subtitle)
      end

      it 'correctly extracts subtitle components' do
        parser = described_class.new
        subtitles = parser.parse(valid_srt_content)
        first_subtitle = subtitles.first

        expect(first_subtitle.index).to eq(1)
        expect(first_subtitle.start_time).to eq(1.0)  # 00:00:01,000 in seconds
        expect(first_subtitle.end_time).to eq(4.0)    # 00:00:04,000 in seconds
        expect(first_subtitle.text).to eq('First subtitle')
      end

      it 'handles multiline subtitle text' do
        parser = described_class.new
        subtitles = parser.parse(valid_srt_content)
        second_subtitle = subtitles[1]

        expect(second_subtitle.text).to eq("Second subtitle\nwith multiple lines")
      end
    end

    context 'with invalid content' do
      it 'raises error for nil content' do
        parser = described_class.new
        expect { parser.parse(nil) }.to raise_error(ArgumentError, 'Content cannot be nil')
      end

      it 'raises error for empty content' do
        parser = described_class.new
        expect { parser.parse('') }.to raise_error(ArgumentError, 'Content cannot be empty')
      end

      it 'raises error for content without valid timestamps' do
        parser = described_class.new
        invalid_content = "1\nInvalid timestamp\nSubtitle text"
        expect { parser.parse(invalid_content) }
          .to raise_error(ArgumentError, 'Invalid SRT format: missing required timestamp format')
      end
    end

    context 'with timestamp parsing' do
      it 'correctly converts timestamps to seconds' do
        parser = described_class.new
        complex_timestamp = <<~SRT
          1
          01:30:45,500 --> 02:15:30,750
          Test subtitle
        SRT

        subtitles = parser.parse(complex_timestamp)
        subtitle = subtitles.first

        # 01:30:45,500 = (1 * 3600) + (30 * 60) + 45 + (500/1000) = 5445.5 seconds
        expect(subtitle.start_time).to eq(5445.5)
        # 02:15:30,750 = (2 * 3600) + (15 * 60) + 30 + (750/1000) = 8130.75 seconds
        expect(subtitle.end_time).to eq(8130.75)
      end
    end

    context 'with edge cases' do
      it 'handles extra blank lines between subtitles' do
        content_with_extra_lines = <<~SRT
          1
          00:00:01,000 --> 00:00:04,000
          First subtitle


          2
          00:00:05,000 --> 00:00:09,500
          Second subtitle
        SRT

        parser = described_class.new
        subtitles = parser.parse(content_with_extra_lines)
        expect(subtitles.length).to eq(2)
      end

      it 'processes the final subtitle block without trailing blank line' do
        content_without_final_newline = valid_srt_content.strip
        parser = described_class.new
        subtitles = parser.parse(content_without_final_newline)
        expect(subtitles.length).to eq(3)
      end

      it 'handles different newline characters' do
        content_with_windows_newlines = valid_srt_content.gsub("\n", "\r\n")
        parser = described_class.new
        expect { parser.parse(content_with_windows_newlines) }.not_to raise_error
      end
    end
  end
end
