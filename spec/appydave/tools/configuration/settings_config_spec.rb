# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::SettingsConfig do
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'settings.json') }
  let(:config_data) { { 'theme' => 'dark', 'language' => 'en' } }

  before do
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
    File.write(config_file, config_data.to_json)
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    it 'initializes with settings config file path and loads data' do
      settings_config = described_class.new

      expect(settings_config.config_path).to eq(config_file)
      expect(settings_config.data).to eq(config_data)
    end
  end

  describe '#set and #get' do
    let(:settings_config) { described_class.new }

    it 'sets and retrieves a configuration value' do
      settings_config.set('notification', 'on')
      expect(settings_config.get('notification')).to eq('on')
    end

    it 'retrieves the default value when the key does not exist' do
      expect(settings_config.get('nonexistent_key', 'default_value')).to eq('default_value')
    end

    it 'updates an existing configuration value' do
      settings_config.set('theme', 'light')
      expect(settings_config.get('theme')).to eq('light')
    end

    it 'persists changes to the configuration file' do
      settings_config.set('auto_update', 'enabled')
      settings_config.save

      # Reload the configuration to see if it persists
      reloaded_settings = described_class.new
      expect(reloaded_settings.get('auto_update')).to eq('enabled')
    end
  end
end
