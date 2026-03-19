# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Update do
  include_context 'with jump filesystem'

  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/dev/ad/appydave-tools', '~/dev/updated-path']) }

  let(:config) do
    data = minimal_config(locations: [JumpTestLocations.ad_tools, JumpTestLocations.flivideo])
    create_test_config(data)
  end

  describe '#run' do
    context 'when location exists and update is valid' do
      it 'updates the location successfully' do
        cmd = described_class.new(config, 'ad-tools', { description: 'Updated description' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:message]).to include('ad-tools')
        expect(result[:message]).to include('updated')
      end

      it 'returns the updated location data' do
        cmd = described_class.new(config, 'ad-tools', { description: 'Updated description' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:location]).to be_a(Hash)
        expect(result[:location][:key]).to eq('ad-tools')
      end

      it 'persists the updated description' do
        cmd = described_class.new(config, 'ad-tools', { description: 'New description' }, path_validator: path_validator)
        cmd.run

        updated = config.find('ad-tools')
        expect(updated.description).to eq('New description')
      end

      it 'persists the updated path' do
        cmd = described_class.new(config, 'ad-tools', { path: '~/dev/updated-path' }, path_validator: path_validator)
        cmd.run

        updated = config.find('ad-tools')
        expect(updated.path).to eq('~/dev/updated-path')
      end

      it 'leaves unmodified locations intact' do
        cmd = described_class.new(config, 'ad-tools', { description: 'Changed' }, path_validator: path_validator)
        cmd.run

        expect(config.key_exists?('flivideo')).to be true
      end

      it 'does not include a warning when updated path exists' do
        cmd = described_class.new(config, 'ad-tools', { path: '~/dev/updated-path' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:warning]).to be_nil
      end

      it 'does not modify non-updated fields on the updated record' do
        original = config.find('ad-tools')
        original_path = original.path
        original_jump = original.jump
        original_tags = original.tags

        cmd = described_class.new(config, 'ad-tools', { description: 'Changed' }, path_validator: path_validator)
        cmd.run

        updated = config.find('ad-tools')
        expect(updated.path).to eq(original_path)
        expect(updated.jump).to eq(original_jump)
        expect(updated.tags).to eq(original_tags)
      end

      it 'does not modify the sibling record fields' do
        original_flivideo = config.find('flivideo')
        original_path = original_flivideo.path
        original_jump = original_flivideo.jump

        cmd = described_class.new(config, 'ad-tools', { description: 'Changed' }, path_validator: path_validator)
        cmd.run

        flivideo = config.find('flivideo')
        expect(flivideo.path).to eq(original_path)
        expect(flivideo.jump).to eq(original_jump)
      end
    end

    context 'when updated path does not exist' do
      let(:no_path_validator) { TestPathValidator.new(valid_paths: []) }

      it 'still succeeds (path may be created later)' do
        cmd = described_class.new(config, 'ad-tools', { path: '~/dev/missing-path' }, path_validator: no_path_validator)
        result = cmd.run

        expect(result[:success]).to be true
      end

      it 'includes a path warning in the result' do
        cmd = described_class.new(config, 'ad-tools', { path: '~/dev/missing-path' }, path_validator: no_path_validator)
        result = cmd.run

        expect(result[:warning]).to include('does not exist')
        expect(result[:warning]).to include('~/dev/missing-path')
      end
    end

    context 'when updating a field that is not the path' do
      it 'does not produce a warning for non-path updates' do
        cmd = described_class.new(config, 'ad-tools', { description: 'No path change' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:warning]).to be_nil
      end
    end

    context 'when location does not exist' do
      it 'returns a not-found error' do
        cmd = described_class.new(config, 'nonexistent-key', { description: 'Whatever' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('NOT_FOUND')
      end

      it 'includes the missing key in the error message' do
        cmd = described_class.new(config, 'nonexistent-key', { description: 'Whatever' }, path_validator: path_validator)
        result = cmd.run

        expect(result[:error]).to include('nonexistent-key')
      end
    end
  end
end
