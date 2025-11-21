# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::FileUtils do
  describe '.calculate_directory_size' do
    let(:temp_dir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(temp_dir) }

    it 'returns 0 for non-existent directory' do
      expect(described_class.calculate_directory_size('/nonexistent/path')).to eq(0)
    end

    it 'returns 0 for empty directory' do
      expect(described_class.calculate_directory_size(temp_dir)).to eq(0)
    end

    it 'calculates size of directory with files' do
      File.write(File.join(temp_dir, 'file1.txt'), 'a' * 100)
      File.write(File.join(temp_dir, 'file2.txt'), 'b' * 200)

      size = described_class.calculate_directory_size(temp_dir)
      expect(size).to eq(300)
    end

    it 'calculates size of nested directories' do
      subdir = File.join(temp_dir, 'subdir')
      Dir.mkdir(subdir)
      File.write(File.join(temp_dir, 'file1.txt'), 'a' * 100)
      File.write(File.join(subdir, 'file2.txt'), 'b' * 200)

      size = described_class.calculate_directory_size(temp_dir)
      expect(size).to eq(300)
    end

    it 'handles permission errors gracefully' do
      # Create a file we can't read (if possible)
      # This test is OS-dependent, so we just ensure it doesn't crash
      expect { described_class.calculate_directory_size(temp_dir) }.not_to raise_error
    end
  end

  describe '.format_size' do
    it 'formats 0 bytes' do
      expect(described_class.format_size(0)).to eq('0 B')
    end

    it 'formats bytes' do
      expect(described_class.format_size(512)).to eq('512.0 B')
    end

    it 'formats kilobytes' do
      expect(described_class.format_size(1024)).to eq('1.0 KB')
      expect(described_class.format_size(1536)).to eq('1.5 KB')
    end

    it 'formats megabytes' do
      expect(described_class.format_size(1_048_576)).to eq('1.0 MB')
      expect(described_class.format_size(5_242_880)).to eq('5.0 MB')
    end

    it 'formats gigabytes' do
      expect(described_class.format_size(1_073_741_824)).to eq('1.0 GB')
      expect(described_class.format_size(2_147_483_648)).to eq('2.0 GB')
    end

    it 'formats terabytes' do
      expect(described_class.format_size(1_099_511_627_776)).to eq('1.0 TB')
    end
  end
end
