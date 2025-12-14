# frozen_string_literal: true

RSpec.describe Appydave::Tools::ZshHistory::Filter do
  let(:filter) { described_class.new }

  def make_command(text:, timestamp: Time.now.to_i)
    Appydave::Tools::ZshHistory::Command.new(
      timestamp: timestamp,
      datetime: Time.at(timestamp),
      text: text,
      is_multiline: false,
      category: nil,
      raw_lines: [": #{timestamp}:0;#{text}"],
      matched_pattern: nil
    )
  end

  describe '#initialize' do
    it 'uses default patterns when none provided' do
      expect(filter.exclude_patterns).not_to be_empty
      expect(filter.include_patterns).not_to be_empty
    end

    it 'accepts custom patterns' do
      custom_filter = described_class.new(
        exclude_patterns: ['^custom_exclude'],
        include_patterns: ['^custom_include']
      )

      expect(custom_filter.exclude_patterns.size).to eq(1)
      expect(custom_filter.include_patterns.size).to eq(1)
    end
  end

  describe '#apply' do
    context 'with default patterns' do
      let(:commands) do
        [
          make_command(text: 'git commit -m "test"'), # wanted - git commit
          make_command(text: 'ls'),                   # unwanted - simple ls
          make_command(text: 'docker run nginx'),       # wanted - docker
          make_command(text: 'vim file.txt'),           # unsure - no match
          make_command(text: 'claude help')             # wanted - claude
        ]
      end

      it 'categorizes commands correctly' do
        result = filter.apply(commands)

        expect(result.wanted.map(&:text)).to include('git commit -m "test"')
        expect(result.wanted.map(&:text)).to include('docker run nginx')
        expect(result.wanted.map(&:text)).to include('claude help')
        expect(result.unwanted.map(&:text)).to include('ls')
        expect(result.unsure.map(&:text)).to include('vim file.txt')
      end

      it 'sets category on each command' do
        result = filter.apply(commands)

        result.wanted.each { |cmd| expect(cmd.category).to eq(:wanted) }
        result.unwanted.each { |cmd| expect(cmd.category).to eq(:unwanted) }
        result.unsure.each { |cmd| expect(cmd.category).to eq(:unsure) }
      end

      it 'returns stats' do
        result = filter.apply(commands)

        expect(result.stats[:total]).to eq(5)
        expect(result.stats[:wanted]).to eq(3)
        expect(result.stats[:unwanted]).to eq(1)
        expect(result.stats[:unsure]).to eq(1)
      end
    end

    context 'with date filtering' do
      let(:old_time) { (Time.now - (10 * 24 * 60 * 60)).to_i } # 10 days ago
      let(:recent_time) { (Time.now - (2 * 24 * 60 * 60)).to_i } # 2 days ago

      let(:commands) do
        [
          make_command(text: 'git status', timestamp: old_time),
          make_command(text: 'docker run nginx', timestamp: recent_time),
          make_command(text: 'claude help', timestamp: Time.now.to_i)
        ]
      end

      it 'filters by date when days specified' do
        result = filter.apply(commands, days: 5)

        expect(result.wanted.size).to eq(2)
        expect(result.unwanted.size).to eq(0)
      end

      it 'includes all commands when days not specified' do
        result = filter.apply(commands)

        expect(result.stats[:total]).to eq(3)
      end
    end
  end

  describe '#filter_by_date' do
    let(:old_time) { (Time.now - (10 * 24 * 60 * 60)).to_i }
    let(:recent_time) { (Time.now - (2 * 24 * 60 * 60)).to_i }

    let(:commands) do
      [
        make_command(text: 'old', timestamp: old_time),
        make_command(text: 'recent', timestamp: recent_time)
      ]
    end

    it 'returns all commands when days is nil' do
      result = filter.filter_by_date(commands, nil)
      expect(result.size).to eq(2)
    end

    it 'filters commands older than specified days' do
      result = filter.filter_by_date(commands, 5)
      expect(result.size).to eq(1)
      expect(result.first.text).to eq('recent')
    end
  end

  describe 'exclude patterns' do
    it 'excludes single letter commands' do
      result = filter.apply([make_command(text: 'x')])
      expect(result.unwanted.size).to eq(1)
    end

    it 'excludes git status' do
      result = filter.apply([make_command(text: 'git status')])
      expect(result.unwanted.size).to eq(1)
    end

    it 'excludes ls commands' do
      result = filter.apply([make_command(text: 'ls -la')])
      expect(result.unwanted.size).to eq(1)
    end

    it 'excludes cd commands' do
      result = filter.apply([make_command(text: 'cd ..')])
      expect(result.unwanted.size).to eq(1)
    end
  end

  describe 'include patterns' do
    it 'includes git commit' do
      result = filter.apply([make_command(text: 'git commit -m "message"')])
      expect(result.wanted.size).to eq(1)
    end

    it 'includes docker commands' do
      result = filter.apply([make_command(text: 'docker build .')])
      expect(result.wanted.size).to eq(1)
    end

    it 'includes claude commands' do
      result = filter.apply([make_command(text: 'claude --help')])
      expect(result.wanted.size).to eq(1)
    end

    it 'includes dam commands' do
      result = filter.apply([make_command(text: 'dam list appydave')])
      expect(result.wanted.size).to eq(1)
    end

    it 'includes rake commands' do
      result = filter.apply([make_command(text: 'rake spec')])
      expect(result.wanted.size).to eq(1)
    end

    it 'includes bundle commands' do
      result = filter.apply([make_command(text: 'bundle install')])
      expect(result.wanted.size).to eq(1)
    end
  end

  describe 'FilterResult struct' do
    let(:result) do
      Appydave::Tools::ZshHistory::FilterResult.new(
        wanted: [make_command(text: 'wanted')],
        unwanted: [make_command(text: 'unwanted')],
        unsure: [make_command(text: 'unsure')],
        stats: { total: 3, wanted: 1, unwanted: 1, unsure: 1 }
      )
    end

    it 'holds wanted commands' do
      expect(result.wanted.first.text).to eq('wanted')
    end

    it 'holds unwanted commands' do
      expect(result.unwanted.first.text).to eq('unwanted')
    end

    it 'holds unsure commands' do
      expect(result.unsure.first.text).to eq('unsure')
    end

    it 'holds stats' do
      expect(result.stats[:total]).to eq(3)
    end
  end
end
