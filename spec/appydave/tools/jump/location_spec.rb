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

    # Regression: to_h used to emit only 8 keys, so `jump update` silently
    # destroyed status/context/git_remote/notes on every entry that had them.
    it 'round-trips every schema field, not just the core eight' do
      attrs = {
        key: 'ss-legacy',
        path: '~/dev/clients/supportsignal/legacy',
        jump: 'jss-legacy',
        client: 'supportsignal',
        type: 'product',
        status: 'deprecated',
        tags: %w[nextjs legacy],
        description: 'SupportSignal legacy application',
        git_remote: 'git@github.com:SupportSignal/legacy.git',
        context: 'CONTEXT.md',
        notes: 'Superseded by the BMAD v6 rebuild'
      }

      expect(described_class.new(attrs).to_h).to eq(attrs)
    end

    it 'orders keys to match the on-disk locations.json convention' do
      location = described_class.new(
        key: 'k', path: '~/p', type: 'tool', status: 'active',
        tags: ['x'], description: 'd', git_remote: 'url', context: 'CONTEXT.md', notes: 'n'
      )

      expect(location.to_h.keys).to eq(
        %i[key path jump type status tags description git_remote context notes]
      )
    end

    context 'with the tri-state git_remote' do
      def hash_for(attrs)
        described_class.new({ key: 'k', path: '~/p' }.merge(attrs)).to_h
      end

      it 'keeps a remote URL' do
        expect(hash_for(git_remote: 'git@github.com:a/b.git')[:git_remote])
          .to eq('git@github.com:a/b.git')
      end

      # nil means "a git repo with no remote backup" — semantically distinct
      # from the key being absent, which means "not a git repo at all".
      it 'preserves an explicit nil rather than compacting it away' do
        hash = hash_for(git_remote: nil)

        expect(hash).to have_key(:git_remote)
        expect(hash[:git_remote]).to be_nil
      end

      it 'omits the key entirely when it was never supplied' do
        expect(hash_for({})).not_to have_key(:git_remote)
      end

      it 'reports whether git_remote was supplied' do
        expect(described_class.new(key: 'k', path: '~/p', git_remote: nil)).to be_git_remote_given
        expect(described_class.new(key: 'k', path: '~/p')).not_to be_git_remote_given
      end
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
