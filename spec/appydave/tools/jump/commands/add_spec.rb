# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Add do
  include_context 'with jump filesystem'

  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/dev/ad/appydave-tools', '~/dev/new-project']) }

  let(:config) do
    data = minimal_config(locations: [JumpTestLocations.ad_tools])
    create_test_config(data)
  end

  let(:valid_attrs) do
    {
      key: 'new-project',
      path: '~/dev/new-project',
      jump: 'jnew',
      type: 'tool',
      tags: %w[ruby],
      description: 'A new project'
    }
  end

  describe '#run' do
    context 'with valid attributes and existing path' do
      it 'adds the location successfully' do
        cmd = described_class.new(config, valid_attrs, path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:message]).to include('new-project')
        expect(result[:message]).to include('added')
      end

      it 'returns the created location data' do
        cmd = described_class.new(config, valid_attrs, path_validator: path_validator)
        result = cmd.run

        expect(result[:location]).to be_a(Hash)
        expect(result[:location][:key]).to eq('new-project')
      end

      it 'persists the location to the config' do
        cmd = described_class.new(config, valid_attrs, path_validator: path_validator)
        cmd.run

        expect(config.key_exists?('new-project')).to be true
      end

      it 'does not set a warning when path exists' do
        cmd = described_class.new(config, valid_attrs, path_validator: path_validator)
        result = cmd.run

        expect(result[:warning]).to be_nil
      end
    end

    context 'with valid attributes but non-existent path' do
      let(:no_path_validator) { TestPathValidator.new(valid_paths: []) }

      it 'still succeeds (path may be created later)' do
        cmd = described_class.new(config, valid_attrs, path_validator: no_path_validator)
        result = cmd.run

        expect(result[:success]).to be true
      end

      it 'includes a path warning in the result' do
        cmd = described_class.new(config, valid_attrs, path_validator: no_path_validator)
        result = cmd.run

        expect(result[:warning]).to include('does not exist')
        expect(result[:warning]).to include('~/dev/new-project')
      end
    end

    context 'when key already exists' do
      it 'returns a duplicate key error' do
        cmd = described_class.new(config, valid_attrs.merge(key: 'ad-tools'), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('DUPLICATE_KEY')
      end

      it 'includes the duplicate key in the error message' do
        cmd = described_class.new(config, valid_attrs.merge(key: 'ad-tools'), path_validator: path_validator)
        result = cmd.run

        expect(result[:error]).to include('ad-tools')
      end
    end

    context 'when required attributes are missing' do
      it 'returns error when key is missing' do
        cmd = described_class.new(config, valid_attrs.merge(key: nil), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
        expect(result[:error]).to include('Key is required')
      end

      it 'returns error when key is empty string' do
        cmd = described_class.new(config, valid_attrs.merge(key: ''), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
      end

      it 'returns error when path is missing' do
        cmd = described_class.new(config, valid_attrs.merge(path: nil), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
        expect(result[:error]).to include('Path is required')
      end

      it 'returns error when path is empty string' do
        cmd = described_class.new(config, valid_attrs.merge(path: ''), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
      end
    end

    context 'when location attributes fail validation' do
      it 'returns invalid input error for bad key format' do
        cmd = described_class.new(config, valid_attrs.merge(key: 'INVALID KEY!'), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
      end

      it 'returns invalid input error for bad path format' do
        cmd = described_class.new(config, valid_attrs.merge(path: 'relative/path'), path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('INVALID_INPUT')
      end
    end
  end
end
