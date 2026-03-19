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

  describe '#build with json format' do
    let(:format) { 'json' }
    let(:include_patterns) { ['**/*.txt'] }
    let(:exclude_patterns) { ['excluded/**/*'] }

    it 'returns valid JSON' do
      result = subject.build
      expect { JSON.parse(result) }.not_to raise_error
    end

    it 'includes a tree key in the JSON output' do
      result = JSON.parse(subject.build)
      expect(result).to have_key('tree')
    end

    it 'includes a content key in the JSON output' do
      result = JSON.parse(subject.build)
      expect(result).to have_key('content')
    end

    it 'includes file paths and content in the content array' do
      result = JSON.parse(subject.build)
      files = result['content'].map { |f| f['file'] }
      expect(files).to include('included/file1.txt')

      entry = result['content'].find { |f| f['file'] == 'included/file1.txt' }
      expect(entry['content']).to include('File 1 content')
    end

    it 'excludes files matching exclude patterns from content' do
      result = JSON.parse(subject.build)
      files = result['content'].map { |f| f['file'] }
      expect(files).not_to include('excluded/excluded_file.txt')
    end
  end

  describe '#build with aider format' do
    let(:format) { 'aider' }
    let(:include_patterns) { ['**/*.txt'] }
    let(:exclude_patterns) { [] }

    context 'when prompt is set' do
      let(:options) do
        Appydave::Tools::GptContext::Options.new(
          include_patterns: include_patterns,
          exclude_patterns: exclude_patterns,
          format: format,
          line_limit: nil,
          working_directory: temp_dir,
          prompt: 'fix the bug'
        )
      end

      it 'returns an aider command string' do
        expect(subject.build).to start_with('aider --message')
      end

      it 'includes the prompt in the command' do
        expect(subject.build).to include('fix the bug')
      end

      it 'includes collected file paths in the command' do
        result = subject.build
        expect(result).to include('included/file1.txt')
      end
    end

    context 'when prompt is not set' do
      it 'returns an empty string' do
        expect(subject.build).to eq('')
      end
    end
  end

  describe '#build with nonexistent working directory' do
    let(:options) do
      Appydave::Tools::GptContext::Options.new(
        include_patterns: ['**/*.nonexistent_xyz_12345'],
        exclude_patterns: [],
        format: 'content',
        line_limit: nil,
        working_directory: '/tmp/does-not-exist-12345'
      )
    end

    it 'returns empty string without raising an error' do
      expect { subject.build }.not_to raise_error
      expect(subject.build).to eq('')
    end
  end
end
