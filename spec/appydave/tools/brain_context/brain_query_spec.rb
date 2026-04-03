# frozen_string_literal: true

RSpec.describe Appydave::Tools::BrainQuery do
  subject { described_class.new(options) }

  let(:options) { Appydave::Tools::BrainContextOptions.new }

  before do
    # Ensure brains-index.json exists
    skip 'brains-index.json not found' unless File.exist?(options.brains_index_path)
  end

  describe '#find' do
    context 'when no queries are specified' do
      it 'returns empty array' do
        expect(subject.find).to eq([])
      end
    end

    context 'when querying by brain name' do
      it 'returns paths for existing brain' do
        options.brain_names = ['omi']
        paths = subject.find

        expect(paths).not_to be_empty
        expect(paths.all? { |p| p.include?('omi') }).to be true
      end

      it 'returns empty array for non-existent brain' do
        options.brain_names = ['nonexistent-brain']
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when querying by tag' do
      it 'returns paths for brains with tag' do
        options.tags = ['agentic-engineering']
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns multiple brains for common tag' do
        options.tags = ['agentic-engineering']
        paths = subject.find

        # Should include files from multiple brains
        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs.length).to be > 1
      end
    end

    context 'when including INDEX.md' do
      it 'includes INDEX.md files by default' do
        options.brain_names = ['omi']
        options.include_index = true
        paths = subject.find

        expect(paths.any? { |p| p.end_with?('INDEX.md') }).to be true
      end

      it 'excludes INDEX.md when files_only is true' do
        options.brain_names = ['omi']
        options.include_index = false
        paths = subject.find

        expect(paths.none? { |p| p.end_with?('INDEX.md') }).to be true
      end
    end

    context 'when querying by category' do
      it 'returns paths for brains in category' do
        options.categories = ['agent-systems']
        paths = subject.find

        expect(paths).not_to be_empty
      end
    end

    context 'when combining multiple query types' do
      it 'combines results from brain_names and tags' do
        options.brain_names = ['omi']
        options.tags = ['agentic-engineering']
        paths = subject.find

        expect(paths).not_to be_empty
        # Should have both omi and agentic-engineering brains
        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs).to include('omi')
      end
    end
  end

  describe 'file paths' do
    it 'returns absolute paths' do
      options.brain_names = ['omi']
      paths = subject.find

      expect(paths.all? { |p| p.start_with?('/') }).to be true
    end

    it 'returns unique paths' do
      options.brain_names = ['omi']
      options.tags = ['agentic-engineering'] # might overlap
      paths = subject.find

      expect(paths.length).to eq(paths.uniq.length)
    end

    it 'returns sorted paths' do
      options.brain_names = ['omi']
      paths = subject.find

      expect(paths).to eq(paths.sort)
    end
  end
end
