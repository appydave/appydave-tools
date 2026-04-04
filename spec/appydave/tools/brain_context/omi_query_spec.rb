# frozen_string_literal: true

RSpec.describe Appydave::Tools::OmiQuery do
  subject { described_class.new(options) }

  let(:options) do
    opts = Appydave::Tools::BrainContextOptions.new
    opts.omi = true
    opts
  end

  before do
    skip 'OMI directory not found' unless Dir.exist?(options.omi_dir)
  end

  describe '#find' do
    context 'when no filters are specified' do
      it 'returns only enriched files by default' do
        paths = subject.find

        expect(paths).not_to be_empty
        expect(paths.length).to be < 200
      end

      it 'returns all files when enriched_only is disabled' do
        options.enriched_only = false
        paths = subject.find

        expect(paths.length).to be > 700
      end
    end

    context 'when filtering by routing (--routing)' do
      it 'returns files with matching routing' do
        options.omi_routings = ['brain-update']
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'supports multiple routing values' do
        options.omi_routings = %w[brain-update til]
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns empty for non-existent routing' do
        options.omi_routings = ['nonexistent-routing']
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when filtering by activity (--activity)' do
      it 'returns files with matching activity' do
        options.omi_activities = ['planning']
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'supports pipe-delimited activities' do
        options.omi_activities = %w[planning meeting]
        paths = subject.find

        expect(paths).not_to be_empty
      end
    end

    context 'when filtering by brain (--brain)' do
      it 'returns sessions mentioning the brain' do
        options.brain_names = ['agentic-os']
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns empty for non-matching brain' do
        options.brain_names = ['nonexistent-brain']
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when filtering by days (--days)' do
      it 'returns sessions from the last N days' do
        options.days = 30
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'sets date_from based on days' do
        options.days = 7
        subject.find

        expect(options.date_from).not_to be_nil
      end

      it 'returns empty when days is far in the future' do
        options.days = -365
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when limiting results (--limit)' do
      it 'caps results to the specified count' do
        options.limit = 5
        paths = subject.find

        expect(paths.length).to be <= 5
      end

      it 'returns the most recent files when limited' do
        unlimited_options = Appydave::Tools::BrainContextOptions.new
        unlimited_options.omi = true
        all_paths = described_class.new(unlimited_options).find

        options.limit = 3
        limited_paths = subject.find

        expect(limited_paths).to eq(all_paths.last(3))
      end
    end

    context 'with combined filters' do
      it 'intersects routing and days' do
        options.omi_routings = ['brain-update']
        options.days = 14
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'applies limit after other filters' do
        options.omi_routings = ['brain-update']
        options.limit = 5
        paths = subject.find

        expect(paths.length).to be <= 5
      end
    end
  end

  describe '#find_meta' do
    context 'with no filters' do
      it 'returns an array of hashes' do
        meta = subject.find_meta

        expect(meta).to be_an(Array)
        expect(meta.first).to be_a(Hash)
      end

      it 'includes expected metadata fields' do
        entry = subject.find_meta.first

        expect(entry.keys).to include('file', 'extraction_summary', 'matched_brains', 'activity', 'routing')
      end

      it 'includes entities fields' do
        entry = subject.find_meta.first

        expect(entry.keys).to include('entities_tools', 'entities_projects', 'entities_concepts')
      end
    end

    context 'with routing filter' do
      it 'returns only matching routing entries' do
        options.omi_routings = ['brain-update']
        meta = subject.find_meta

        expect(meta).not_to be_empty
        expect(meta.all? { |e| e['routing']&.include?('brain-update') }).to be true
      end
    end

    context 'with limit' do
      it 'respects limit on metadata results' do
        options.limit = 3
        meta = subject.find_meta

        expect(meta.length).to be <= 3
      end
    end

    context 'with brain filter' do
      it 'returns metadata for sessions mentioning the brain' do
        options.brain_names = ['agentic-os']
        meta = subject.find_meta

        expect(meta).not_to be_empty
        expect(meta.all? { |e| e['matched_brains'].include?('agentic-os') }).to be true
      end
    end
  end

  describe 'file paths' do
    it 'returns absolute paths' do
      options.omi_routings = ['brain-update']
      paths = subject.find

      expect(paths.all? { |p| p.start_with?('/') }).to be true
    end

    it 'returns sorted paths' do
      paths = subject.find

      expect(paths).to eq(paths.sort)
    end

    it 'all returned files exist on disk' do
      options.omi_routings = ['brain-update']
      paths = subject.find

      expect(paths.all? { |p| File.exist?(p) }).to be true
    end
  end
end
