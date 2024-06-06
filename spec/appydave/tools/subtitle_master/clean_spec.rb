# frozen_string_literal: true

require 'appydave/tools/subtitle_master/clean'

RSpec.describe Appydave::Tools::SubtitleMaster::Clean do
  let(:file_path) { 'spec/fixtures/subtitle_master/test.srt' }
  let(:cleaner) { described_class.new(file_path) }

  describe '#clean' do
    it 'normalizes the subtitles correctly' do
      expected_content = <<~SRT
        1
        00:00:00,060 --> 00:00:02,760
        I had a wonderful relationship with Mid Journey.

        2
        00:00:03,060 --> 00:00:05,040
        We've shared many experiences and created a lot of memories over the last 12 months.
      SRT

      cleaned_content = cleaner.clean
      expect(cleaned_content.strip.encode('UTF-8')).to eq(expected_content.strip.encode('UTF-8'))
    end
  end
end
