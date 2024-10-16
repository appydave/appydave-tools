# frozen_string_literal: true

RSpec.describe Appydave::Tools::GptContext::OutputHandler do
  subject { described_class.new(content, options) }

  let(:content) { 'Sample content' }
  let(:options) { Appydave::Tools::GptContext::Options.new(output_target: ['clipboard'], working_directory: Dir.pwd) }

  describe '#execute' do
    it 'copies content to clipboard when output target is clipboard' do
      allow(Clipboard).to receive(:copy)
      subject.execute
      expect(Clipboard).to have_received(:copy).with(content)
    end

    context 'when output target is a file' do
      let(:options) { Appydave::Tools::GptContext::Options.new(output_target: ['output.txt'], working_directory: Dir.pwd) }

      it 'writes content to the specified file' do
        allow(File).to receive(:write)
        subject.execute
        expect(File).to have_received(:write).with(File.join(Dir.pwd, 'output.txt'), content)
      end
    end

    context 'when multiple output targets are specified' do
      let(:options) { Appydave::Tools::GptContext::Options.new(output_target: ['clipboard', 'output.txt'], working_directory: Dir.pwd) }

      it 'copies content to clipboard and writes to file' do
        allow(Clipboard).to receive(:copy)
        allow(File).to receive(:write)
        subject.execute
        expect(Clipboard).to have_received(:copy).with(content)
        expect(File).to have_received(:write).with(File.join(Dir.pwd, 'output.txt'), content)
      end
    end
  end
end
