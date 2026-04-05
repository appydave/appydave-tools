# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Query do
  include_context 'with jump filesystem'

  let(:config) do
    data = full_config(
      locations: [
        JumpTestLocations.ad_tools,
        JumpTestLocations.flivideo,
        JumpTestLocations.supportsignal,
        {
          'key' => 'ad-gem',
          'path' => '~/dev/ad/appydave-gem',
          'jump' => 'jadag',
          'brand' => 'appydave',
          'type' => 'gem',
          'tags' => %w[ruby gem],
          'description' => 'AppyDave Ruby gem'
        }
      ],
      brands: JumpTestLocations.sample_brands,
      clients: JumpTestLocations.sample_clients
    )
    create_test_config(data)
  end

  describe '#run' do
    context 'with no filters' do
      subject { described_class.new(config) }

      it 'returns all locations' do
        result = subject.run

        expect(result[:success]).to be true
        expect(result[:count]).to eq(4)
      end

      it 'returns results with key and path' do
        result = subject.run

        expect(result[:results].first).to include(:key, :path)
      end
    end

    context 'with --find filter' do
      it 'matches by key substring' do
        cmd = described_class.new(config, find: ['flivideo'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:key]).to eq('flivideo')
      end

      it 'matches by type' do
        cmd = described_class.new(config, find: ['gem'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].any? { |r| r[:type] == 'gem' }).to be true
      end

      it 'matches by tag' do
        cmd = described_class.new(config, find: ['ruby'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:count]).to be >= 2
      end

      it 'matches by description substring' do
        cmd = described_class.new(config, find: ['asset management'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].first[:key]).to eq('flivideo')
      end

      it 'matches by brand' do
        cmd = described_class.new(config, find: ['appydave'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].all? { |r| r[:brand] == 'appydave' }).to be true
      end

      it 'applies AND logic for multiple find terms' do
        cmd = described_class.new(config, find: %w[appydave gem])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:key]).to eq('ad-gem')
      end

      it 'is case-insensitive' do
        cmd = described_class.new(config, find: ['FliVideo'])
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].first[:key]).to eq('flivideo')
      end
    end

    context 'with --type filter' do
      it 'returns only locations of that type' do
        cmd = described_class.new(config, type: 'tool')
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].all? { |r| r[:type] == 'tool' }).to be true
      end

      it 'returns NOT_FOUND when no locations match type' do
        cmd = described_class.new(config, type: 'nonexistent-type')
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('NOT_FOUND')
      end
    end

    context 'with --brand filter' do
      it 'returns only locations for that brand' do
        cmd = described_class.new(config, brand: 'appydave')
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].all? { |r| r[:brand] == 'appydave' }).to be true
      end
    end

    context 'with combined --find and --type filters' do
      it 'applies both filters (AND logic)' do
        cmd = described_class.new(config, find: ['appydave'], type: 'tool')
        result = cmd.run

        expect(result[:success]).to be true
        expect(result[:results].all? { |r| r[:brand] == 'appydave' && r[:type] == 'tool' }).to be true
      end
    end

    context 'when no matches found' do
      it 'returns NOT_FOUND error' do
        cmd = described_class.new(config, find: ['zzznomatch'])
        result = cmd.run

        expect(result[:success]).to be false
        expect(result[:code]).to eq('NOT_FOUND')
        expect(result[:error]).to be_a(String)
      end
    end

    context 'with result structure' do
      subject { described_class.new(config, find: ['flivideo']) }

      it 'includes required fields' do
        result = subject.run

        r = result[:results].first
        expect(r).to include(:key, :path, :index)
      end

      it 'expands ~ in path' do
        result = subject.run

        expect(result[:results].first[:path]).not_to start_with('~')
      end

      it 'includes status field' do
        result = subject.run

        expect(result[:results].first[:status]).to eq('active')
      end
    end
  end
end
