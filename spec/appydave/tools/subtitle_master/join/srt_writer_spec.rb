# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::SubtitleMaster::Join::SRTWriter do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_file) { File.join(temp_dir, 'output.srt') }
  let(:writer) { described_class.new(output_file) }
  let(:parser) { Appydave::Tools::SubtitleMaster::Join::SRTParser.new }

  after do
    FileUtils.remove_entry temp_dir
  end

  describe '#write' do
    context 'with valid subtitles' do
      let(:subtitles) do
        [
          create_subtitle(1, '00:00:00,000', '00:00:02,000', 'First line'),
          create_subtitle(2, '00:00:02,000', '00:00:04,000', 'Second line'),
          create_subtitle(3, '00:00:04,000', '00:00:06,000', 'Third line')
        ]
      end

      it 'writes subtitles in correct SRT format' do
        writer.write(subtitles)
        content = File.read(output_file)

        expected_content = <<~EXPECTED
          1
          00:00:00,000 --> 00:00:02,000
          First line

          2
          00:00:02,000 --> 00:00:04,000
          Second line

          3
          00:00:04,000 --> 00:00:06,000
          Third line
        EXPECTED

        expect(content).to eq(expected_content)
      end

      it 'maintains sequential numbering' do
        # Deliberately mix up the indices
        subtitles.each { |s| s.instance_variable_set(:@index, rand(100)) }

        writer.write(subtitles)
        content = File.read(output_file)

        expect(content).to match(/^1\n/)
        expect(content).to match(/\n2\n/)
        expect(content).to match(/\n3\n/)
      end
    end

    context 'with empty subtitle list' do
      it 'creates an empty file' do
        writer.write([])
        expect(File.read(output_file)).to be_empty
      end
    end

    context 'with multi-line subtitles' do
      let(:subtitles) do
        [
          create_subtitle(1, '00:00:00,000', '00:00:03,000', "First line\nSecond line"),
          create_subtitle(2, '00:00:03,000', '00:00:06,000', "Another subtitle\nWith multiple\nlines")
        ]
      end

      it 'preserves line breaks in subtitle text' do
        writer.write(subtitles)
        content = File.read(output_file)

        expected_content = <<~EXPECTED
          1
          00:00:00,000 --> 00:00:03,000
          First line
          Second line

          2
          00:00:03,000 --> 00:00:06,000
          Another subtitle
          With multiple
          lines
        EXPECTED

        expect(content).to eq(expected_content)
      end
    end

    context 'with special characters' do
      let(:subtitles) do
        [
          create_subtitle(1, '00:00:00,000', '00:00:02,000', 'Special chars: áéíóú'),
          create_subtitle(2, '00:00:02,000', '00:00:04,000', 'Symbols: &<>"\''),
          create_subtitle(3, '00:00:04,000', '00:00:06,000', 'HTML: <u>underlined</u>')
        ]
      end

      it 'maintains UTF-8 encoding and special characters' do
        writer.write(subtitles)
        content = File.read(output_file, encoding: 'UTF-8')

        expect(content).to include('áéíóú')
        expect(content).to include('&<>"\'')
        expect(content).to include('<u>underlined</u>')
      end
    end

    context 'with file system errors' do
      it 'raises error when directory is not writable' do
        FileUtils.chmod(0o444, temp_dir)

        expect do
          writer.write([create_subtitle(1, '00:00:00,000', '00:00:02,000', 'Test')])
        end.to raise_error(Errno::EACCES)
      end

      it 'raises error when file cannot be created' do
        allow(File).to receive(:write).and_raise(IOError)

        expect do
          writer.write([create_subtitle(1, '00:00:00,000', '00:00:02,000', 'Test')])
        end.to raise_error(IOError)
      end
    end
  end

  private

  def create_subtitle(index, start_time, end_time, text)
    Appydave::Tools::SubtitleMaster::Join::SRTParser::Subtitle.new(
      index: index,
      start_time: start_time,
      end_time: end_time,
      text: text
    )
  end
end
