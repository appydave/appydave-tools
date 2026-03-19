# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Appydave::Tools::Dam::S3ScanCommand do
  include_context 'with vat filesystem and brands', brands: %w[appydave]

  let(:scanner) { described_class.new }
  let(:brand_key) { 'appydave' }
  let(:mock_s3_scanner) { instance_double(Appydave::Tools::Dam::S3Scanner) }

  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:mock_brand_aws) do
    instance_double('BrandAws', s3_bucket: 'test-bucket', s3_prefix: 'test-prefix/', region: 'ap-southeast-2')
  end
  let(:mock_brand_info_appydave) do
    instance_double('BrandInfo', key: 'appydave', aws: mock_brand_aws)
  end
  let(:mock_brands_config) do
    cfg = instance_double(Appydave::Tools::Configuration::Models::BrandsConfig)
    allow(cfg).to receive(:get_brand).with(brand_key).and_return(mock_brand_info_appydave)
    allow(cfg).to receive(:brands).and_return([mock_brand_info_appydave])
    cfg
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:s3_result) do
    { 'b65-test-project' => { file_count: 3, total_bytes: 1_500_000, last_modified: '2025-01-01T00:00:00Z' } }
  end

  let(:manifest_path) { File.join(appydave_path, 'projects.json') }

  let(:base_manifest) do
    {
      config: { last_updated: Time.now.utc.iso8601, note: 'test' },
      projects: [{ id: 'b65-test-project', storage: { s3: {} } }]
    }
  end

  before do
    # Ensure @configurations is initialized before stubbing brands
    Appydave::Tools::Configuration::Config.configure
    allow(Appydave::Tools::Dam::S3Scanner).to receive(:new).with(brand_key).and_return(mock_s3_scanner)
    allow(Appydave::Tools::Configuration::Config).to receive(:configure)
    allow(Appydave::Tools::Configuration::Config).to receive(:brands).and_return(mock_brands_config)
    allow(Appydave::Tools::Dam::Config).to receive(:expand_brand).with(brand_key).and_return('v-appydave')
    allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with(brand_key).and_return(appydave_path)
    allow(Appydave::Tools::Dam::Config).to receive(:project_path).with(brand_key, 'b65-test-project').and_return(File.join(appydave_path, 'b65-test-project'))
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project', 's3-staging'))
    allow(scanner).to receive(:puts)
    allow(scanner).to receive(:print)
  end

  describe '#scan_single' do
    context 'when manifest exists and S3 returns results' do
      before do
        File.write(manifest_path, JSON.generate(base_manifest))
        allow(mock_s3_scanner).to receive(:scan_all_projects).and_return(s3_result)
      end

      it 'writes updated s3 data into the manifest file' do
        scanner.scan_single(brand_key)
        updated = JSON.parse(File.read(manifest_path), symbolize_names: true)
        project = updated[:projects].find { |p| p[:id] == 'b65-test-project' }
        expect(project).not_to be_nil
        expect(project[:storage][:s3]).to include(
          file_count: 3,
          total_bytes: 1_500_000,
          last_modified: '2025-01-01T00:00:00Z'
        )
      end

      it 'calls LocalSyncStatus.enrich! with matched projects after writing manifest' do
        allow(Appydave::Tools::Dam::LocalSyncStatus).to receive(:enrich!).and_call_original
        scanner.scan_single(brand_key)
        expect(Appydave::Tools::Dam::LocalSyncStatus).to have_received(:enrich!)
          .with({ 'b65-test-project' => s3_result['b65-test-project'] }, brand_key)
      end
    end

    context 'when manifest not found' do
      before do
        allow(mock_s3_scanner).to receive(:scan_all_projects).and_return(s3_result)
      end

      it 'raises ConfigurationError with Manifest not found message' do
        expect { scanner.scan_single(brand_key) }
          .to raise_error(Appydave::Tools::Dam::ConfigurationError, /Manifest not found/)
      end
    end

    context 'when S3 returns empty results' do
      before do
        allow(mock_s3_scanner).to receive(:scan_all_projects).and_return({})
      end

      it 'returns early without raising' do
        expect { scanner.scan_single(brand_key) }.not_to raise_error
      end

      it 'does not write a manifest file' do
        scanner.scan_single(brand_key)
        expect(File.exist?(manifest_path)).to be false
      end
    end

    context 'when S3 has orphaned projects' do
      before do
        File.write(manifest_path, JSON.generate(base_manifest))
        allow(mock_s3_scanner).to receive(:scan_all_projects).and_return(
          'b65-test-project' => { file_count: 3, total_bytes: 1_500_000, last_modified: '2025-01-01T00:00:00Z' },
          'b99-orphan' => { file_count: 2, total_bytes: 500_000, last_modified: '2025-01-02T00:00:00Z' }
        )
      end

      it 'runs without error when orphaned projects are present' do
        expect { scanner.scan_single(brand_key) }.not_to raise_error
      end

      it 'still updates the manifest for the matched project' do
        scanner.scan_single(brand_key)
        updated = JSON.parse(File.read(manifest_path), symbolize_names: true)
        project = updated[:projects].find { |p| p[:id] == 'b65-test-project' }
        expect(project[:storage][:s3]).to include(
          file_count: 3,
          total_bytes: 1_500_000,
          last_modified: '2025-01-01T00:00:00Z'
        )
      end
    end
  end

  describe '#scan_all' do
    # rubocop:disable RSpec/VerifiedDoubleReference
    let(:mock_brand_info_voz) { instance_double('BrandInfo', key: 'voz') }
    # rubocop:enable RSpec/VerifiedDoubleReference

    context 'when one brand fails' do
      before do
        allow(mock_brands_config).to receive(:brands).and_return([mock_brand_info_appydave, mock_brand_info_voz])
        allow(scanner).to receive(:scan_single).with('appydave')
        allow(scanner).to receive(:scan_single).with('voz').and_raise(StandardError, 'voz failed')
      end

      it 'does not re-raise the per-brand failure' do
        expect { scanner.scan_all }.not_to raise_error
      end

      it 'calls scan_single for each brand' do
        scanner.scan_all
        expect(scanner).to have_received(:scan_single).with('appydave')
        expect(scanner).to have_received(:scan_single).with('voz')
      end
    end
  end
end
