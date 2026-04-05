# frozen_string_literal: true

RSpec.describe Appydave::Tools::AppContext::GlobsLoader do
  let(:fixtures_path) { File.expand_path('../../../fixtures/app_context', __dir__) }
  let(:sample_project_path) { File.join(fixtures_path, 'sample_project') }

  describe 'with a standard context.globs.json' do
    subject(:loader) { described_class.new(sample_project_path) }

    it 'is available' do
      expect(loader.available?).to be true
    end

    it 'reads the project name' do
      expect(loader.project_name).to eq('sample-app')
    end

    it 'reads the pattern' do
      expect(loader.pattern).to eq('rvets')
    end

    it 'loads glob categories' do
      expect(loader.globs.keys).to include('docs', 'services', 'routes', 'components', 'context')
    end

    it 'loads aliases' do
      expect(loader.aliases.keys).to include('backend', 'frontend', 'api')
    end

    it 'loads composites' do
      expect(loader.composites.keys).to include('understand', 'codebase', 'full')
    end
  end

  describe '#available_names' do
    subject(:loader) { described_class.new(sample_project_path) }

    it 'includes globs, aliases, and composites' do
      names = loader.available_names
      types = names.map { |n| n[:type] }.uniq.sort

      expect(types).to eq(%w[alias composite glob])
    end

    it 'labels each name with its type' do
      names = loader.available_names
      backend = names.find { |n| n[:name] == 'backend' }

      expect(backend[:type]).to eq('alias')
    end
  end

  describe '#resolve' do
    subject(:loader) { described_class.new(sample_project_path) }

    context 'with tier 1: direct glob name' do
      it 'returns the raw glob patterns' do
        patterns = loader.resolve('services')

        expect(patterns).to eq(['server/src/services/**/*.ts'])
      end
    end

    context 'with tier 2: alias' do
      it 'resolves alias to constituent globs' do
        patterns = loader.resolve('backend')

        expect(patterns).to include('server/src/services/**/*.ts')
        expect(patterns).to include('server/src/routes/**/*.ts')
      end

      it 'resolves api alias to routes' do
        patterns = loader.resolve('api')

        expect(patterns).to eq(['server/src/routes/**/*.ts'])
      end
    end

    context 'with tier 3: composite' do
      it 'resolves composite to constituent globs' do
        patterns = loader.resolve('understand')

        expect(patterns).to include('CLAUDE.md', 'CONTEXT.md')
        expect(patterns).to include('docs/**/*.md')
        expect(patterns).to include('*.config.*')
      end

      it 'resolves full composite to all globs' do
        patterns = loader.resolve('full')

        expect(patterns.length).to be >= 7
        expect(patterns).to include('docs/**/*.md', 'server/src/services/**/*.ts')
      end
    end

    context 'with tier 4: substring fallback' do
      it 'matches substring of a known name' do
        patterns = loader.resolve('back')

        expect(patterns).to include('server/src/services/**/*.ts')
      end
    end

    context 'when name not found' do
      it 'returns empty array' do
        expect(loader.resolve('nonexistent')).to eq([])
      end
    end

    context 'with case insensitivity' do
      it 'resolves regardless of case' do
        patterns = loader.resolve('BACKEND')

        expect(patterns).to include('server/src/services/**/*.ts')
      end
    end
  end

  describe '#expand' do
    subject(:loader) { described_class.new(sample_project_path) }

    it 'expands direct glob to absolute file paths' do
      paths = loader.expand(['services'])

      expect(paths).not_to be_empty
      expect(paths.all? { |p| p.start_with?('/') }).to be true
      expect(paths.all? { |p| p.include?('services') }).to be true
      expect(paths.all? { |p| File.exist?(p) }).to be true
    end

    it 'expands alias to file paths from all constituents' do
      paths = loader.expand(['backend'])

      service_paths = paths.select { |p| p.include?('services') }
      route_paths = paths.select { |p| p.include?('routes') }

      expect(service_paths).not_to be_empty
      expect(route_paths).not_to be_empty
    end

    it 'expands composite to file paths' do
      paths = loader.expand(['understand'])

      expect(paths.any? { |p| p.end_with?('CLAUDE.md') }).to be true
      expect(paths.any? { |p| p.include?('docs') }).to be true
    end

    it 'deduplicates and sorts results' do
      paths = loader.expand(%w[services backend])

      expect(paths.length).to eq(paths.uniq.length)
      expect(paths).to eq(paths.sort)
    end

    it 'returns only files, not directories' do
      paths = loader.expand(['docs'])

      expect(paths.all? { |p| File.file?(p) }).to be true
    end

    it 'handles multiple names' do
      paths = loader.expand(%w[docs context])

      expect(paths.any? { |p| p.include?('docs') }).to be true
      expect(paths.any? { |p| p.end_with?('CLAUDE.md') }).to be true
    end
  end

  describe 'when context.globs.json is missing' do
    subject(:loader) { described_class.new('/tmp/nonexistent-project') }

    it 'is not available' do
      expect(loader.available?).to be false
    end

    it 'returns empty globs' do
      expect(loader.globs).to eq({})
    end

    it 'returns empty on resolve' do
      expect(loader.resolve('docs')).to eq([])
    end

    it 'returns empty on expand' do
      expect(loader.expand(['docs'])).to eq([])
    end
  end

  describe 'when context.globs.json has no aliases or composites' do
    subject(:loader) do
      # Use a temp dir with minimal globs file
      dir = Dir.mktmpdir
      FileUtils.cp(File.join(fixtures_path, 'context.globs.minimal.json'),
                   File.join(dir, 'context.globs.json'))
      described_class.new(dir)
    end

    it 'is available' do
      expect(loader.available?).to be true
    end

    it 'has empty aliases' do
      expect(loader.aliases).to eq({})
    end

    it 'has empty composites' do
      expect(loader.composites).to eq({})
    end

    it 'resolves direct glob names' do
      patterns = loader.resolve('docs')

      expect(patterns).to eq(['docs/**/*.md'])
    end
  end

  describe 'when context.globs.json has empty globs' do
    subject(:loader) do
      dir = Dir.mktmpdir
      FileUtils.cp(File.join(fixtures_path, 'context.globs.empty.json'),
                   File.join(dir, 'context.globs.json'))
      described_class.new(dir)
    end

    it 'is available but has no glob categories' do
      expect(loader.available?).to be true
      expect(loader.globs).to eq({})
    end

    it 'returns empty available_names' do
      expect(loader.available_names).to eq([])
    end
  end

  describe 'when context.globs.json is malformed' do
    subject(:loader) do
      dir = Dir.mktmpdir
      File.write(File.join(dir, 'context.globs.json'), '{ invalid json }}}')
      described_class.new(dir)
    end

    it 'is not available' do
      expect(loader.available?).to be false
    end
  end
end
