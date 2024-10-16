# frozen_string_literal: true

RSpec.describe Appydave::Tools::GptContext::FileCollector do
  subject(:collector) { described_class.new(options) }

  let(:temp_dir) { Dir.mktmpdir }
  let(:options) do
    Appydave::Tools::GptContext::Options.new(
      include_patterns: include_patterns,
      exclude_patterns: exclude_patterns,
      format: format,
      line_limit: line_limit,
      working_directory: temp_dir
    )
  end

  let(:include_patterns) { ['**/*.txt'] }
  let(:exclude_patterns) { ['excluded/*.txt', '**/deep/**/*'] }
  let(:format) { 'content' }
  let(:line_limit) { nil }

  before do
    # Create test files
    FileUtils.mkdir_p(File.join(temp_dir, 'included/subdir'))
    FileUtils.mkdir_p(File.join(temp_dir, 'excluded'))
    FileUtils.mkdir_p(File.join(temp_dir, 'included/deep'))

    File.write(File.join(temp_dir, 'included/file1.txt'), "File 1 content\nLine #2")
    File.write(File.join(temp_dir, 'included/file2.txt'), "File 2 content\nLine #2")
    File.write(File.join(temp_dir, 'included/subdir/file3.txt'), "File 3 content\nLine #2")
    File.write(File.join(temp_dir, 'excluded/excluded_file.txt'), 'Excluded file content')
    File.write(File.join(temp_dir, 'included/deep/deep_file.txt'), 'Deep file content')
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe '#build' do
    context 'when gathering content' do
      it 'concatenates content from files matching include patterns' do
        expect(subject.build).to include('File 1 content', 'File 2 content')
      end

      it 'excludes content from files matching exclude patterns' do
        expect(subject.build).not_to include('Excluded file content')
        expect(subject.build).not_to include('Deep file content')
      end

      it 'includes file paths as headers in the gathered content' do
        expect(subject.build)
          .to include('# file: included/file1.txt')
          .and include('# file: included/file2.txt')
      end
    end

    context 'when line limit is set' do
      let(:line_limit) { 1 }

      it 'limits the number of lines included from each file' do
        expect(subject.build).not_to include('Line #2')
      end
    end
  end

  describe '#build with tree format' do
    let(:format) { 'tree' }
    let(:include_patterns) { ['**/*'] }
    let(:exclude_patterns) { [] }

    it 'prints a tree view of the included files and directories with improved ASCII art' do
      expected_output = <<~TREE.strip
        ├─ excluded
        │ ├─ excluded_file.txt
        └─ included
          ├─ deep
          │ ├─ deep_file.txt
          ├─ file1.txt
          ├─ file2.txt
          └─ subdir
            └─ file3.txt
      TREE

      expect(subject.build.strip).to eq(expected_output)
    end
  end

  describe '#build with both formats' do
    let(:format) { 'tree,content' }
    let(:include_patterns) { ['**/*'] }
    let(:exclude_patterns) { [] }

    it 'prints both a tree view and the file contents' do
      result = subject.build

      expect(result).to include('├─ excluded')
      expect(result).to include('└─ included')
      expect(result).to include('# file: included/file1.txt')
      expect(result).to include('File 1 content')
      expect(result).to include('File 2 content')
      expect(result).to include('File 3 content')
    end
  end
end
