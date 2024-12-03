# frozen_string_literal: true

RSpec.describe Appydave::Tools::SubtitleMaster::Join::FileResolver do
  let(:temp_folder) { Dir.mktmpdir }

  before do
    # Create test files in temporary directory
    FileUtils.touch(File.join(temp_folder, 'a.srt'))
    FileUtils.touch(File.join(temp_folder, 'b.srt'))
    FileUtils.touch(File.join(temp_folder, 'c.srt'))
    FileUtils.touch(File.join(temp_folder, 'test 1.srt'))
    FileUtils.touch(File.join(temp_folder, 'special@file.srt'))
  end

  after do
    # Clean up temporary directory
    FileUtils.remove_entry temp_folder
  end

  describe '#initialize' do
    it 'initializes with folder, files, and sort attributes' do
      resolver = described_class.new(folder: temp_folder, files: '*.srt', sort: 'asc')
      expect(resolver).to be_a(described_class)
    end

    it 'raises an error if folder is not provided' do
      expect do
        described_class.new(files: '*.srt', sort: 'asc')
      end.to raise_error(ArgumentError)
    end

    it 'raises an error if files is not provided' do
      expect do
        described_class.new(folder: temp_folder, sort: 'asc')
      end.to raise_error(ArgumentError)
    end
  end

  describe '#process' do
    context 'with wildcard patterns' do
      it 'resolves all .srt files in the given folder' do
        resolver = described_class.new(folder: temp_folder, files: '*.srt', sort: 'asc')
        files = resolver.process
        expect(files.length).to eq(5)
        expect(files.all? { |f| f.end_with?('.srt') }).to be true
      end

      it 'sorts files in ascending order when sort is asc' do
        resolver = described_class.new(folder: temp_folder, files: '*.srt', sort: 'asc')
        files = resolver.process
        expect(files).to eq(files.sort)
      end

      it 'sorts files in descending order when sort is desc' do
        resolver = described_class.new(folder: temp_folder, files: '*.srt', sort: 'desc')
        files = resolver.process
        expect(files).to eq(files.sort.reverse)
      end

      it 'returns an empty array when no files match the pattern' do
        resolver = described_class.new(folder: temp_folder, files: 'nonexistent*.srt', sort: 'asc')
        expect(resolver.process).to be_empty
      end
    end

    context 'with explicit filenames' do
      it 'resolves explicit filenames correctly' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'a.srt,b.srt',
          sort: 'inferred'
        )
        files = resolver.process
        expect(files.map { |f| File.basename(f) }).to eq(['a.srt', 'b.srt'])
      end

      it 'skips non-existent files' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'a.srt,nonexistent.srt,b.srt',
          sort: 'inferred'
        )
        files = resolver.process
        expect(files.map { |f| File.basename(f) }).to eq(['a.srt', 'b.srt'])
      end

      it 'maintains order with inferred sorting' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'b.srt,a.srt',
          sort: 'inferred'
        )
        files = resolver.process
        expect(files.map { |f| File.basename(f) }).to eq(['b.srt', 'a.srt'])
      end
    end

    context 'with mixed patterns' do
      it 'handles both wildcards and explicit files' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'a.srt,*.srt',
          sort: 'inferred'
        )
        files = resolver.process
        expect(files).not_to be_empty
        expect(files.first).to end_with('a.srt')
      end
    end

    context 'when edge cases and error handling occur' do
      it 'raises an error for non-existent folder' do
        expect do
          resolver = described_class.new(
            folder: 'nonexistent_folder',
            files: '*.srt',
            sort: 'asc'
          )
          resolver.process
        end.to raise_error(Errno::ENOENT)
      end

      it 'handles files with spaces' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'test 1.srt',
          sort: 'asc'
        )
        files = resolver.process
        expect(files.map { |f| File.basename(f) }).to include('test 1.srt')
      end

      it 'handles files with special characters' do
        resolver = described_class.new(
          folder: temp_folder,
          files: 'special@file.srt',
          sort: 'asc'
        )
        files = resolver.process
        expect(files.map { |f| File.basename(f) }).to include('special@file.srt')
      end
    end
  end
end
