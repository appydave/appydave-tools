# frozen_string_literal: true

require 'rspec'

# rubocop:disable RSpec/AnyInstance
RSpec.describe Appydave::Tools::Dam::Config do
  include_context 'with dam filesystem'

  describe '.projects_root' do
    context 'when settings.json has video-projects-root configured' do
      before do
        FileUtils.mkdir_p(projects_root)
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return(projects_root)
      end

      it 'returns configured path' do
        expect(described_class.projects_root).to eq(projects_root)
      end
    end

    context 'when video-projects-root is not configured' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return(nil)
      end

      it 'raises helpful error mentioning ad_config' do
        expect { described_class.projects_root }.to raise_error(RuntimeError, /VIDEO_PROJECTS_ROOT.*ad_config/m)
      end
    end

    context 'when video-projects-root is empty string' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return('')
      end

      it 'raises helpful error' do
        expect { described_class.projects_root }.to raise_error(RuntimeError, /VIDEO_PROJECTS_ROOT.*ad_config/m)
      end
    end

    context 'when configured path does not exist' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return('/nonexistent/path')
      end

      it 'raises helpful error' do
        expect { described_class.projects_root }.to raise_error(RuntimeError, /VIDEO_PROJECTS_ROOT.*ad_config/m)
      end
    end
  end

  describe '.brand_path' do
    before do
      FileUtils.mkdir_p(projects_root)
      allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
        .to receive(:video_projects_root).and_return(projects_root)
    end

    context 'when brand exists' do
      before do
        FileUtils.mkdir_p(File.join(projects_root, 'v-appydave', 'b65-test-project'))
      end

      it 'returns full path for shortcut' do
        expect(described_class.brand_path('appydave')).to eq(File.join(projects_root, 'v-appydave'))
      end

      it 'returns full path for full brand name' do
        expect(described_class.brand_path('v-appydave')).to eq(File.join(projects_root, 'v-appydave'))
      end
    end

    context 'when brand does not exist' do
      it 'raises error with available brands' do
        expect { described_class.brand_path('nonexistent') }.to raise_error(/Brand directory not found/)
      end
    end
  end

  describe '.expand_brand' do
    it 'expands appydave to v-appydave' do
      expect(described_class.expand_brand('appydave')).to eq('v-appydave')
    end

    it 'expands voz to v-voz' do
      expect(described_class.expand_brand('voz')).to eq('v-voz')
    end

    it 'expands aitldr to v-aitldr' do
      expect(described_class.expand_brand('aitldr')).to eq('v-aitldr')
    end

    it 'expands kiros to v-kiros' do
      expect(described_class.expand_brand('kiros')).to eq('v-kiros')
    end

    it 'expands joy to v-beauty-and-joy' do
      expect(described_class.expand_brand('joy')).to eq('v-beauty-and-joy')
    end

    it 'expands ss to v-supportsignal' do
      expect(described_class.expand_brand('ss')).to eq('v-supportsignal')
    end

    it 'returns v-* names unchanged' do
      expect(described_class.expand_brand('v-appydave')).to eq('v-appydave')
      expect(described_class.expand_brand('v-custom')).to eq('v-custom')
    end

    it 'adds v- prefix to unknown brands' do
      expect(described_class.expand_brand('custom')).to eq('v-custom')
    end

    context 'with case-insensitive matching' do
      let(:brands_config) { instance_double(Appydave::Tools::Configuration::Models::BrandsConfig) }
      let(:appydave_brand) do
        instance_double(
          Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo,
          key: 'appydave',
          shortcut: 'ad'
        )
      end
      let(:voz_brand) do
        instance_double(
          Appydave::Tools::Configuration::Models::BrandsConfig::BrandInfo,
          key: 'voz',
          shortcut: 'voz'
        )
      end

      before do
        allow(Appydave::Tools::Configuration::Config).to receive(:configure)
        allow(Appydave::Tools::Configuration::Config).to receive(:brands).and_return(brands_config)
        allow(brands_config).to receive(:brands).and_return([appydave_brand, voz_brand])
      end

      it 'matches brand key in uppercase (APPYDAVE → v-appydave)' do
        allow(brands_config).to receive(:shortcut?).with('appydave').and_return(false)
        expect(described_class.expand_brand('APPYDAVE')).to eq('v-appydave')
      end

      it 'matches brand key in mixed case (AppyDave → v-appydave)' do
        allow(brands_config).to receive(:shortcut?).with('appydave').and_return(false)
        expect(described_class.expand_brand('AppyDave')).to eq('v-appydave')
      end

      it 'matches shortcut in uppercase (AD → v-appydave)' do
        allow(brands_config).to receive(:shortcut?).with('ad').and_return(false)
        expect(described_class.expand_brand('AD')).to eq('v-appydave')
      end

      it 'matches shortcut in mixed case (Ad → v-appydave)' do
        allow(brands_config).to receive(:shortcut?).with('ad').and_return(false)
        expect(described_class.expand_brand('Ad')).to eq('v-appydave')
      end

      it 'matches VOZ in uppercase' do
        allow(brands_config).to receive(:shortcut?).with('voz').and_return(false)
        expect(described_class.expand_brand('VOZ')).to eq('v-voz')
      end

      it 'normalizes unknown brands to lowercase (CUSTOM → v-custom)' do
        allow(brands_config).to receive(:shortcut?).with('custom').and_return(false)
        expect(described_class.expand_brand('CUSTOM')).to eq('v-custom')
      end
    end
  end

  describe '.available_brands' do
    before do
      FileUtils.mkdir_p(projects_root)
      allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
        .to receive(:video_projects_root).and_return(projects_root)
    end

    context 'when no brands exist' do
      it 'returns empty array' do
        expect(described_class.available_brands).to eq([])
      end
    end

    context 'when brands exist' do
      before do
        # Create valid brands (with projects)
        FileUtils.mkdir_p(File.join(projects_root, 'v-appydave', 'b65-test'))
        FileUtils.mkdir_p(File.join(projects_root, 'v-voz', 'boy-baker'))
        FileUtils.mkdir_p(File.join(projects_root, 'v-aitldr', 'movie-posters'))

        # Create v-shared (should be excluded)
        FileUtils.mkdir_p(File.join(projects_root, 'v-shared', 'tools'))

        # Create empty brand (no projects - should be excluded)
        FileUtils.mkdir_p(File.join(projects_root, 'v-empty'))
      end

      it 'returns list of brand shortcuts' do
        brands = described_class.available_brands
        expect(brands).to include('appydave', 'voz', 'aitldr')
      end

      it 'excludes v-shared' do
        brands = described_class.available_brands
        expect(brands).not_to include('shared')
      end

      it 'excludes empty brands' do
        brands = described_class.available_brands
        expect(brands).not_to include('empty')
      end

      it 'returns sorted list' do
        brands = described_class.available_brands
        expect(brands).to eq(brands.sort)
      end
    end
  end

  describe '.valid_brand?' do
    let(:brand_path) { File.join(projects_root, 'v-test') }

    before do
      FileUtils.mkdir_p(brand_path)
    end

    context 'when brand has projects' do
      before do
        FileUtils.mkdir_p(File.join(brand_path, 'project-1'))
        FileUtils.mkdir_p(File.join(brand_path, 'project-2'))
      end

      it 'returns true' do
        expect(described_class.valid_brand?(brand_path)).to be(true)
      end
    end

    context 'when brand has only hidden directories' do
      before do
        FileUtils.mkdir_p(File.join(brand_path, '.git'))
        FileUtils.mkdir_p(File.join(brand_path, '_cache'))
      end

      it 'returns false' do
        expect(described_class.valid_brand?(brand_path)).to be(false)
      end
    end

    context 'when brand is empty' do
      it 'returns false' do
        expect(described_class.valid_brand?(brand_path)).to be(false)
      end
    end
  end

  describe '.configured?' do
    context 'when video-projects-root exists and is valid' do
      before do
        FileUtils.mkdir_p(projects_root)
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return(projects_root)
      end

      it 'returns true' do
        expect(described_class.configured?).to be(true)
      end
    end

    context 'when video-projects-root is not configured' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return(nil)
      end

      it 'returns false' do
        expect(described_class.configured?).to be(false)
      end
    end

    context 'when video-projects-root is empty string' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return('')
      end

      it 'returns false' do
        expect(described_class.configured?).to be(false)
      end
    end

    context 'when video-projects-root path is invalid' do
      before do
        allow_any_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
          .to receive(:video_projects_root).and_return('/nonexistent')
      end

      it 'returns false' do
        expect(described_class.configured?).to be(false)
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
