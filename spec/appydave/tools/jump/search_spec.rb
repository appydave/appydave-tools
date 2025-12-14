# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Search do
  include_context 'with jump filesystem'

  let(:config) do
    data = full_config(
      locations: [JumpTestLocations.ad_tools, JumpTestLocations.flivideo, JumpTestLocations.supportsignal],
      brands: JumpTestLocations.sample_brands,
      clients: JumpTestLocations.sample_clients
    )
    create_test_config(data)
  end

  let(:search) { described_class.new(config) }

  describe '#search' do
    context 'with matching terms' do
      it 'finds locations by key' do
        result = search.search('ad-tools')

        expect(result[:success]).to be true
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:key]).to eq('ad-tools')
      end

      it 'finds locations by partial key match' do
        result = search.search('tools')

        expect(result[:success]).to be true
        expect(result[:count]).to be >= 1
        expect(result[:results].any? { |r| r[:key] == 'ad-tools' }).to be true
      end

      it 'finds locations by brand alias' do
        result = search.search('ad')

        expect(result[:success]).to be true
        expect(result[:results].any? { |r| r[:brand] == 'appydave' }).to be true
      end

      it 'finds locations by client alias' do
        result = search.search('ss')

        expect(result[:success]).to be true
        expect(result[:results].any? { |r| r[:client] == 'supportsignal' }).to be true
      end

      it 'finds locations by tag' do
        result = search.search('ruby')

        expect(result[:success]).to be true
        expect(result[:results].any? { |r| r[:tags]&.include?('ruby') }).to be true
      end

      it 'finds locations by type' do
        result = search.search('tool')

        expect(result[:success]).to be true
        expect(result[:count]).to be >= 1
      end

      it 'finds locations by multiple terms' do
        result = search.search('appydave ruby')

        expect(result[:success]).to be true
        # ad-tools has both appydave brand and ruby tag
        expect(result[:results].any? { |r| r[:key] == 'ad-tools' }).to be true
      end
    end

    context 'with no matches' do
      it 'returns empty results' do
        result = search.search('nonexistent')

        expect(result[:success]).to be true
        expect(result[:count]).to eq(0)
        expect(result[:results]).to be_empty
      end
    end

    context 'with empty query' do
      it 'returns empty results' do
        result = search.search('')

        expect(result[:success]).to be true
        expect(result[:count]).to eq(0)
      end

      it 'handles nil query' do
        result = search.search(nil)

        expect(result[:success]).to be true
        expect(result[:count]).to eq(0)
      end
    end

    context 'with scoring' do
      it 'scores exact key match highest' do
        result = search.search('ad-tools')

        expect(result[:results].first[:score]).to eq(100)
      end

      it 'sorts by score descending' do
        result = search.search('tool')

        scores = result[:results].map { |r| r[:score] }
        expect(scores).to eq(scores.sort.reverse)
      end

      it 'includes index numbers' do
        result = search.search('tool')

        expect(result[:results].first[:index]).to eq(1)
        expect(result[:results].last[:index]).to eq(result[:count])
      end
    end
  end

  describe '#get' do
    it 'returns location for exact key' do
      result = search.get('ad-tools')

      expect(result[:success]).to be true
      expect(result[:result][:key]).to eq('ad-tools')
    end

    it 'returns error for unknown key' do
      result = search.get('unknown')

      expect(result[:success]).to be false
      expect(result[:code]).to eq('NOT_FOUND')
    end

    it 'includes suggestions for unknown key' do
      result = search.get('ad-tool') # similar to ad-tools

      expect(result[:success]).to be false
      expect(result[:suggestion]).to match(/Did you mean/)
    end
  end

  describe '#list' do
    it 'returns all locations' do
      result = search.list

      expect(result[:success]).to be true
      expect(result[:count]).to eq(3)
    end

    it 'includes index numbers' do
      result = search.list

      expect(result[:results].first[:index]).to eq(1)
    end

    it 'expands paths' do
      result = search.list

      # Paths should be expanded (no ~)
      expect(result[:results].first[:path]).to start_with('/')
    end
  end
end
