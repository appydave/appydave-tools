# frozen_string_literal: true

RSpec.describe Appydave::Tools::BrainContextOptions do
  let(:temp_folder) { Dir.mktmpdir }
  let(:settings_file) { File.join(temp_folder, 'settings.json') }
  let(:settings_data) { {} }

  before do
    # Write settings file BEFORE Config registers SettingsConfig.new so the
    # newly created instance reads the correct file content.
    File.write(settings_file, settings_data.to_json)
    Appydave::Tools::Configuration::Config.reset
    Appydave::Tools::Configuration::Config.configure do |c|
      c.config_path = temp_folder
      c.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
    end
  end

  after do
    Appydave::Tools::Configuration::Config.reset
    FileUtils.remove_entry(temp_folder)
  end

  describe '#brains_root' do
    context 'when brains-root-path is not configured' do
      let(:settings_data) { {} }

      it 'falls back to the default path' do
        options = described_class.new
        expect(options.brains_root).to eq(File.expand_path('~/dev/ad/brains'))
      end
    end

    context 'when brains-root-path is configured' do
      let(:settings_data) { { 'brains-root-path' => '/custom/brains' } }

      it 'uses the configured path' do
        options = described_class.new
        expect(options.brains_root).to eq('/custom/brains')
      end
    end

    context 'when brains-root-path uses tilde expansion' do
      let(:settings_data) { { 'brains-root-path' => '~/my-brains' } }

      it 'expands the tilde' do
        options = described_class.new
        expect(options.brains_root).to eq(File.expand_path('~/my-brains'))
        expect(options.brains_root).not_to include('~')
      end
    end

    context 'when brains-root-path is an empty string' do
      let(:settings_data) { { 'brains-root-path' => '' } }

      it 'falls back to the default path' do
        options = described_class.new
        expect(options.brains_root).to eq(File.expand_path('~/dev/ad/brains'))
      end
    end

    it 'is overridable directly' do
      options = described_class.new
      options.instance_variable_set(:@brains_root, '/override/path')
      expect(options.brains_root).to eq('/override/path')
    end
  end

  describe '#omi_dir' do
    context 'when omi-directory-path is not configured' do
      let(:settings_data) { {} }

      it 'falls back to the default path' do
        options = described_class.new
        expect(options.omi_dir).to eq(File.expand_path('~/dev/raw-intake/omi'))
      end
    end

    context 'when omi-directory-path is configured' do
      let(:settings_data) { { 'omi-directory-path' => '/custom/omi' } }

      it 'uses the configured path' do
        options = described_class.new
        expect(options.omi_dir).to eq('/custom/omi')
      end
    end

    context 'when omi-directory-path uses tilde expansion' do
      let(:settings_data) { { 'omi-directory-path' => '~/dev/omi-data' } }

      it 'expands the tilde' do
        options = described_class.new
        expect(options.omi_dir).to eq(File.expand_path('~/dev/omi-data'))
        expect(options.omi_dir).not_to include('~')
      end
    end

    context 'when omi-directory-path is blank' do
      let(:settings_data) { { 'omi-directory-path' => '   ' } }

      it 'falls back to the default path' do
        options = described_class.new
        expect(options.omi_dir).to eq(File.expand_path('~/dev/raw-intake/omi'))
      end
    end

    it 'is overridable via the attr_accessor setter' do
      options = described_class.new
      options.omi_dir = '/override/omi'
      expect(options.omi_dir).to eq('/override/omi')
    end
  end

  describe '#brains_index_path' do
    context 'when brains-root-path is configured' do
      let(:settings_data) { { 'brains-root-path' => '/custom/brains' } }

      it 'builds the index path relative to configured brains_root' do
        options = described_class.new
        expect(options.brains_index_path).to eq('/custom/brains/audit/brains-index.json')
      end
    end
  end

  describe 'both paths configured together' do
    let(:settings_data) { { 'brains-root-path' => '/lars/brains', 'omi-directory-path' => '/lars/omi' } }

    it 'reads both independently' do
      options = described_class.new
      expect(options.brains_root).to eq('/lars/brains')
      expect(options.omi_dir).to eq('/lars/omi')
    end
  end
end
