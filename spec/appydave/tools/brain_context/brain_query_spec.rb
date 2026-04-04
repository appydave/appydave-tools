# frozen_string_literal: true

RSpec.describe Appydave::Tools::BrainQuery do
  subject { described_class.new(options) }

  let(:options) { Appydave::Tools::BrainContextOptions.new }

  before do
    skip 'brains-index.json not found' unless File.exist?(options.brains_index_path)
  end

  describe '#find' do
    context 'when no queries are specified' do
      it 'returns empty array' do
        expect(subject.find).to eq([])
      end
    end

    context 'when finding by name (--find)' do
      it 'returns paths for an exact brain name' do
        options.brain_names = ['omi']
        paths = subject.find

        expect(paths).not_to be_empty
        expect(paths.all? { |p| p.include?('omi') }).to be true
      end

      it 'returns empty array for non-existent term' do
        options.brain_names = ['nonexistent-brain-xyz']
        expect(subject.find).to eq([])
      end

      it 'finds brains by tag (unified search)' do
        options.brain_names = ['agentic-engineering']
        paths = subject.find

        expect(paths).not_to be_empty
        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs.length).to be > 1
      end

      it 'finds brains by partial name match' do
        options.brain_names = ['paper']
        paths = subject.find

        expect(paths).not_to be_empty
        expect(paths.any? { |p| p.include?('paperclip') }).to be true
      end
    end

    context 'when finding by category (--category)' do
      it 'returns all brains in a category' do
        options.categories = ['agent-systems']
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'combines multiple categories' do
        options.categories = %w[agent-systems agent-frameworks]
        paths = subject.find

        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs.length).to be > 5
      end
    end

    context 'when using --active flag' do
      it 'returns all high-activity brains' do
        options.active = true
        paths = subject.find

        expect(paths).not_to be_empty
        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs.length).to be >= 10
      end

      it 'includes known high-activity brains' do
        options.active = true
        paths = subject.find

        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs).to include('omi', 'agentic-os', 'anthropic-claude')
      end
    end

    context 'when controlling INDEX.md inclusion' do
      it 'includes INDEX.md files by default' do
        options.brain_names = ['omi']
        paths = subject.find

        expect(paths.any? { |p| p.end_with?('INDEX.md') }).to be true
      end

      it 'excludes INDEX.md when files_only is set' do
        options.brain_names = ['omi']
        options.include_index = false
        paths = subject.find

        expect(paths.none? { |p| p.end_with?('INDEX.md') }).to be true
      end
    end

    context 'when combining query types' do
      it 'combines --find and --category results' do
        options.brain_names = ['omi']
        options.categories = ['agent-frameworks']
        paths = subject.find

        brain_dirs = paths.map { |p| p.match(%r{brains/([^/]+)})&.[](1) }.uniq
        expect(brain_dirs).to include('omi')
        expect(brain_dirs.length).to be > 1
      end
    end
  end

  describe '#find_meta' do
    context 'when using --active flag' do
      it 'returns an array of hashes' do
        options.active = true
        meta = subject.find_meta

        expect(meta).to be_an(Array)
        expect(meta.first).to be_a(Hash)
      end

      it 'includes expected metadata fields' do
        options.active = true
        entry = subject.find_meta.first

        expect(entry.keys).to include('name', 'category', 'activity_level', 'tags', 'file_count', 'status')
      end

      it 'returns only high-activity brains' do
        options.active = true
        meta = subject.find_meta

        expect(meta.all? { |e| e['activity_level'] == 'high' }).to be true
      end
    end

    context 'when finding by name' do
      it 'includes name and category in result' do
        options.brain_names = ['omi']
        entry = subject.find_meta.first

        expect(entry['name']).to eq('omi')
        expect(entry['category']).not_to be_nil
      end

      it 'includes tags array' do
        options.brain_names = ['omi']
        entry = subject.find_meta.first

        expect(entry['tags']).to be_an(Array)
      end
    end

    context 'when finding by category' do
      it 'returns all brains in category with metadata' do
        options.categories = ['agent-systems']
        meta = subject.find_meta

        expect(meta).not_to be_empty
        expect(meta.all? { |e| e['category'] == 'agent-systems' }).to be true
      end
    end

    context 'when no query specified' do
      it 'returns empty array' do
        expect(subject.find_meta).to eq([])
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
      options.categories = ['agent-systems']
      paths = subject.find

      expect(paths.length).to eq(paths.uniq.length)
    end

    it 'returns sorted paths' do
      options.active = true
      paths = subject.find

      expect(paths).to eq(paths.sort)
    end
  end
end
