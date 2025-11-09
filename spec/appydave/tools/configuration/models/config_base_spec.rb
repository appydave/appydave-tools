# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::Models::ConfigBase do
  # let(:config_name) { 'test_config' }
  let(:config) { described_class.new }
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'config-base.json') } # "#{config_name}.json") }
  let(:config_data) { { 'key' => 'value' } }

  before do
    Appydave::Tools::Configuration::Config.configure do |configure|
      configure.config_path = temp_folder
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    it 'initializes with the correct config file path and loads data' do
      File.write(config_file, config_data.to_json)

      expect(config.config_path).to eq(config_file)
      expect(config.data).to eq(config_data)
    end

    it 'handles missing config file by initializing data as empty hash' do
      expect(config.config_path).to eq(config_file)
      expect(config.data).to eq({})
    end
  end

  describe '#save' do
    it 'saves the current data to the config file' do
      config.instance_variable_set(:@data, config_data) # Directly set the data to bypass loading mechanism

      config.save

      expect(File.read(config_file)).to eq(JSON.pretty_generate(config_data))
    end

    context 'when config file already exists' do
      it 'creates a timestamped backup before saving' do
        # Create initial file
        File.write(config_file, { 'old' => 'data' }.to_json)

        # Update and save
        config.instance_variable_set(:@data, config_data)

        # Freeze time to predictable timestamp
        frozen_time = Time.new(2025, 11, 9, 20, 30, 15)
        allow(Time).to receive(:now).and_return(frozen_time)

        config.save

        # Check backup was created with timestamp
        expected_backup = "#{config_file}.backup.20251109-203015"
        expect(File.exist?(expected_backup)).to be true
        expect(File.read(expected_backup)).to eq({ 'old' => 'data' }.to_json)
      end

      it 'overwrites the original file with new data' do
        # Create initial file
        File.write(config_file, { 'old' => 'data' }.to_json)

        # Update and save
        config.instance_variable_set(:@data, config_data)
        config.save

        # Check original file has new data
        expect(File.read(config_file)).to eq(JSON.pretty_generate(config_data))
      end
    end

    context 'when config file does not exist' do
      it 'does not create a backup' do
        config.instance_variable_set(:@data, config_data)
        config.save

        # No backup files should exist
        backup_files = Dir.glob("#{config_file}.backup.*")
        expect(backup_files).to be_empty
      end
    end
  end

  describe '#load' do
    context 'when the file exists' do
      it 'loads the data from the file' do
        File.write(config_file, config_data.to_json)

        expect(config.data).to eq(config_data)
      end
    end

    context 'when the file does not exist' do
      it 'returns an empty hash' do
        expect(config.data).to eq({})
      end
    end

    context 'when the file has invalid JSON' do
      it 'returns an empty hash on parse failure' do
        File.write(config_file, 'invalid json')

        expect(config.data).to eq({})
      end
    end
  end
end
