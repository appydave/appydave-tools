# frozen_string_literal: true

RSpec.describe Appydave::Tools::AppContext::Options do
  subject(:options) { described_class.new }

  describe 'defaults' do
    it 'has empty app_names' do
      expect(options.app_names).to eq([])
    end

    it 'has empty glob_names' do
      expect(options.glob_names).to eq([])
    end

    it 'has nil pattern_filter' do
      expect(options.pattern_filter).to be_nil
    end

    it 'has meta disabled' do
      expect(options.meta).to be false
    end

    it 'has list disabled' do
      expect(options.list).to be false
    end

    it 'has list_apps disabled' do
      expect(options.list_apps).to be false
    end

    it 'has debug_level set to none' do
      expect(options.debug_level).to eq('none')
    end
  end

  describe '#query?' do
    context 'when no app names or pattern filter' do
      it 'returns false' do
        expect(options.query?).to be false
      end
    end

    context 'when app_names has entries' do
      before { options.app_names << 'flihub' }

      it 'returns true' do
        expect(options.query?).to be true
      end
    end

    context 'when pattern_filter is set' do
      before { options.pattern_filter = 'rvets' }

      it 'returns true' do
        expect(options.query?).to be true
      end
    end
  end

  describe 'mutability' do
    it 'allows pushing to app_names' do
      options.app_names << 'flihub'
      options.app_names << 'angeleye'
      expect(options.app_names).to eq(%w[flihub angeleye])
    end

    it 'allows pushing to glob_names' do
      options.glob_names << 'docs'
      options.glob_names << 'services'
      expect(options.glob_names).to eq(%w[docs services])
    end

    it 'allows setting meta' do
      options.meta = true
      expect(options.meta).to be true
    end
  end
end
