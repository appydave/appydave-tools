# frozen_string_literal: true

RSpec.describe Appydave::Tools::GptContext::FileCollector do # , :tools_enabled do
  describe '#build' do
    subject { described_class.new(include_patterns: include_patterns, exclude_patterns: exclude_patterns) }

    let(:include_patterns) { ['spec/fixtures/gpt-content-gatherer/**/*.txt'] }
    let(:exclude_patterns) { ['spec/fixtures/gpt-content-gatherer/excluded/*.txt'] }

    context 'when gathering content' do
      it 'concatenates content from files matching include patterns' do
        expect(subject.build).to include('File 1 content', 'File 2 content')
      end

      it 'excludes content from files matching exclude patterns' do
        expect(subject.build).not_to include('Excluded file content')
      end

      it 'includes file paths as headers in the gathered content' do
        expect(subject.build)
          .to include('# file: spec/fixtures/gpt-content-gatherer/included/file1.txt')
          .and include('# file: spec/fixtures/gpt-content-gatherer/included/file2.txt')
      end
    end
  end

  describe '#build with tree format' do
    subject { described_class.new(include_patterns: include_patterns, exclude_patterns: exclude_patterns, format: 'tree') }

    let(:include_patterns) { ['spec/fixtures/gpt-content-gatherer/**/*'] }
    let(:exclude_patterns) { [] }

    before do
      allow(Dir).to receive(:glob).and_return(
        [
          'spec/fixtures/gpt-content-gatherer/included/file1.txt',
          'spec/fixtures/gpt-content-gatherer/included/file2.txt',
          'spec/fixtures/gpt-content-gatherer/included/subdir/file3.txt'
        ]
      )
      allow(File).to receive(:directory?).and_return(false)
      # allow(subject).to receive(:excluded?).and_return(false)
    end

    it 'prints a tree view of the included files and directories with improved ASCII art' do
      expected_output = <<~TREE
        └─ spec
          └─ fixtures
            └─ gpt-content-gatherer
              └─ included
                ├─ file1.txt
                ├─ file2.txt
                └─ subdir
                  └─ file3.txt
      TREE

      # puts subject.build

      expect(subject.build.strip).to eq(expected_output.strip)
    end
  end
end
