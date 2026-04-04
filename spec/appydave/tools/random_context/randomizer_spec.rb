# frozen_string_literal: true

RSpec.describe Appydave::Tools::RandomContext::Randomizer do
  let(:config_file) { Tempfile.new(['random-queries', '.yml']) }
  let(:config_path) { config_file.path }

  after { config_file.close! }

  def write_config(queries)
    File.write(config_path, { 'queries' => queries }.to_yaml)
  end

  def stub_executor(results_map)
    ->(command) { results_map.fetch(command, []) }
  end

  describe '#pick' do
    context 'when a query returns results in the good range' do
      let(:queries) do
        [{ 'label' => 'Find paperclip', 'command' => 'query_brain --find paperclip',
           'min_results' => 1, 'max_results' => 5 }]
      end

      before { write_config(queries) }

      it 'returns [entry, results] when result count is within range' do
        executor = stub_executor('query_brain --find paperclip' => ['/path/a.md', '/path/b.md'])
        randomizer = described_class.new(config_path: config_path, executor: executor)

        entry, results = randomizer.pick
        expect(entry.label).to eq('Find paperclip')
        expect(results).to eq(['/path/a.md', '/path/b.md'])
      end
    end

    context 'when result count is below min_results' do
      before do
        write_config([{ 'label' => 'Find paperclip', 'command' => 'query_brain --find paperclip',
                        'min_results' => 3, 'max_results' => 10 }])
      end

      it 'excludes the entry' do
        executor = stub_executor('query_brain --find paperclip' => ['/path/a.md'])
        expect(described_class.new(config_path: config_path, executor: executor).pick).to be_nil
      end
    end

    context 'when result count exceeds max_results' do
      before do
        write_config([{ 'label' => 'Find paperclip', 'command' => 'query_brain --find paperclip',
                        'min_results' => 1, 'max_results' => 2 }])
      end

      it 'excludes the entry' do
        executor = stub_executor('query_brain --find paperclip' => %w[/a /b /c /d /e])
        expect(described_class.new(config_path: config_path, executor: executor).pick).to be_nil
      end
    end

    context 'with multiple queries, only one in range' do
      let(:multi_queries) do
        [
          { 'label' => 'Too few', 'command' => 'cmd_a', 'min_results' => 5, 'max_results' => 10 },
          { 'label' => 'Just right', 'command' => 'cmd_b', 'min_results' => 1, 'max_results' => 5 },
          { 'label' => 'Too many', 'command' => 'cmd_c', 'min_results' => 1, 'max_results' => 2 }
        ]
      end

      before do
        write_config(multi_queries)
      end

      it 'only picks from entries with good result counts' do
        executor = stub_executor('cmd_a' => [], 'cmd_b' => %w[/x.md /y.md], 'cmd_c' => %w[/a /b /c /d /e /f])
        entry, _results = described_class.new(config_path: config_path, executor: executor).pick
        expect(entry.label).to eq('Just right')
      end

      it 'returns nil when no queries have good result counts' do
        executor = stub_executor('cmd_a' => [], 'cmd_b' => [], 'cmd_c' => [])
        expect(described_class.new(config_path: config_path, executor: executor).pick).to be_nil
      end
    end

    context 'when config has no queries key' do
      it 'returns nil without error' do
        File.write(config_path, {}.to_yaml)
        expect(described_class.new(config_path: config_path, executor: ->(_cmd) { [] }).pick).to be_nil
      end
    end

    context 'when config file does not exist and bootstrap is disabled' do
      it 'raises an error' do
        expect { described_class.new(config_path: '/nonexistent/path.yml').pick }
          .to raise_error(/Config not found/)
      end
    end
  end

  describe 'bootstrap' do
    it 'copies bundled config to user config path when it does not exist' do
      Dir.mktmpdir do |tmpdir|
        user_config = File.join(tmpdir, 'random-queries.yml')
        bundled = Tempfile.new(['bundled', '.yml'])
        File.write(bundled.path, { 'queries' => [] }.to_yaml)

        described_class.new(
          config_path: user_config,
          bundled_config_path: bundled.path,
          bootstrap: true,
          executor: ->(_cmd) { [] }
        ).pick

        expect(File.exist?(user_config)).to be true
        bundled.close!
      end
    end

    it 'creates parent directories as needed' do
      Dir.mktmpdir do |tmpdir|
        user_config = File.join(tmpdir, 'nested', 'dir', 'random-queries.yml')
        bundled = Tempfile.new(['bundled', '.yml'])
        File.write(bundled.path, { 'queries' => [] }.to_yaml)

        described_class.new(
          config_path: user_config,
          bundled_config_path: bundled.path,
          bootstrap: true,
          executor: ->(_cmd) { [] }
        ).pick

        expect(File.exist?(user_config)).to be true
        bundled.close!
      end
    end
  end

  describe '#run' do
    context 'when a candidate is found' do
      before do
        write_config([{ 'label' => 'Recent TIL sessions', 'command' => 'query_omi --routing til',
                        'min_results' => 1, 'max_results' => 5 }])
      end

      it 'prints the question label and results' do
        executor = stub_executor('query_omi --routing til' => ['/omi/session1.md'])
        output = capture_stdout { described_class.new(config_path: config_path, executor: executor).run }
        expect(output).to include('Question: "Recent TIL sessions"')
        expect(output).to include('/omi/session1.md')
      end

      it 'appends --meta to command when meta: true' do
        calls = []
        executor = lambda do |command|
          calls << command
          ['/omi/session1.md']
        end
        capture_stdout { described_class.new(config_path: config_path, meta: true, executor: executor).run }
        expect(calls).to include('query_omi --routing til --meta')
      end

      it 'does not append --meta when meta: false' do
        calls = []
        executor = lambda do |command|
          calls << command
          ['/omi/session1.md']
        end
        capture_stdout { described_class.new(config_path: config_path, meta: false, executor: executor).run }
        expect(calls.any? { |c| c.end_with?('--meta') }).to be false
      end
    end

    context 'when no candidates are found' do
      before do
        write_config([{ 'label' => 'Nothing', 'command' => 'cmd_empty',
                        'min_results' => 1, 'max_results' => 5 }])
      end

      it 'prints a friendly no-results message' do
        output = capture_stdout { described_class.new(config_path: config_path, executor: stub_executor({})).run }
        expect(output).to include('No matching queries found')
      end
    end
  end

  describe Appydave::Tools::RandomContext::QueryEntry do
    subject { described_class.new({ 'label' => 'x', 'command' => 'y', 'min_results' => 2, 'max_results' => 5 }) }

    describe '#good_count?' do
      it { expect(subject.good_count?(3)).to be true }
      it { expect(subject.good_count?(2)).to be true }  # lower boundary
      it { expect(subject.good_count?(5)).to be true }  # upper boundary
      it { expect(subject.good_count?(1)).to be false } # below min
      it { expect(subject.good_count?(6)).to be false } # above max
    end

    describe 'defaults' do
      subject { described_class.new({ 'label' => 'x', 'command' => 'y' }) }

      it { expect(subject.min_results).to eq(1) }
      it { expect(subject.max_results).to eq(15) }
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
