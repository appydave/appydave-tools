# frozen_string_literal: true

RSpec.describe Appydave::Tools::SubtitleProcessor::Transcript do
  let(:srt_content) do
    <<~SRT
      1
      00:00:00,060 --> 00:00:01,760
      Hello world.

      2
      00:00:01,760 --> 00:00:03,060
      This is a test.

      3
      00:00:03,060 --> 00:00:05,040
      Goodbye world.
    SRT
  end

  describe '#initialize' do
    it 'initializes with file_path' do
      file_path = File.expand_path('../../../fixtures/subtitle_processor/test.srt', __dir__)
      expect { described_class.new(file_path: file_path) }.not_to raise_error
    end

    it 'initializes with srt_content' do
      expect { described_class.new(srt_content: srt_content) }.not_to raise_error
    end

    it 'raises error when both file_path and srt_content are provided' do
      file_path = File.expand_path('../../../fixtures/subtitle_processor/test.srt', __dir__)
      expect { described_class.new(file_path: file_path, srt_content: srt_content) }
        .to raise_error(ArgumentError, 'You cannot provide both a file path and an SRT content stream.')
    end

    it 'raises error when neither file_path nor srt_content are provided' do
      expect { described_class.new }
        .to raise_error(ArgumentError, 'You must provide either a file path or an SRT content stream.')
    end
  end

  describe '#extract' do
    subject(:transcript) { described_class.new(srt_content: srt_content) }

    it 'extracts plain text from SRT content' do
      result = transcript.extract
      expect(result).to eq("Hello world.\nThis is a test.\nGoodbye world.")
    end

    it 'uses custom paragraph gap' do
      result = transcript.extract(paragraph_gap: 2)
      expect(result).to eq("Hello world.\n\nThis is a test.\n\nGoodbye world.")
    end

    it 'strips timestamps and indices' do
      result = transcript.extract
      expect(result).not_to include('00:00:')
      expect(result).not_to match(/^\d+$/)
      expect(result).not_to include('-->')
    end
  end

  describe '#write' do
    subject(:transcript) { described_class.new(srt_content: srt_content) }

    let(:output_file) { File.expand_path('../../../fixtures/subtitle_processor/output_transcript.txt', __dir__) }

    after do
      FileUtils.rm_f(output_file)
    end

    it 'writes transcript to file' do
      transcript.write(output_file)
      expect(File.exist?(output_file)).to be true
      expect(File.read(output_file)).to eq("Hello world.\nThis is a test.\nGoodbye world.")
    end

    it 'writes with custom paragraph gap' do
      transcript.write(output_file, paragraph_gap: 2)
      expect(File.read(output_file)).to eq("Hello world.\n\nThis is a test.\n\nGoodbye world.")
    end
  end
end
