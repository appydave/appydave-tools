# frozen_string_literal: true

RSpec.describe Appydave::Tools::AppContext::AppQuery do
  subject(:query) { described_class.new(options, jump_config: jump_config) }

  let(:fixtures_path) { File.expand_path('../../../fixtures/app_context', __dir__) }
  let(:sample_project_path) { File.join(fixtures_path, 'sample_project') }
  let(:options) { Appydave::Tools::AppContext::Options.new }

  # Build a Jump::Config from the test fixture, with the sample_project_path injected
  let(:jump_config) do
    fixture_path = File.join(fixtures_path, 'locations.json')
    raw = JSON.parse(File.read(fixture_path))
    # Replace placeholder with actual path
    raw['locations'].each do |loc|
      loc['path'] = sample_project_path if loc['path'] == 'SAMPLE_PROJECT_PATH'
    end

    # Write to temp file so Jump::Config can load it
    temp_file = File.join(Dir.mktmpdir, 'locations.json')
    File.write(temp_file, raw.to_json)
    Appydave::Tools::Jump::Config.new(config_path: temp_file)
  end

  describe '#find' do
    context 'when no query is specified' do
      it 'returns empty array' do
        expect(query.find).to eq([])
      end
    end

    context 'when finding by exact app key' do
      before do
        options.app_names = ['sample-app']
        options.glob_names = ['services']
      end

      it 'returns file paths' do
        paths = query.find

        expect(paths).not_to be_empty
        expect(paths.all? { |p| p.include?('services') }).to be true
      end

      it 'returns absolute paths' do
        paths = query.find

        expect(paths.all? { |p| p.start_with?('/') }).to be true
      end

      it 'returns existing files' do
        paths = query.find

        expect(paths.all? { |p| File.exist?(p) }).to be true
      end

      it 'returns sorted paths' do
        paths = query.find

        expect(paths).to eq(paths.sort)
      end

      it 'returns unique paths' do
        paths = query.find

        expect(paths.length).to eq(paths.uniq.length)
      end
    end

    context 'when finding by jump alias' do
      before do
        options.app_names = ['jsample']
        options.glob_names = ['docs']
      end

      it 'resolves the app and returns file paths' do
        paths = query.find

        expect(paths).not_to be_empty
        expect(paths.any? { |p| p.include?('docs') }).to be true
      end
    end

    context 'when finding by substring' do
      before do
        options.app_names = ['sample']
        options.glob_names = ['routes']
      end

      it 'resolves via substring match' do
        paths = query.find

        expect(paths).not_to be_empty
        expect(paths.all? { |p| p.include?('routes') }).to be true
      end
    end

    context 'when using alias glob names' do
      before do
        options.app_names = ['sample-app']
        options.glob_names = ['backend']
      end

      it 'resolves alias to constituent file paths' do
        paths = query.find

        service_paths = paths.select { |p| p.include?('services') }
        route_paths = paths.select { |p| p.include?('routes') }

        expect(service_paths).not_to be_empty
        expect(route_paths).not_to be_empty
      end
    end

    context 'when using composite glob names' do
      before do
        options.app_names = ['sample-app']
        options.glob_names = ['understand']
      end

      it 'resolves composite to file paths' do
        paths = query.find

        expect(paths.any? { |p| p.end_with?('CLAUDE.md') }).to be true
        expect(paths.any? { |p| p.include?('docs') }).to be true
      end
    end

    context 'when app has no context.globs.json' do
      before do
        options.app_names = ['no-globs-app']
        options.glob_names = ['docs']
      end

      it 'returns empty array' do
        expect(query.find).to eq([])
      end
    end

    context 'when app is not found' do
      before do
        options.app_names = ['nonexistent-xyz']
        options.glob_names = ['docs']
      end

      it 'returns empty array' do
        expect(query.find).to eq([])
      end
    end

    context 'when no glob names specified' do
      before do
        options.app_names = ['sample-app']
      end

      it 'returns empty array' do
        expect(query.find).to eq([])
      end
    end

    context 'when using multiple glob names' do
      before do
        options.app_names = ['sample-app']
        options.glob_names = %w[docs services]
      end

      it 'returns combined results' do
        paths = query.find

        expect(paths.any? { |p| p.include?('docs') }).to be true
        expect(paths.any? { |p| p.include?('services') }).to be true
      end
    end
  end

  describe '#find_meta' do
    context 'when no query is specified' do
      it 'returns empty array' do
        expect(query.find_meta).to eq([])
      end
    end

    context 'with a valid app and glob query' do
      before do
        options.app_names = ['sample-app']
        options.glob_names = ['backend']
      end

      it 'returns an array of hashes' do
        meta = query.find_meta

        expect(meta).to be_an(Array)
        expect(meta.first).to be_a(Hash)
      end

      it 'includes expected metadata fields' do
        entry = query.find_meta.first

        expect(entry.keys).to include('app', 'path', 'pattern', 'matched_globs', 'resolved_from', 'file_count')
      end

      it 'reports the correct app key' do
        entry = query.find_meta.first

        expect(entry['app']).to eq('sample-app')
      end

      it 'reports the pattern type' do
        entry = query.find_meta.first

        expect(entry['pattern']).to eq('rvets')
      end

      it 'reports the resolved glob names' do
        entry = query.find_meta.first

        expect(entry['matched_globs']).to include('services', 'routes')
      end

      it 'reports resolution type' do
        entry = query.find_meta.first

        expect(entry['resolved_from']).to include('alias')
      end

      it 'reports a positive file count' do
        entry = query.find_meta.first

        expect(entry['file_count']).to be > 0
      end
    end
  end

  describe '#list_globs' do
    it 'returns available glob names for an app' do
      names = query.list_globs('sample-app')

      expect(names).not_to be_empty

      glob_names = names.select { |n| n[:type] == 'glob' }.map { |n| n[:name] }
      expect(glob_names).to include('docs', 'services', 'routes')
    end

    it 'includes aliases and composites' do
      names = query.list_globs('sample-app')
      types = names.map { |n| n[:type] }.uniq.sort

      expect(types).to eq(%w[alias composite glob])
    end

    it 'returns empty for unknown app' do
      expect(query.list_globs('nonexistent-xyz')).to eq([])
    end

    it 'returns empty for app without globs file' do
      expect(query.list_globs('no-globs-app')).to eq([])
    end
  end

  describe '#list_apps' do
    it 'returns apps that have context.globs.json' do
      apps = query.list_apps

      keys = apps.map { |a| a['key'] }
      expect(keys).to include('sample-app')
      expect(keys).not_to include('no-globs-app')
    end

    it 'includes pattern and glob_count in results' do
      app = query.list_apps.find { |a| a['key'] == 'sample-app' }

      expect(app['pattern']).to eq('rvets')
      expect(app['glob_count']).to be > 0
    end
  end

  describe 'pattern-based cross-app queries' do
    before do
      options.pattern_filter = 'rvets'
      options.glob_names = ['services']
    end

    it 'finds apps matching the pattern' do
      paths = query.find

      expect(paths).not_to be_empty
      expect(paths.all? { |p| p.include?('services') }).to be true
    end

    it 'returns meta for all matching apps' do
      meta = query.find_meta

      expect(meta).not_to be_empty
      expect(meta.all? { |m| m['pattern'] == 'rvets' }).to be true
    end
  end
end
