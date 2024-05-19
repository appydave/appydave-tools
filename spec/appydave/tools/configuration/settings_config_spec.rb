# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

RSpec.describe Appydave::Tools::Configuration::SettingsConfig do
  let(:settings) { described_class.new }
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'settings.json') }
  let(:config_data) { { 'theme' => 'dark', 'language' => 'en' } }

  before do
    Appydave::Tools::Configuration::Config.configure do |configure|
      configure.config_path = temp_folder
    end
    File.write(config_file, config_data.to_json)
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    describe '.name' do
      subject { settings.name }

      it { is_expected.to eq('Settings') }
    end

    describe '.config_name' do
      subject { settings.config_name }

      it { is_expected.to eq('settings') }
    end

    describe '.config_path' do
      subject { settings.config_path }

      it { is_expected.to eq(config_file) }
    end

    describe '.data' do
      subject { settings.data }

      it { is_expected.to eq(config_data) }
    end
  end

  describe '#set and #get' do
    let(:settings) { described_class.new }

    it 'sets and retrieves a configuration value' do
      settings.set('notification', 'on')
      expect(settings.get('notification')).to eq('on')
    end

    it 'retrieves the default value when the key does not exist' do
      expect(settings.get('nonexistent_key', 'default_value')).to eq('default_value')
    end

    it 'updates an existing configuration value' do
      settings.set('theme', 'light')
      expect(settings.get('theme')).to eq('light')
    end

    it 'persists changes to the configuration file' do
      settings.set('auto_update', 'enabled')
      settings.save

      # Reload the configuration to see if it persists
      reloaded_settings = described_class.new
      expect(reloaded_settings.get('auto_update')).to eq('enabled')
    end
  end
end
