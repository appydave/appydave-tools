# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::PathValidator do
  let(:validator) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe '#exists?' do
    it 'returns true for existing directory' do
      expect(validator.exists?(temp_dir)).to be true
    end

    it 'returns false for non-existing directory' do
      expect(validator.exists?('/nonexistent/path/12345')).to be false
    end

    it 'expands ~ in paths' do
      # This tests that ~ is expanded, not that the path exists
      # The home directory should exist
      expect(validator.exists?('~')).to be true
    end
  end

  describe '#file_exists?' do
    it 'returns true for existing file' do
      file_path = File.join(temp_dir, 'test.txt')
      File.write(file_path, 'test')

      expect(validator.file_exists?(file_path)).to be true
    end

    it 'returns false for non-existing file' do
      expect(validator.file_exists?('/nonexistent/file.txt')).to be false
    end
  end

  describe '#expand' do
    it 'expands ~ to home directory' do
      expanded = validator.expand('~/test')

      expect(expanded).to start_with('/')
      expect(expanded).not_to include('~')
    end

    it 'returns absolute paths unchanged' do
      expect(validator.expand('/absolute/path')).to eq('/absolute/path')
    end
  end
end
