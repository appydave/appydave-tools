# frozen_string_literal: true

require 'rspec'

RSpec.describe Appydave::Tools::Dam::ProjectResolver do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  describe '.resolve' do
    context 'with FliVideo pattern (short names)' do
      before do
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-guy-monroe-marketing-plan'))
        FileUtils.mkdir_p(File.join(appydave_path, 'b66-context-engineered-html-art'))
      end

      it 'expands b65 to full project name' do
        result = described_class.resolve('appydave', 'b65')
        expect(result).to eq('b65-guy-monroe-marketing-plan')
      end

      it 'expands b66 to full project name' do
        result = described_class.resolve('appydave', 'b66')
        expect(result).to eq('b66-context-engineered-html-art')
      end

      it 'works with full brand name' do
        result = described_class.resolve('v-appydave', 'b65')
        expect(result).to eq('b65-guy-monroe-marketing-plan')
      end
    end

    context 'with Storyline pattern (exact match)' do
      before do
        FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
        FileUtils.mkdir_p(File.join(voz_path, 'the-point'))
      end

      it 'returns exact match for boy-baker' do
        result = described_class.resolve('voz', 'boy-baker')
        expect(result).to eq('boy-baker')
      end

      it 'returns exact match for the-point' do
        result = described_class.resolve('voz', 'the-point')
        expect(result).to eq('the-point')
      end
    end

    context 'with pattern matching (wildcards)' do
      before do
        FileUtils.mkdir_p(File.join(appydave_path, 'b60-test-1'))
        FileUtils.mkdir_p(File.join(appydave_path, 'b61-test-2'))
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-3'))
        FileUtils.mkdir_p(File.join(appydave_path, 'b70-test-4'))
      end

      it 'resolves b6* pattern to matching projects' do
        result = described_class.resolve('appydave', 'b6*')
        expect(result).to contain_exactly('b60-test-1', 'b61-test-2', 'b65-test-3')
      end

      it 'resolves b* pattern to all b-projects' do
        result = described_class.resolve('appydave', 'b*')
        expect(result).to contain_exactly('b60-test-1', 'b61-test-2', 'b65-test-3', 'b70-test-4')
      end
    end

    context 'when no matches found' do
      before do
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-existing'))
      end

      it 'raises error for missing short name' do
        expect { described_class.resolve('appydave', 'b99') }.to raise_error(/No project found matching 'b99'/)
      end

      it 'raises error for missing pattern' do
        expect { described_class.resolve('appydave', 'x*') }.to raise_error(/No projects found matching pattern 'x\*'/)
      end
    end

    context 'with multiple matches for short name' do
      before do
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-first-project'))
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-second-project'))

        # Mock stdin for interactive selection
        allow($stdin).to receive(:gets).and_return("1\n")
      end

      it 'prompts for selection and returns chosen project' do
        result = described_class.resolve('appydave', 'b65')
        expect(result).to eq('b65-first-project')
      end
    end
  end

  describe '.resolve_pattern' do
    before do
      FileUtils.mkdir_p(File.join(appydave_path, 'b60-alpha'))
      FileUtils.mkdir_p(File.join(appydave_path, 'b61-beta'))
      FileUtils.mkdir_p(File.join(appydave_path, 'b65-gamma'))
      FileUtils.mkdir_p(File.join(appydave_path, 'c10-delta'))
    end

    it 'returns matching projects sorted' do
      result = described_class.resolve_pattern('appydave', 'b6*')
      expect(result).to eq(%w[b60-alpha b61-beta b65-gamma])
    end

    it 'returns all projects for * pattern' do
      result = described_class.resolve_pattern('appydave', '*')
      expect(result).to eq(%w[b60-alpha b61-beta b65-gamma c10-delta])
    end

    it 'raises error when no matches' do
      expect do
        described_class.resolve_pattern('appydave', 'z*')
      end.to raise_error(/No projects found matching pattern 'z\*'/)
    end
  end

  describe '.list_projects' do
    before do
      FileUtils.mkdir_p(File.join(appydave_path, 'b65-test'))
      FileUtils.mkdir_p(File.join(appydave_path, 'b66-test'))
      FileUtils.mkdir_p(File.join(appydave_path, '.git'))
      FileUtils.mkdir_p(File.join(appydave_path, '_cache'))
    end

    it 'returns all valid projects' do
      result = described_class.list_projects('appydave')
      expect(result).to contain_exactly('b65-test', 'b66-test')
    end

    it 'excludes hidden directories' do
      result = described_class.list_projects('appydave')
      expect(result).not_to include('.git')
    end

    it 'excludes underscore-prefixed directories' do
      result = described_class.list_projects('appydave')
      expect(result).not_to include('_cache')
    end

    it 'returns sorted list' do
      result = described_class.list_projects('appydave')
      expect(result).to eq(result.sort)
    end

    context 'with pattern filter' do
      it 'returns only matching projects' do
        result = described_class.list_projects('appydave', 'b65*')
        expect(result).to eq(['b65-test'])
      end
    end
  end

  describe '.valid_project?' do
    let(:brand_path) { appydave_path }

    before do
      FileUtils.mkdir_p(brand_path)
    end

    it 'returns true for normal project' do
      project_path = File.join(brand_path, 'b65-test')
      FileUtils.mkdir_p(project_path)
      expect(described_class.valid_project?(project_path)).to be(true)
    end

    it 'returns false for excluded directories' do
      %w[archived docs node_modules .git .github].each do |excluded|
        project_path = File.join(brand_path, excluded)
        FileUtils.mkdir_p(project_path)
        expect(described_class.valid_project?(project_path)).to be(false)
      end
    end

    it 'returns false for hidden directories' do
      project_path = File.join(brand_path, '.hidden')
      FileUtils.mkdir_p(project_path)
      expect(described_class.valid_project?(project_path)).to be(false)
    end

    it 'returns false for underscore-prefixed directories' do
      project_path = File.join(brand_path, '_cache')
      FileUtils.mkdir_p(project_path)
      expect(described_class.valid_project?(project_path)).to be(false)
    end
  end

  describe '.detect_from_pwd' do
    context 'when in valid project directory' do
      before do
        FileUtils.mkdir_p(File.join(appydave_path, 'b65-test'))
      end

      it 'detects brand and project from path' do
        allow(Dir).to receive(:pwd).and_return(File.join(appydave_path, 'b65-test'))
        brand, project = described_class.detect_from_pwd
        expect(brand).to eq('v-appydave')
        expect(project).to eq('b65-test')
      end
    end

    context 'when not in project directory' do
      it 'returns nil for both' do
        allow(Dir).to receive(:pwd).and_return('/some/other/path')
        brand, project = described_class.detect_from_pwd
        expect(brand).to be_nil
        expect(project).to be_nil
      end
    end
  end

  describe '.project_exists?' do
    before do
      FileUtils.mkdir_p(File.join(appydave_path, 'b65-existing'))
    end

    it 'returns true for existing project' do
      result = described_class.project_exists?('v-appydave', 'b65-existing')
      expect(result).to be(true)
    end

    it 'returns false for non-existing project' do
      result = described_class.project_exists?('v-appydave', 'b99-missing')
      expect(result).to be(false)
    end
  end
end
