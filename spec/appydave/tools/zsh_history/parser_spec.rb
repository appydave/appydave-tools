# frozen_string_literal: true

RSpec.describe Appydave::Tools::ZshHistory::Parser do
  let(:fixtures_path) { File.expand_path('../../../fixtures/zsh_history', __dir__) }
  let(:simple_history_path) { File.join(fixtures_path, 'simple_history.txt') }
  let(:multiline_history_path) { File.join(fixtures_path, 'multiline_history.txt') }
  let(:empty_history_path) { File.join(fixtures_path, 'empty_history.txt') }

  describe '#initialize' do
    it 'uses provided file path' do
      parser = described_class.new(simple_history_path)
      expect(parser.file_path).to eq(simple_history_path)
    end

    it 'defaults to ~/.zsh_history when no path provided' do
      parser = described_class.new
      expect(parser.file_path).to eq(File.expand_path('~/.zsh_history'))
    end
  end

  describe '#parse' do
    context 'with simple history file' do
      let(:parser) { described_class.new(simple_history_path) }

      it 'parses all commands' do
        commands = parser.parse
        expect(commands.size).to eq(6)
      end

      it 'extracts correct command text' do
        commands = parser.parse
        expect(commands[0].text).to eq('git status')
        expect(commands[1].text).to eq('ls -la')
        expect(commands[3].text).to eq('bundle install')
      end

      it 'extracts correct timestamps' do
        commands = parser.parse
        expect(commands[0].timestamp).to eq(1_702_483_200)
        expect(commands[0].datetime).to eq(Time.at(1_702_483_200))
      end

      it 'marks single-line commands correctly' do
        commands = parser.parse
        expect(commands.all? { |cmd| cmd.is_multiline == false }).to be true
      end
    end

    context 'with multi-line commands' do
      let(:parser) { described_class.new(multiline_history_path) }

      it 'parses all commands including multi-line' do
        commands = parser.parse
        expect(commands.size).to eq(5)
      end

      it 'joins multi-line commands' do
        commands = parser.parse
        docker_cmd = commands[1]

        expect(docker_cmd.is_multiline).to be true
        expect(docker_cmd.text).to include('docker run')
        expect(docker_cmd.text).to include('nginx:latest')
      end

      it 'preserves raw lines for multi-line commands' do
        commands = parser.parse
        docker_cmd = commands[1]

        expect(docker_cmd.raw_lines.size).to eq(4)
      end
    end

    context 'with empty file' do
      let(:parser) { described_class.new(empty_history_path) }

      it 'returns empty array' do
        commands = parser.parse
        expect(commands).to eq([])
      end
    end

    context 'with non-existent file' do
      let(:parser) { described_class.new('/non/existent/path') }

      it 'returns empty array' do
        commands = parser.parse
        expect(commands).to eq([])
      end
    end
  end

  describe 'Command struct' do
    let(:command) do
      Appydave::Tools::ZshHistory::Command.new(
        timestamp: 1_702_483_200,
        datetime: Time.at(1_702_483_200),
        text: 'git status',
        is_multiline: false,
        category: nil,
        raw_lines: [': 1702483200:0;git status'],
        matched_pattern: nil
      )
    end

    describe '#formatted_datetime' do
      it 'formats datetime with default format' do
        expect(command.formatted_datetime).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'formats datetime with custom format' do
        expect(command.formatted_datetime('%Y-%m-%d')).to match(/\d{4}-\d{2}-\d{2}/)
      end
    end

    describe '#to_history_format' do
      it 'returns raw lines joined by newline' do
        expect(command.to_history_format).to eq(': 1702483200:0;git status')
      end
    end
  end
end
