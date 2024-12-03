# frozen_string_literal: true

require 'appydave/tools/subtitle_manager/clean'

RSpec.describe Appydave::Tools::SubtitleMaster::Clean do
  let(:file_path) { File.expand_path('../../../fixtures/subtitle_manager/test.srt', __dir__) }
  let(:simple_content) do
    <<~SRT
      1
      00:00:00,060 --> 00:00:01,760
      <u>The</u> quick

      2
      00:00:01,760 --> 00:00:03,060
      The <u>quick</u>

      3
      00:00:03,060 --> 00:00:10,040
      <u>brown</u> fox, jumps over the lazy dog.
    SRT
  end
  let(:srt_content) { simple_content }

  describe '#initialize' do
    it 'initializes with file_path' do
      expect { described_class.new(file_path: file_path) }.not_to raise_error
    end

    it 'initializes with srt_content' do
      expect { described_class.new(srt_content: srt_content) }.not_to raise_error
    end

    it 'raises error when both file_path and srt_content are provided' do
      expect { described_class.new(file_path: file_path, srt_content: srt_content) }
        .to raise_error(ArgumentError, 'You cannot provide both a file path and an SRT content stream.')
    end

    it 'raises error when neither file_path nor srt_content are provided' do
      expect { described_class.new }
        .to raise_error(ArgumentError, 'You must provide either a file path or an SRT content stream.')
    end
  end

  describe '#clean' do
    context 'when initialized with file_path' do
      let(:cleaner) { described_class.new(file_path: file_path) }
      let(:expected_content) do
        <<~SRT
          1
          00:00:00,060 --> 00:00:02,760
          I had a wonderful relationship with Mid Journey.

          2
          00:00:03,060 --> 00:00:05,040
          We have shared many experiences and created a lot of memories over the last 12 months.
        SRT
      end

      it 'normalizes the subtitles correctly' do
        cleaned_content = cleaner.clean
        expect(cleaned_content.strip.encode('UTF-8')).to eq(expected_content.strip.encode('UTF-8'))
      end
    end

    context 'when initialized with srt_content' do
      let(:cleaner) { described_class.new(srt_content: srt_content) }
      let(:expected_content) do
        <<~SRT
          1
          00:00:00,060 --> 00:00:03,060
          The quick

          2
          00:00:03,060 --> 00:00:10,040
          brown fox, jumps over the lazy dog.
        SRT
      end

      it 'normalizes the subtitles correctly' do
        cleaned_content = cleaner.clean
        expect(cleaned_content.strip.encode('UTF-8')).to eq(expected_content.strip.encode('UTF-8'))
      end
    end
  end
end
