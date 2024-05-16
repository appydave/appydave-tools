# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::ConfigBase do
  let(:config_name) { 'test_config' }
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, "#{config_name}.json") }
  let(:config_data) { { 'key' => 'value' } }

  before do
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    it 'initializes with the correct config file path and loads data' do
      File.write(config_file, config_data.to_json)

      config = described_class.new(config_name)

      expect(config.config_path).to eq(config_file)
      expect(config.data).to eq(config_data)
    end

    it 'handles missing config file by initializing data as empty hash' do
      config = described_class.new(config_name)

      expect(config.config_path).to eq(config_file)
      expect(config.data).to eq({})
    end
  end

  describe '#save' do
    it 'saves the current data to the config file' do
      config = described_class.new(config_name)
      config.instance_variable_set(:@data, config_data) # Directly set the data to bypass loading mechanism

      config.save

      expect(File.read(config_file)).to eq(JSON.pretty_generate(config_data))
    end
  end

  describe '#load' do
    context 'when the file exists' do
      it 'loads the data from the file' do
        File.write(config_file, config_data.to_json)
        config = described_class.new(config_name)

        expect(config.data).to eq(config_data)
      end
    end

    context 'when the file does not exist' do
      it 'returns an empty hash' do
        config = described_class.new(config_name)

        expect(config.data).to eq({})
      end
    end

    context 'when the file has invalid JSON' do
      it 'returns an empty hash on parse failure' do
        File.write(config_file, 'invalid json')
        config = described_class.new(config_name)

        expect(config.data).to eq({})
      end
    end
  end
end
