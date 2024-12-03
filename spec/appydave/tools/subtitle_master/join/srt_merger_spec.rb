# frozen_string_literal: true

RSpec.describe Appydave::Tools::SubtitleMaster::Join::SRTMerger do
  let(:parser) { Appydave::Tools::SubtitleMaster::Join::SRTParser.new }
  let(:merger) { described_class.new(buffer_ms: 100) }

  let(:first_content) do
    <<~SRT
      1
      00:00:01,000 --> 00:00:04,000
      First subtitle
    SRT
  end

  let(:second_content) do
    <<~SRT
      1
      00:00:01,000 --> 00:00:05,000
      Second file subtitle
    SRT
  end

  describe '#merge' do
    it 'returns empty array for empty input' do
      expect(merger.merge([])).to eq([])
    end

    it 'preserves single subtitle array unchanged' do
      subtitles = parser.parse(first_content)
      result = merger.merge([subtitles])

      expect(result.length).to eq(1)
      expect(result.first.text).to eq('First subtitle')
      expect(result.first.start_time).to eq(1.0)
      expect(result.first.end_time).to eq(4.0)
    end

    it 'creates sequential non-overlapping subtitles with proper duration' do
      first_subtitles = parser.parse(first_content)
      second_subtitles = parser.parse(second_content)

      result = merger.merge([first_subtitles, second_subtitles])

      expect(result.size).to eq(2)

      # First subtitle should maintain its original timing
      expect(result[0].start_time).to eq(1.0)
      expect(result[0].end_time).to eq(4.0)
      expect(result[0].text).to eq('First subtitle')

      # Second subtitle should start after first + buffer
      expect(result[1].start_time).to eq(4.1) # 4.0 + 0.1s buffer
      expect(result[1].end_time).to eq(8.1)   # 4.1 + 4.0s duration
      expect(result[1].text).to eq('Second file subtitle')

      # Verify total duration
      total_duration = result.last.end_time - result.first.start_time
      expect(total_duration).to eq(7.1) # 3s first + 0.1s buffer + 4s second
    end

    it 'handles multiple files maintaining proper spacing' do
      third_content = <<~SRT
        1
        00:00:01,000 --> 00:00:03,000
        Third subtitle
      SRT

      first_subtitles = parser.parse(first_content)
      second_subtitles = parser.parse(second_content)
      third_subtitles = parser.parse(third_content)

      result = merger.merge([first_subtitles, second_subtitles, third_subtitles])

      expect(result.size).to eq(3)

      # Verify sequential timing
      expect(result[0].start_time).to eq(1.0)
      expect(result[0].end_time).to eq(4.0)

      expect(result[1].start_time).to eq(4.1)
      expect(result[1].end_time).to eq(8.1)

      expect(result[2].start_time).to eq(8.2)
      expect(result[2].end_time).to eq(10.2)

      # Verify total duration (3s + 0.1s + 4s + 0.1s + 2s = 9.2s)
      total_duration = result.last.end_time - result.first.start_time
      expect(total_duration).to eq(9.2)
    end

    it 'renumbers subtitles sequentially' do
      first_subtitles = parser.parse(first_content)
      second_subtitles = parser.parse(second_content)

      result = merger.merge([first_subtitles, second_subtitles])

      expect(result[0].index).to eq(1)
      expect(result[1].index).to eq(2)
    end
  end
end
