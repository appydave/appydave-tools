# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::ExampleInstaller do
  let(:target_dir) { Dir.mktmpdir }
  let(:examples_dir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(target_dir)
    FileUtils.remove_entry(examples_dir)
  end

  # Build a test installer pointing at a temp examples directory
  def build_installer(target: target_dir)
    installer = described_class.new(target_path: target)
    # Point at our controlled examples dir for isolation
    allow(installer).to receive(:example_files).and_return(
      Dir.glob(File.join(examples_dir, '*.example.*')).sort
    )
    installer
  end

  def create_example(name, content = '{}')
    File.write(File.join(examples_dir, name), content)
  end

  describe '#available' do
    it 'returns target names (without .example segment)' do
      create_example('settings.example.json')
      create_example('locations.example.json')

      expect(build_installer.available).to contain_exactly('settings.json', 'locations.json')
    end

    it 'returns empty array when no examples exist' do
      expect(build_installer.available).to eq([])
    end
  end

  describe '#install' do
    context 'when no target files exist yet' do
      it 'installs all example files' do
        create_example('settings.example.json', '{"key":"value"}')
        create_example('locations.example.json', '{"locations":[]}')

        result = build_installer.install

        expect(result[:installed]).to contain_exactly('settings.json', 'locations.json')
        expect(result[:skipped]).to be_empty
      end

      it 'writes file content to the target directory' do
        create_example('settings.example.json', '{"video-projects-root":"~/dev/video"}')

        build_installer.install

        written = File.read(File.join(target_dir, 'settings.json'))
        expect(written).to include('video-projects-root')
      end
    end

    context 'when target files already exist' do
      before do
        create_example('settings.example.json', '{"new":"value"}')
        File.write(File.join(target_dir, 'settings.json'), '{"existing":"value"}')
      end

      it 'skips existing files' do
        result = build_installer.install

        expect(result[:skipped]).to eq(['settings.json'])
        expect(result[:installed]).to be_empty
      end

      it 'does not overwrite existing file content' do
        build_installer.install

        content = JSON.parse(File.read(File.join(target_dir, 'settings.json')))
        expect(content['existing']).to eq('value')
      end
    end

    context 'with a mix of new and existing files' do
      before do
        create_example('settings.example.json')
        create_example('locations.example.json')
        File.write(File.join(target_dir, 'settings.json'), '{}')
      end

      it 'installs new files and skips existing ones' do
        result = build_installer.install

        expect(result[:installed]).to eq(['locations.json'])
        expect(result[:skipped]).to eq(['settings.json'])
      end
    end

    it 'creates the target directory if it does not exist' do
      new_target = File.join(Dir.mktmpdir, 'nested', 'config')
      create_example('settings.example.json')

      installer = described_class.new(target_path: new_target)
      allow(installer).to receive(:example_files).and_return(
        Dir.glob(File.join(examples_dir, '*.example.*')).sort
      )
      installer.install

      expect(Dir.exist?(new_target)).to be true
      FileUtils.remove_entry(File.dirname(File.dirname(new_target)))
    end

    it 'returns empty installed and skipped when no examples exist' do
      result = build_installer.install

      expect(result[:installed]).to be_empty
      expect(result[:skipped]).to be_empty
    end
  end

  describe 'bundled examples' do
    it 'bundled examples directory exists' do
      expect(Dir.exist?(described_class::EXAMPLES_PATH)).to be true
    end

    it 'settings.example.json is present in bundled examples' do
      expect(File.exist?(File.join(described_class::EXAMPLES_PATH, 'settings.example.json'))).to be true
    end

    it 'locations.example.json is present in bundled examples' do
      expect(File.exist?(File.join(described_class::EXAMPLES_PATH, 'locations.example.json'))).to be true
    end

    it 'settings.example.json contains brains-root-path key' do
      content = JSON.parse(File.read(File.join(described_class::EXAMPLES_PATH, 'settings.example.json')))
      expect(content.key?('brains-root-path')).to be true
    end

    it 'settings.example.json contains omi-directory-path key' do
      content = JSON.parse(File.read(File.join(described_class::EXAMPLES_PATH, 'settings.example.json')))
      expect(content.key?('omi-directory-path')).to be true
    end

    it 'locations.example.json is valid JSON with a locations array' do
      content = JSON.parse(File.read(File.join(described_class::EXAMPLES_PATH, 'locations.example.json')))
      expect(content['locations']).to be_an(Array)
    end
  end
end
