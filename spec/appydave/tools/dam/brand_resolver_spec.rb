# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::BrandResolver do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  # Manually create paths for brands with hyphens (shared context uses underscores)
  let(:beauty_and_joy_path) do
    path = File.join(projects_root, 'v-beauty-and-joy')
    FileUtils.mkdir_p(path)
    path
  end

  let(:supportsignal_path) do
    path = File.join(projects_root, 'v-supportsignal')
    FileUtils.mkdir_p(path)
    path
  end

  before do
    # Create at least one project in each brand to make them valid
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project'))
    FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
    FileUtils.mkdir_p(File.join(beauty_and_joy_path, 'test-project'))
    FileUtils.mkdir_p(File.join(supportsignal_path, 'a01-test'))
  end

  describe '.expand' do
    it 'returns v- prefixed names unchanged' do
      expect(described_class.expand('v-appydave')).to eq('v-appydave')
      expect(described_class.expand('v-voz')).to eq('v-voz')
    end

    it 'expands brand keys to v- prefixed names' do
      expect(described_class.expand('appydave')).to eq('v-appydave')
      expect(described_class.expand('voz')).to eq('v-voz')
      expect(described_class.expand('beauty-and-joy')).to eq('v-beauty-and-joy')
    end

    it 'expands shortcuts to v- prefixed names' do
      expect(described_class.expand('ad')).to eq('v-appydave')
      expect(described_class.expand('joy')).to eq('v-beauty-and-joy')
      expect(described_class.expand('ss')).to eq('v-supportsignal')
    end

    it 'handles case-insensitive input' do
      expect(described_class.expand('APPYDAVE')).to eq('v-appydave')
      expect(described_class.expand('Ad')).to eq('v-appydave')
      expect(described_class.expand('JOY')).to eq('v-beauty-and-joy')
    end
  end

  describe '.normalize' do
    it 'strips v- prefix' do
      expect(described_class.normalize('v-appydave')).to eq('appydave')
      expect(described_class.normalize('v-voz')).to eq('voz')
      expect(described_class.normalize('v-beauty-and-joy')).to eq('beauty-and-joy')
    end

    it 'returns names without v- prefix unchanged' do
      expect(described_class.normalize('appydave')).to eq('appydave')
      expect(described_class.normalize('voz')).to eq('voz')
    end

    it 'handles empty strings' do
      expect(described_class.normalize('')).to eq('')
    end
  end

  describe '.to_config_key' do
    context 'with brand keys' do
      it 'returns lowercase brand key' do
        expect(described_class.to_config_key('appydave')).to eq('appydave')
        expect(described_class.to_config_key('APPYDAVE')).to eq('appydave')
        expect(described_class.to_config_key('voz')).to eq('voz')
      end
    end

    context 'with shortcuts' do
      it 'converts shortcut to brand key' do
        expect(described_class.to_config_key('ad')).to eq('appydave')
        expect(described_class.to_config_key('AD')).to eq('appydave')
        expect(described_class.to_config_key('joy')).to eq('beauty-and-joy')
        expect(described_class.to_config_key('ss')).to eq('supportsignal')
      end
    end

    context 'with v- prefixed names' do
      it 'strips v- prefix and returns key' do
        expect(described_class.to_config_key('v-appydave')).to eq('appydave')
        expect(described_class.to_config_key('v-voz')).to eq('voz')
        expect(described_class.to_config_key('v-beauty-and-joy')).to eq('beauty-and-joy')
      end
    end

    context 'with unknown brands' do
      it 'returns normalized lowercase input' do
        expect(described_class.to_config_key('unknown')).to eq('unknown')
        expect(described_class.to_config_key('CUSTOM')).to eq('custom')
      end
    end

    context 'with case-insensitive matching' do
      it 'matches brand keys in any case' do
        expect(described_class.to_config_key('APPYDAVE')).to eq('appydave')
        expect(described_class.to_config_key('AppyDave')).to eq('appydave')
        expect(described_class.to_config_key('VOZ')).to eq('voz')
      end

      it 'matches shortcuts in any case' do
        expect(described_class.to_config_key('AD')).to eq('appydave')
        expect(described_class.to_config_key('Ad')).to eq('appydave')
        expect(described_class.to_config_key('JOY')).to eq('beauty-and-joy')
      end
    end
  end

  describe '.to_display' do
    it 'returns v- prefixed display name' do
      expect(described_class.to_display('appydave')).to eq('v-appydave')
      expect(described_class.to_display('ad')).to eq('v-appydave')
      expect(described_class.to_display('v-appydave')).to eq('v-appydave')
    end

    it 'handles shortcuts' do
      expect(described_class.to_display('joy')).to eq('v-beauty-and-joy')
      expect(described_class.to_display('ss')).to eq('v-supportsignal')
    end
  end

  describe '.validate' do
    context 'when brand exists' do
      it 'returns config key for valid brand' do
        expect(described_class.validate('appydave')).to eq('appydave')
        expect(described_class.validate('ad')).to eq('appydave')
        expect(described_class.validate('v-appydave')).to eq('appydave')
      end

      it 'handles case-insensitive input' do
        expect(described_class.validate('APPYDAVE')).to eq('appydave')
        expect(described_class.validate('AD')).to eq('appydave')
      end
    end

    context 'when brand does not exist' do
      it 'raises BrandNotFoundError with available brands' do
        expect { described_class.validate('nonexistent') }.to raise_error(
          Appydave::Tools::Dam::BrandNotFoundError,
          /nonexistent/
        )
      end

      it 'includes brand name in error message' do
        expect { described_class.validate('invalid') }.to raise_error do |error|
          expect(error.message).to include('invalid')
          expect(error.message).to include('Brand directory not found')
        end
      end
    end
  end

  describe '.exists?' do
    it 'returns true for existing brands' do
      expect(described_class.exists?('appydave')).to be true
      expect(described_class.exists?('ad')).to be true
      expect(described_class.exists?('v-voz')).to be true
    end

    it 'returns false for non-existing brands' do
      expect(described_class.exists?('nonexistent')).to be false
      expect(described_class.exists?('invalid')).to be false
    end

    it 'handles case-insensitive input' do
      expect(described_class.exists?('APPYDAVE')).to be true
      expect(described_class.exists?('Ad')).to be true
    end
  end
end
