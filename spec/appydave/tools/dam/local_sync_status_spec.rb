# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::LocalSyncStatus do
  include_context 'with vat filesystem and brands', brands: %w[appydave]

  describe '.enrich!' do
    let(:project_id) { 'b65-test-project' }
    let(:matched_projects) { { project_id => { file_count: 3, total_bytes: 1000 } } }

    context 'when project directory does not exist' do
      before { appydave_path } # ensure brand directory exists

      it 'sets :no_project status' do
        described_class.enrich!(matched_projects, 'appydave')
        expect(matched_projects[project_id][:local_status]).to eq(:no_project)
      end
    end

    context 'when project exists but no s3-staging directory' do
      before { FileUtils.mkdir_p(File.join(appydave_path, project_id)) }

      it 'sets :no_files status' do
        described_class.enrich!(matched_projects, 'appydave')
        expect(matched_projects[project_id][:local_status]).to eq(:no_files)
      end
    end

    context 'when s3-staging has matching file count' do
      before do
        staging = File.join(appydave_path, project_id, 's3-staging')
        FileUtils.mkdir_p(staging)
        3.times { |i| FileUtils.touch(File.join(staging, "file#{i}.mp4")) }
      end

      it 'sets :synced status' do
        described_class.enrich!(matched_projects, 'appydave')
        expect(matched_projects[project_id][:local_status]).to eq(:synced)
      end
    end
  end

  describe '.format' do
    it 'formats :synced' do
      expect(described_class.format(:synced, 3, 3)).to eq('✓ Synced')
    end

    it 'formats :no_files' do
      expect(described_class.format(:no_files, 0, 3)).to eq('⚠ None')
    end

    it 'formats :partial' do
      expect(described_class.format(:partial, 2, 3)).to eq('⚠ 2/3')
    end

    it 'formats :no_project' do
      expect(described_class.format(:no_project, nil, 3)).to eq('✗ Missing')
    end
  end
end
