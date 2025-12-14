# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Location do
  describe '#initialize' do
    it 'creates a location with all attributes' do
      location = described_class.new(
        key: 'ad-tools',
        path: '~/dev/ad/appydave-tools',
        jump: 'jad-tools',
        brand: 'appydave',
        type: 'tool',
        tags: %w[ruby cli],
        description: 'AppyDave CLI tools'
      )

      expect(location.key).to eq('ad-tools')
      expect(location.path).to eq('~/dev/ad/appydave-tools')
      expect(location.jump).to eq('jad-tools')
      expect(location.brand).to eq('appydave')
      expect(location.type).to eq('tool')
      expect(location.tags).to eq(%w[ruby cli])
      expect(location.description).to eq('AppyDave CLI tools')
    end

    it 'generates default jump alias if not provided' do
      location = described_class.new(key: 'my-project', path: '~/dev/project')

      expect(location.jump).to eq('jmy-project')
    end

    it 'handles string keys' do
      location = described_class.new('key' => 'test', 'path' => '~/dev/test')

      expect(location.key).to eq('test')
      expect(location.path).to eq('~/dev/test')
    end
  end

  describe '#validate' do
    context 'with valid location' do
      it 'returns empty errors array' do
        location = described_class.new(key: 'ad-tools', path: '~/dev/project')

        expect(location.validate).to be_empty
      end

      it 'accepts single character key' do
        location = described_class.new(key: 'a', path: '~/dev/a')

        expect(location.validate).to be_empty
      end

      it 'accepts keys with hyphens' do
        location = described_class.new(key: 'my-long-project-name', path: '~/dev/project')

        expect(location.validate).to be_empty
      end
    end

    context 'with invalid key' do
      it 'returns error for missing key' do
        location = described_class.new(path: '~/dev/project')

        expect(location.validate).to include('Key is required')
      end

      it 'returns error for uppercase key' do
        location = described_class.new(key: 'MyProject', path: '~/dev/project')

        errors = location.validate
        expect(errors.any? { |e| e.include?('invalid') }).to be true
      end

      it 'returns error for key starting with hyphen' do
        location = described_class.new(key: '-invalid', path: '~/dev/project')

        errors = location.validate
        expect(errors.any? { |e| e.include?('invalid') }).to be true
      end
    end

    context 'with invalid path' do
      it 'returns error for missing path' do
        location = described_class.new(key: 'my-project')

        expect(location.validate).to include('Path is required')
      end

      it 'returns error for relative path' do
        location = described_class.new(key: 'my-project', path: 'dev/project')

        errors = location.validate
        expect(errors.any? { |e| e.include?('Path') && e.include?('invalid') }).to be true
      end
    end

    context 'with invalid tags' do
      it 'returns error for uppercase tags' do
        location = described_class.new(key: 'my-project', path: '~/dev/project', tags: ['Ruby'])

        errors = location.validate
        expect(errors.any? { |e| e.include?('Tag') && e.include?('invalid') }).to be true
      end
    end
  end

  describe '#valid?' do
    it 'returns true for valid location' do
      location = described_class.new(key: 'ad-tools', path: '~/dev/project')

      expect(location.valid?).to be true
    end

    it 'returns false for invalid location' do
      location = described_class.new(key: 'Invalid', path: 'relative/path')

      expect(location.valid?).to be false
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      location = described_class.new(
        key: 'ad-tools',
        path: '~/dev/project',
        brand: 'appydave'
      )

      hash = location.to_h

      expect(hash[:key]).to eq('ad-tools')
      expect(hash[:path]).to eq('~/dev/project')
      expect(hash[:brand]).to eq('appydave')
    end

    it 'excludes nil values' do
      location = described_class.new(key: 'ad-tools', path: '~/dev/project')

      hash = location.to_h

      expect(hash).not_to have_key(:brand)
      expect(hash).not_to have_key(:client)
      expect(hash).not_to have_key(:description)
    end
  end

  describe '#searchable_terms' do
    it 'includes key, path, type, description' do
      location = described_class.new(
        key: 'ad-tools',
        path: '~/dev/project',
        type: 'tool',
        description: 'CLI tools'
      )

      terms = location.searchable_terms

      expect(terms).to include('ad-tools')
      expect(terms).to include('~/dev/project')
      expect(terms).to include('tool')
      expect(terms).to include('cli tools')
    end

    it 'includes tags' do
      location = described_class.new(
        key: 'ad-tools',
        path: '~/dev/project',
        tags: %w[ruby cli]
      )

      terms = location.searchable_terms

      expect(terms).to include('ruby')
      expect(terms).to include('cli')
    end

    it 'includes brand aliases when provided' do
      location = described_class.new(
        key: 'ad-tools',
        path: '~/dev/project',
        brand: 'appydave'
      )

      brands = {
        'appydave' => { 'aliases' => %w[ad appy] }
      }

      terms = location.searchable_terms(brands: brands)

      expect(terms).to include('appydave')
      expect(terms).to include('ad')
      expect(terms).to include('appy')
    end
  end
end
