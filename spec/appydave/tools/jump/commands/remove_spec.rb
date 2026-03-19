# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Remove do
  include_context 'with jump filesystem'

  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/dev/ad/appydave-tools']) }

  let(:config) do
    data = minimal_config(locations: [JumpTestLocations.ad_tools, JumpTestLocations.flivideo])
    create_test_config(data)
  end

  describe '#run' do
    context 'when location exists and --force is given' do
      it 'removes the location successfully' do
        cmd = described_class.new(config, 'ad-tools', force: true, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:message]).to include('ad-tools')
        expect(result[:message]).to include('removed')
      end

      it 'returns the removed location data' do
        cmd = described_class.new(config, 'ad-tools', force: true, path_validator: path_validator)
        result = cmd.run

        expect(result[:removed]).to be_a(Hash)
        expect(result[:removed][:key]).to eq('ad-tools')
      end

      it 'actually removes the location from config' do
        cmd = described_class.new(config, 'ad-tools', force: true, path_validator: path_validator)
        cmd.run

        expect(config.key_exists?('ad-tools')).to be false
      end

      it 'leaves other locations intact' do
        cmd = described_class.new(config, 'ad-tools', force: true, path_validator: path_validator)
        cmd.run

        expect(config.key_exists?('flivideo')).to be true
      end
    end

    context 'when location exists but --force is not given' do
      it 'refuses to remove without --force' do
        cmd = described_class.new(config, 'ad-tools', force: false, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('CONFIRMATION_REQUIRED')
      end

      it 'includes --force guidance in the error message' do
        cmd = described_class.new(config, 'ad-tools', force: false, path_validator: path_validator)
        result = cmd.run

        expect(result[:error]).to include('--force')
        expect(result[:error]).to include('ad-tools')
      end

      it 'does not remove the location from config' do
        cmd = described_class.new(config, 'ad-tools', force: false, path_validator: path_validator)
        cmd.run

        expect(config.key_exists?('ad-tools')).to be true
      end
    end

    context 'when location does not exist' do
      it 'returns a not-found error' do
        cmd = described_class.new(config, 'nonexistent-key', force: true, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('NOT_FOUND')
      end

      it 'includes the missing key in the error message' do
        cmd = described_class.new(config, 'nonexistent-key', force: true, path_validator: path_validator)
        result = cmd.run

        expect(result[:error]).to include('nonexistent-key')
      end

      it 'provides a suggestion when a similar key exists' do
        cmd = described_class.new(config, 'ad', force: true, path_validator: path_validator)
        result = cmd.run

        # 'ad' is a prefix of 'ad-tools' so suggestion should fire
        expect(result[:suggestion]).to include('ad-tools')
      end

      it 'returns no suggestion when no similar key exists' do
        cmd = described_class.new(config, 'zzz-no-match', force: true, path_validator: path_validator)
        result = cmd.run

        expect(result[:suggestion]).to be_nil
      end
    end
  end
end
