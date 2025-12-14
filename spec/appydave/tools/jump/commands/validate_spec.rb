# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Validate do
  include_context 'with jump filesystem'

  let(:config) do
    data = minimal_config(locations: [
                            { 'key' => 'valid-loc', 'path' => '~/real-path', 'jump' => 'jvalid' },
                            { 'key' => 'invalid-loc', 'path' => '~/does-not-exist', 'jump' => 'jinvalid' }
                          ])
    create_test_config(data)
  end

  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/real-path']) }

  describe '#run' do
    context 'when validating all locations' do
      subject { described_class.new(config, path_validator: path_validator) }

      it 'returns validation results for all locations' do
        result = subject.run

        expect(result[:success]).to be true
        expect(result[:count]).to eq(2)
        expect(result[:valid_count]).to eq(1)
        expect(result[:invalid_count]).to eq(1)
      end

      it 'identifies valid paths' do
        result = subject.run

        valid_loc = result[:results].find { |r| r[:key] == 'valid-loc' }
        expect(valid_loc[:valid]).to be true
      end

      it 'identifies invalid paths' do
        result = subject.run

        invalid_loc = result[:results].find { |r| r[:key] == 'invalid-loc' }
        expect(invalid_loc[:valid]).to be false
      end
    end

    context 'when validating specific location' do
      it 'validates only the specified location' do
        cmd = described_class.new(config, key: 'valid-loc', path_validator: path_validator)
        result = cmd.run

        expect(result[:count]).to eq(1)
        expect(result[:results].first[:key]).to eq('valid-loc')
      end

      it 'returns error for unknown key' do
        cmd = described_class.new(config, key: 'unknown', path_validator: path_validator)
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('NOT_FOUND')
      end
    end
  end
end
