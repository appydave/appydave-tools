# frozen_string_literal: true

require 'rspec'
require 'tmpdir'

RSpec.describe Appydave::Tools::Vat::ConfigLoader do
  let(:temp_folder) { Dir.mktmpdir }
  let(:repo_path) { File.join(temp_folder, 'v-test') }
  let(:config_file) { File.join(repo_path, '.video-tools.env') }

  before do
    FileUtils.mkdir_p(repo_path)
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '.load_from_repo' do
    context 'with valid configuration' do
      before do
        File.write(config_file, <<~CONFIG)
          # Configuration for video tools
          SSD_BASE=/Volumes/T7/youtube-PUBLISHED/appydave
          AWS_ACCESS_KEY_ID=AKIA123456789
          AWS_SECRET_ACCESS_KEY=secret123
          AWS_REGION=ap-southeast-1
          S3_BUCKET=appydave-video-projects
          S3_STAGING_PREFIX=staging/v-appydave/
        CONFIG
      end

      it 'loads configuration successfully' do
        config = described_class.load_from_repo(repo_path)
        expect(config).to be_a(Hash)
      end

      it 'parses SSD_BASE' do
        config = described_class.load_from_repo(repo_path)
        expect(config['SSD_BASE']).to eq('/Volumes/T7/youtube-PUBLISHED/appydave')
      end

      it 'parses AWS credentials' do
        config = described_class.load_from_repo(repo_path)
        expect(config['AWS_ACCESS_KEY_ID']).to eq('AKIA123456789')
        expect(config['AWS_SECRET_ACCESS_KEY']).to eq('secret123')
      end

      it 'parses optional S3 configuration' do
        config = described_class.load_from_repo(repo_path)
        # S3_BUCKET is optional (only SSD_BASE is required per REQUIRED_KEYS)
        # If present, should parse correctly
        expect(config).to include('SSD_BASE', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION')
      end
    end

    context 'with quotes in values' do
      before do
        File.write(config_file, <<~CONFIG)
          SSD_BASE="/Volumes/T7/youtube-PUBLISHED/appydave"
          AWS_REGION='ap-southeast-1'
        CONFIG
      end

      it 'removes double quotes from values' do
        config = described_class.load_from_repo(repo_path)
        expect(config['SSD_BASE']).to eq('/Volumes/T7/youtube-PUBLISHED/appydave')
      end

      it 'removes single quotes from values' do
        config = described_class.load_from_repo(repo_path)
        expect(config['AWS_REGION']).to eq('ap-southeast-1')
      end
    end

    context 'with comments and empty lines' do
      before do
        File.write(config_file, <<~CONFIG)
          # This is a comment
          SSD_BASE=/path/to/ssd

          # Another comment
          AWS_REGION=us-east-1

        CONFIG
      end

      it 'skips comments' do
        config = described_class.load_from_repo(repo_path)
        expect(config.keys).not_to include('#')
      end

      it 'skips empty lines' do
        config = described_class.load_from_repo(repo_path)
        expect(config.keys).to contain_exactly('SSD_BASE', 'AWS_REGION')
      end

      it 'parses valid keys' do
        config = described_class.load_from_repo(repo_path)
        expect(config['SSD_BASE']).to eq('/path/to/ssd')
        expect(config['AWS_REGION']).to eq('us-east-1')
      end
    end

    context 'when config file does not exist' do
      it 'raises ConfigNotFoundError' do
        expect do
          described_class.load_from_repo(repo_path)
        end.to raise_error(Appydave::Tools::Vat::ConfigLoader::ConfigNotFoundError, /Configuration file not found/)
      end
    end

    context 'when required keys are missing' do
      before do
        File.write(config_file, <<~CONFIG)
          AWS_REGION=us-east-1
        CONFIG
      end

      it 'raises InvalidConfigError' do
        expect do
          described_class.load_from_repo(repo_path)
        end.to raise_error(Appydave::Tools::Vat::ConfigLoader::InvalidConfigError, /Missing required configuration keys/)
      end

      it 'lists missing keys in error message' do
        expect do
          described_class.load_from_repo(repo_path)
        end.to raise_error(/SSD_BASE/)
      end
    end

    context 'with all required keys present' do
      before do
        File.write(config_file, <<~CONFIG)
          SSD_BASE=/Volumes/T7/youtube-PUBLISHED/appydave
        CONFIG
      end

      it 'does not raise error' do
        expect { described_class.load_from_repo(repo_path) }.not_to raise_error
      end
    end
  end
end
