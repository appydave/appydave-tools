# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Brand resolution integration' do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project'))
    FileUtils.mkdir_p(File.join(appydave_path, 'b66-another-project'))
    FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
  end

  describe 'BrandResolver → Config.brand_path' do
    it 'resolves appydave shortcut to correct path' do
      path = Appydave::Tools::Dam::Config.brand_path('appydave')
      expect(path).to eq(appydave_path)
    end

    it 'resolves voz shortcut to correct path' do
      path = Appydave::Tools::Dam::Config.brand_path('voz')
      expect(path).to eq(voz_path)
    end

    it 'raises BrandNotFoundError for unknown brand' do
      expect { Appydave::Tools::Dam::Config.brand_path('nonexistent') }
        .to raise_error(Appydave::Tools::Dam::BrandNotFoundError)
    end
  end

  describe 'BrandResolver.expand' do
    it 'expands appydave to v-appydave' do
      expect(Appydave::Tools::Dam::BrandResolver.expand('appydave')).to eq('v-appydave')
    end

    it 'expands voz to v-voz' do
      expect(Appydave::Tools::Dam::BrandResolver.expand('voz')).to eq('v-voz')
    end
  end

  describe 'ProjectResolver.resolve' do
    it 'resolves short name b65 to full project name' do
      result = Appydave::Tools::Dam::ProjectResolver.resolve('appydave', 'b65')
      expect(result).to eq('b65-test-project')
    end

    it 'resolves exact project name' do
      result = Appydave::Tools::Dam::ProjectResolver.resolve('voz', 'boy-baker')
      expect(result).to eq('boy-baker')
    end

    it 'raises error for missing project' do
      expect { Appydave::Tools::Dam::ProjectResolver.resolve('appydave', 'b99') }
        .to raise_error(/No project found matching 'b99'/)
    end
  end

  describe 'ProjectResolver.detect_from_pwd' do
    it 'detects brand and project from a project directory' do
      project_path = File.join(appydave_path, 'b65-test-project')

      allow(Appydave::Tools::Dam::Config).to receive(:project_path) do |brand_key, project_id|
        if brand_key == 'appydave' && project_id == 'b65-test-project'
          project_path
        else
          '/nonexistent'
        end
      end

      Dir.chdir(project_path) do
        brand, project = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
        expect(brand).to eq('appydave')
        expect(project).to eq('b65-test-project')
      end
    end

    it 'returns nil when run outside any known brand directory' do
      Dir.chdir('/tmp') do
        brand, project = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
        expect(brand).to be_nil
        expect(project).to be_nil
      end
    end
  end
end
