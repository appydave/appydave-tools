# frozen_string_literal: true

RSpec.describe Appydave::Tools::Dam::FuzzyMatcher do
  describe '.levenshtein_distance' do
    it 'returns 0 for identical strings' do
      expect(described_class.levenshtein_distance('hello', 'hello')).to eq(0)
    end

    it 'returns string length for empty source' do
      expect(described_class.levenshtein_distance('', 'hello')).to eq(5)
    end

    it 'returns string length for empty target' do
      expect(described_class.levenshtein_distance('hello', '')).to eq(5)
    end

    it 'calculates single character substitution' do
      expect(described_class.levenshtein_distance('hello', 'hallo')).to eq(1)
    end

    it 'calculates single character insertion' do
      expect(described_class.levenshtein_distance('hello', 'helllo')).to eq(1)
    end

    it 'calculates single character deletion' do
      expect(described_class.levenshtein_distance('hello', 'helo')).to eq(1)
    end

    it 'calculates multiple edits' do
      expect(described_class.levenshtein_distance('kitten', 'sitting')).to eq(3)
    end

    it 'is case-sensitive' do
      expect(described_class.levenshtein_distance('Hello', 'hello')).to eq(1)
    end
  end

  describe '.find_matches' do
    let(:brands) { %w[appydave voz aitldr kiros beauty-and-joy supportsignal] }

    context 'with exact match' do
      it 'returns exact match with distance 0' do
        matches = described_class.find_matches('voz', brands)
        expect(matches).to eq(['voz'])
      end
    end

    context 'with typos' do
      it 'finds match for single character typo' do
        matches = described_class.find_matches('vos', brands, threshold: 1)
        expect(matches).to include('voz')
      end

      it 'finds match for appydav (missing e)' do
        matches = described_class.find_matches('appydav', brands)
        expect(matches.first).to eq('appydave')
      end

      it 'finds match for appydave with extra character' do
        matches = described_class.find_matches('appydavee', brands)
        expect(matches.first).to eq('appydave')
      end

      it 'finds match for aitlr (missing d)' do
        matches = described_class.find_matches('aitlr', brands, threshold: 2)
        expect(matches).to include('aitldr')
      end
    end

    context 'with threshold' do
      it 'excludes matches beyond threshold' do
        matches = described_class.find_matches('xyz', brands, threshold: 1)
        expect(matches).to be_empty
      end

      it 'includes matches within threshold' do
        matches = described_class.find_matches('kiross', brands, threshold: 2)
        expect(matches).to include('kiros')
      end

      it 'uses default threshold of 3' do
        matches = described_class.find_matches('appydav', brands)
        expect(matches).not_to be_empty
      end
    end

    context 'with case-insensitive matching' do
      it 'finds match regardless of input case' do
        matches = described_class.find_matches('VOZ', brands)
        expect(matches).to include('voz')
      end

      it 'finds match for APPYDAVE' do
        matches = described_class.find_matches('APPYDAVE', brands)
        expect(matches.first).to eq('appydave')
      end
    end

    context 'with empty inputs' do
      it 'returns empty array for nil input' do
        matches = described_class.find_matches(nil, brands)
        expect(matches).to eq([])
      end

      it 'returns empty array for empty input' do
        matches = described_class.find_matches('', brands)
        expect(matches).to eq([])
      end

      it 'returns empty array for empty candidates' do
        matches = described_class.find_matches('voz', [])
        expect(matches).to eq([])
      end
    end

    context 'with multiple matches' do
      it 'returns matches sorted by distance' do
        # 'appyd' is closer to 'appydave' (3 edits) than other brands
        matches = described_class.find_matches('appyd', brands, threshold: 10)
        expect(matches.first).to eq('appydave')
      end

      it 'returns multiple matches sorted by distance' do
        matches = described_class.find_matches('vo', brands, threshold: 3)
        expect(matches).to include('voz')
      end
    end
  end
end
