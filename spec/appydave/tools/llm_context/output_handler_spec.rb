# frozen_string_literal: true

RSpec.describe Appydave::Tools::LlmContext::OutputHandler do
  subject { described_class.new(content, options) }

  let(:content) { 'Sample content' }
  let(:options) { Appydave::Tools::LlmContext::Options.new(output_target: ['clipboard'], working_directory: Dir.pwd) }

  describe '#execute' do
    it 'copies content to clipboard when output target is clipboard' do
      allow(Clipboard).to receive(:copy)
      subject.execute
      expect(Clipboard).to have_received(:copy).with(content)
    end

    context 'when output target is a file' do
      let(:options) { Appydave::Tools::LlmContext::Options.new(output_target: ['output.txt'], working_directory: Dir.pwd) }

      it 'writes content to the specified file' do
        allow(File).to receive(:write)
        subject.execute
        expect(File).to have_received(:write).with(File.join(Dir.pwd, 'output.txt'), content)
      end
    end

    context 'when output target is temp' do
      let(:options) { Appydave::Tools::LlmContext::Options.new(output_target: ['temp'], working_directory: Dir.pwd) }

      it 'writes content to a file in system temp directory' do
        file_path = nil
        allow(Clipboard).to receive(:copy) { |arg| file_path = arg }

        subject.execute

        # Verify file was created in tmpdir
        expect(file_path).to include(Dir.tmpdir)
        expect(File.exist?(file_path)).to be true
        # Clean up
        FileUtils.rm_f(file_path)
      end

      it 'copies the file path (not content) to clipboard' do
        clipboard_arg = nil
        allow(Clipboard).to receive(:copy) { |arg| clipboard_arg = arg }

        subject.execute

        # The call to Clipboard.copy should receive a path string, not the original content
        expect(clipboard_arg).not_to eq(content) # path, not content
        expect(clipboard_arg).to be_a(String)
        expect(clipboard_arg).to match(/llm_context-\d{8}-\d{6}-\d{3}\.txt/) # temp file path with timestamp

        # Clean up
        FileUtils.rm_f(clipboard_arg)
      end

      it 'writes the file to disk with content' do
        file_path = nil
        allow(Clipboard).to receive(:copy) { |arg| file_path = arg }

        subject.execute

        # Verify that a file was created with our content
        expect(File.exist?(file_path)).to be true
        expect(File.read(file_path)).to eq(content)
        # Clean up
        FileUtils.rm_f(file_path)
      end
    end

    context 'when multiple output targets are specified' do
      let(:options) { Appydave::Tools::LlmContext::Options.new(output_target: ['clipboard', 'output.txt'], working_directory: Dir.pwd) }

      it 'copies content to clipboard and writes to file' do
        allow(Clipboard).to receive(:copy)
        allow(File).to receive(:write)
        subject.execute
        expect(Clipboard).to have_received(:copy).with(content)
        expect(File).to have_received(:write).with(File.join(Dir.pwd, 'output.txt'), content)
      end
    end

    context 'when temp and clipboard targets are specified' do
      let(:options) { Appydave::Tools::LlmContext::Options.new(output_target: %w[temp clipboard], working_directory: Dir.pwd) }

      it 'writes to file and copies content to clipboard' do
        clipboard_calls = []
        allow(Clipboard).to receive(:copy) { |arg| clipboard_calls << arg }

        subject.execute

        # First call to clipboard should be the file path, second should be the content
        expect(clipboard_calls.size).to eq(2)
        expect(clipboard_calls[0]).to match(/llm_context-\d{8}-\d{6}-\d{3}\.txt/) # temp file path
        expect(clipboard_calls[1]).to eq(content) # actual content

        # Clean up
        FileUtils.rm_f(clipboard_calls[0])
      end
    end
  end
end
