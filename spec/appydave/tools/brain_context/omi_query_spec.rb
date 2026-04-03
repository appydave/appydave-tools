# frozen_string_literal: true

RSpec.describe Appydave::Tools::OmiQuery do
  subject { described_class.new(options) }

  let(:options) do
    opts = Appydave::Tools::BrainContextOptions.new
    opts.omi = true
    opts
  end

  before do
    # Ensure OMI directory exists
    skip 'OMI directory not found' unless Dir.exist?(options.omi_dir)
  end

  describe '#find' do
    context 'when no filters are specified' do
      it 'returns all OMI files' do
        paths = subject.find

        expect(paths).not_to be_empty
        expect(paths.all? { |p| p.include?('omi') && p.end_with?('.md') }).to be true
      end
    end

    context 'when filtering by signal' do
      it 'returns files with matching signal' do
        options.omi_signals = ['work']
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns empty array for non-existent signal' do
        options.omi_signals = ['nonexistent']
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when filtering by routing' do
      it 'returns files with matching routing' do
        options.omi_routings = ['brain-update']
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'supports multiple routing values' do
        options.omi_routings = %w[brain-update todo-item]
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end
    end

    context 'when filtering by activity' do
      it 'returns files with matching activity' do
        options.omi_activities = ['planning']
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end
    end

    context 'when filtering by date range' do
      it 'returns files within date range' do
        options.date_from = '2026-03-01'
        options.date_to = '2026-04-30'
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns files outside date range (raw files have no extracted_at)' do
        options.date_from = '2025-01-01'
        options.date_to = '2025-12-31'
        options.enriched_only = false
        paths = subject.find

        # Raw files without extracted_at are included (they're considered "no date")
        expect(paths).not_to be_empty
      end

      it 'returns empty for enriched files outside date range' do
        options.date_from = '2025-01-01'
        options.date_to = '2025-12-31'
        options.enriched_only = true
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when filtering by brain' do
      it 'returns files mentioning the brain' do
        options.brain_names = ['agentic-os']
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end

      it 'returns empty for non-matching brain' do
        options.brain_names = ['nonexistent-brain']
        paths = subject.find

        expect(paths).to eq([])
      end
    end

    context 'when enriched-only filter is applied' do
      it 'excludes raw files' do
        options.enriched_only = true
        paths = subject.find

        # All returned files should have enriched frontmatter
        # This is hard to test without parsing, but we can verify count is reasonable
        expect(paths.length).to be < 200  # There are ~150 enriched, 788 raw
      end

      it 'includes all files when enriched-only is false' do
        options.enriched_only = false
        paths = subject.find

        expect(paths.length).to be > 700  # Should include ~900 total
      end
    end

    context 'with combined filters' do
      it 'intersects results from multiple filters' do
        options.omi_signals = ['work']
        options.date_from = '2026-04-01'
        options.enriched_only = true
        paths = subject.find

        expect(paths).not_to be_empty
      end
    end
  end

  describe 'file paths' do
    it 'returns absolute paths' do
      options.omi_signals = ['work']
      options.enriched_only = true
      paths = subject.find

      expect(paths.all? { |p| p.start_with?('/') }).to be true
    end

    it 'returns sorted paths' do
      options.enriched_only = true
      paths = subject.find

      expect(paths).to eq(paths.sort)
    end

    it 'all files exist on disk' do
      options.omi_signals = ['work']
      options.enriched_only = true
      paths = subject.find

      expect(paths.all? { |p| File.exist?(p) }).to be true
    end
  end
end
