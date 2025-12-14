# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Config do
  include_context 'with jump filesystem'

  describe '#initialize' do
    it 'loads config from file' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)

      expect(config.locations.size).to eq(1)
      expect(config.locations.first.key).to eq('ad-tools')
    end

    it 'creates default config if file does not exist' do
      config = described_class.new(config_path: File.join(temp_folder, 'nonexistent.json'))

      expect(config.locations).to be_empty
      expect(config.meta['version']).to eq('1.0')
    end
  end

  describe '#locations' do
    it 'returns array of Location objects' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)

      expect(config.locations.first).to be_a(Appydave::Tools::Jump::Location)
    end
  end

  describe '#brands' do
    it 'returns brand definitions' do
      data = full_config(brands: JumpTestLocations.sample_brands)
      create_test_config(data)

      config = described_class.new(config_path: config_path)

      expect(config.brands['appydave']['aliases']).to include('ad')
    end
  end

  describe '#find' do
    it 'finds location by key' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools, JumpTestLocations.flivideo]))

      config = described_class.new(config_path: config_path)
      location = config.find('ad-tools')

      expect(location).not_to be_nil
      expect(location.key).to eq('ad-tools')
    end

    it 'returns nil for unknown key' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)

      expect(config.find('unknown')).to be_nil
    end
  end

  describe '#key_exists?' do
    it 'returns true for existing key' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)

      expect(config.key_exists?('ad-tools')).to be true
    end

    it 'returns false for unknown key' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)

      expect(config.key_exists?('unknown')).to be false
    end
  end

  describe '#add' do
    it 'adds new location' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)
      config.add(key: 'new-project', path: '~/dev/new-project')

      expect(config.locations.size).to eq(1)
      expect(config.find('new-project')).not_to be_nil
    end

    it 'raises error for duplicate key' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)

      expect do
        config.add(key: 'ad-tools', path: '~/other/path')
      end.to raise_error(ArgumentError, /already exists/)
    end

    it 'raises error for invalid location' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)

      expect do
        config.add(key: 'Invalid', path: 'relative/path')
      end.to raise_error(ArgumentError, /Invalid location/)
    end
  end

  describe '#update' do
    it 'updates existing location' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)
      config.update('ad-tools', description: 'Updated description')

      location = config.find('ad-tools')
      expect(location.description).to eq('Updated description')
    end

    it 'raises error for unknown key' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)

      expect do
        config.update('unknown', description: 'test')
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#remove' do
    it 'removes existing location' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)
      config.remove('ad-tools')

      expect(config.locations).to be_empty
    end

    it 'raises error for unknown key' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)

      expect do
        config.remove('unknown')
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#save' do
    it 'persists changes to file' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)
      config.add(key: 'new-project', path: '~/dev/project')
      config.save

      # Reload and verify
      reloaded = described_class.new(config_path: config_path)
      expect(reloaded.find('new-project')).not_to be_nil
    end

    it 'creates backup before saving' do
      create_test_config(minimal_config(locations: []))

      config = described_class.new(config_path: config_path)
      config.save

      backups = Dir.glob("#{config_path}.backup.*")
      expect(backups).not_to be_empty
    end
  end

  describe '#info' do
    it 'returns config information' do
      create_test_config(minimal_config(locations: [JumpTestLocations.ad_tools]))

      config = described_class.new(config_path: config_path)
      info = config.info

      expect(info[:exists]).to be true
      expect(info[:location_count]).to eq(1)
      expect(info[:config_path]).to eq(config_path)
    end
  end
end
