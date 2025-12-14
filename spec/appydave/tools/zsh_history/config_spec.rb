# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.describe Appydave::Tools::ZshHistory::Config do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, 'zsh_history') }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'uses default config path when none provided' do
      config = described_class.new
      expect(config.config_path).to eq(described_class::DEFAULT_CONFIG_PATH)
    end

    it 'uses provided config path' do
      config = described_class.new(config_path: config_path)
      expect(config.config_path).to eq(config_path)
    end

    it 'accepts profile parameter' do
      config = described_class.new(profile: 'test-profile')
      expect(config.profile_name).to eq('test-profile')
    end
  end

  describe '#configured?' do
    context 'when config directory does not exist' do
      it 'returns false' do
        config = described_class.new(config_path: config_path)
        expect(config.configured?).to be false
      end
    end

    context 'when config directory exists' do
      before { FileUtils.mkdir_p(config_path) }

      it 'returns true' do
        config = described_class.new(config_path: config_path)
        expect(config.configured?).to be true
      end
    end
  end

  describe '#available_profiles' do
    let(:config) { described_class.new(config_path: config_path) }

    context 'when no profiles exist' do
      before { FileUtils.mkdir_p(config_path) }

      it 'returns empty array' do
        expect(config.available_profiles).to eq([])
      end
    end

    context 'when profiles exist' do
      before do
        FileUtils.mkdir_p(File.join(config_path, 'profiles', 'profile-a'))
        FileUtils.mkdir_p(File.join(config_path, 'profiles', 'profile-b'))
      end

      it 'returns sorted list of profile names' do
        expect(config.available_profiles).to eq(%w[profile-a profile-b])
      end
    end
  end

  describe '#profile_exists?' do
    let(:config) { described_class.new(config_path: config_path, profile: 'my-profile') }

    context 'when profile does not exist' do
      before { FileUtils.mkdir_p(config_path) }

      it 'returns false' do
        expect(config.profile_exists?).to be false
      end
    end

    context 'when profile exists' do
      before do
        FileUtils.mkdir_p(File.join(config_path, 'profiles', 'my-profile'))
      end

      it 'returns true' do
        expect(config.profile_exists?).to be true
      end
    end
  end

  describe '#default_profile' do
    let(:config) { described_class.new(config_path: config_path) }

    context 'when config.txt does not exist' do
      before { FileUtils.mkdir_p(config_path) }

      it 'returns nil' do
        expect(config.default_profile).to be_nil
      end
    end

    context 'when config.txt has default_profile' do
      before do
        FileUtils.mkdir_p(config_path)
        File.write(File.join(config_path, 'config.txt'), "default_profile=crash-recovery\n")
      end

      it 'returns the profile name' do
        expect(config.default_profile).to eq('crash-recovery')
      end
    end

    context 'when config.txt has comments and blank lines' do
      before do
        FileUtils.mkdir_p(config_path)
        File.write(File.join(config_path, 'config.txt'), <<~CONFIG)
          # Comment

          default_profile=my-profile
        CONFIG
      end

      it 'parses correctly' do
        expect(config.default_profile).to eq('my-profile')
      end
    end
  end

  describe '#exclude_patterns' do
    context 'when no config exists' do
      let(:config) { described_class.new(config_path: config_path) }

      it 'returns nil (to fall back to defaults)' do
        expect(config.exclude_patterns).to be_nil
      end
    end

    context 'when base_exclude.txt exists' do
      before do
        FileUtils.mkdir_p(config_path)
        File.write(File.join(config_path, 'base_exclude.txt'), <<~PATTERNS)
          # Comment
          ^ls$
          ^cd$
        PATTERNS
      end

      let(:config) { described_class.new(config_path: config_path) }

      it 'loads patterns from file' do
        expect(config.exclude_patterns).to eq(['^ls$', '^cd$'])
      end
    end

    context 'when profile has exclude.txt' do
      before do
        FileUtils.mkdir_p(config_path)
        FileUtils.mkdir_p(File.join(config_path, 'profiles', 'test'))
        File.write(File.join(config_path, 'base_exclude.txt'), "^base$\n")
        File.write(File.join(config_path, 'profiles', 'test', 'exclude.txt'), "^profile$\n")
      end

      let(:config) { described_class.new(config_path: config_path, profile: 'test') }

      it 'combines base and profile patterns' do
        expect(config.exclude_patterns).to eq(['^base$', '^profile$'])
      end
    end
  end

  describe '#include_patterns' do
    context 'when no config exists' do
      let(:config) { described_class.new(config_path: config_path) }

      it 'returns nil (to fall back to defaults)' do
        expect(config.include_patterns).to be_nil
      end
    end

    context 'when profile has include.txt' do
      before do
        FileUtils.mkdir_p(File.join(config_path, 'profiles', 'test'))
        File.write(File.join(config_path, 'profiles', 'test', 'include.txt'), <<~PATTERNS)
          ^git commit
          ^docker
        PATTERNS
      end

      let(:config) { described_class.new(config_path: config_path, profile: 'test') }

      it 'loads patterns from profile' do
        expect(config.include_patterns).to eq(['^git commit', '^docker'])
      end
    end
  end

  describe '.create_default_config' do
    it 'creates config directory structure' do
      described_class.create_default_config(config_path)

      expect(Dir.exist?(config_path)).to be true
      expect(Dir.exist?(File.join(config_path, 'profiles', 'crash-recovery'))).to be true
    end

    it 'creates config.txt with default profile' do
      described_class.create_default_config(config_path)

      config_file = File.join(config_path, 'config.txt')
      expect(File.exist?(config_file)).to be true
      expect(File.read(config_file)).to include('default_profile=crash-recovery')
    end

    it 'creates base_exclude.txt' do
      described_class.create_default_config(config_path)

      expect(File.exist?(File.join(config_path, 'base_exclude.txt'))).to be true
    end

    it 'creates profile exclude.txt and include.txt' do
      described_class.create_default_config(config_path)

      profile_path = File.join(config_path, 'profiles', 'crash-recovery')
      expect(File.exist?(File.join(profile_path, 'exclude.txt'))).to be true
      expect(File.exist?(File.join(profile_path, 'include.txt'))).to be true
    end

    it 'does not overwrite existing files' do
      FileUtils.mkdir_p(config_path)
      File.write(File.join(config_path, 'config.txt'), 'custom content')

      described_class.create_default_config(config_path)

      expect(File.read(File.join(config_path, 'config.txt'))).to eq('custom content')
    end
  end
end
