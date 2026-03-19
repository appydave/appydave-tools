# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::S3ArgParser do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  let(:brands_data) do
    {
      'brands' => {
        'appydave' => {
          'name' => 'AppyDave',
          'shortcut' => 'ad',
          'type' => 'owned',
          'youtube_channels' => [],
          'team' => [],
          'locations' => { 'video_projects' => appydave_path, 'ssd_backup' => '/tmp/ssd' },
          'aws' => { 'profile' => 'appydave', 'region' => 'us-east-1', 's3_bucket' => 'test-bucket', 's3_prefix' => 'staging/v-appydave/' },
          'settings' => { 's3_cleanup_days' => 90 }
        },
        'voz' => {
          'name' => 'VOZ',
          'shortcut' => 'voz',
          'type' => 'client',
          'youtube_channels' => [],
          'team' => [],
          'locations' => { 'video_projects' => voz_path, 'ssd_backup' => '/tmp/ssd' },
          'aws' => { 'profile' => 'voz', 'region' => 'us-east-1', 's3_bucket' => 'test-bucket', 's3_prefix' => 'staging/v-voz/' },
          'settings' => { 's3_cleanup_days' => 90 }
        }
      },
      'users' => {}
    }
  end

  let(:brands_config) do
    Appydave::Tools::Configuration::Models::BrandsConfig.new.tap do |cfg|
      cfg.instance_variable_set(:@data, brands_data)
    end
  end

  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project'))
    allow(Appydave::Tools::Configuration::Config).to receive(:configure)
    allow(Appydave::Tools::Configuration::Config).to receive(:brands).and_return(brands_config)
  end

  describe '.valid_brand?' do
    it 'returns true for known brand' do
      expect(described_class.valid_brand?('appydave')).to be true
    end

    it 'returns false for unknown brand' do
      expect(described_class.valid_brand?('unknown')).to be false
    end
  end

  describe '.parse_s3' do
    context 'with brand and project args' do
      it 'returns brand and project keys' do
        result = described_class.parse_s3(%w[appydave b65-test-project], 's3-up')
        expect(result[:brand]).to eq('appydave')
        expect(result[:project]).to eq('b65-test-project')
      end

      it 'defaults dry_run to false' do
        result = described_class.parse_s3(%w[appydave b65-test-project], 's3-up')
        expect(result[:dry_run]).to be false
      end

      it 'sets dry_run when flag present' do
        result = described_class.parse_s3(%w[appydave b65-test-project --dry-run], 's3-up')
        expect(result[:dry_run]).to be true
      end
    end
  end

  describe '.parse_discover' do
    it 'returns brand_key and project_id' do
      result = described_class.parse_discover(%w[appydave b65-test-project])
      expect(result[:brand_key]).to eq('appydave')
      expect(result[:project_id]).to eq('b65-test-project')
    end

    it 'sets shareable flag when present' do
      result = described_class.parse_discover(%w[appydave b65-test-project --shareable])
      expect(result[:shareable]).to be true
    end
  end
end
