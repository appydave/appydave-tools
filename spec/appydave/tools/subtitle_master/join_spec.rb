RSpec.describe Appydave::Tools::SubtitleMaster::Join do
  let(:fixtures_path) { File.expand_path('../../../fixtures/subtitle_master', __dir__) }
  let(:temp_folder) { Dir.mktmpdir }

  describe '#initialize' do
    it 'initializes with default values' do
      join = described_class.new
      expect(join).to be_a(described_class)
    end
  end

  describe '#join' do
    before do
      # Copy all SRT files from fixtures to temp directory for testing
      Dir[File.join(fixtures_path, '*.srt')].each do |file|
        FileUtils.cp(file, temp_folder)
      end
    end

    after do
      FileUtils.remove_entry temp_folder
    end

    context 'when a91-*.srt files are provided' do
      let(:files) { 'a91-*.srt' }
      let(:output_filename) { 'output-a91.srt' }

      fit 'processes SRT files using the parser' do
        join = described_class.new(
          folder: temp_folder,
          files: files,
          sort: 'inferred',           # Add the missing keyword argument
          buffer: 100,
          output: File.join(temp_folder, output_filename),
          log_level: :info            # Add log_level if needed or use a default
        )
        expect { join.join }.not_to raise_error

        open_in_vscode(temp_folder, output_filename)
      end
    end
  end

  def open_in_vscode(temp_folder, file)
    # Open the output file in VS Code
    system("code '#{File.join(temp_folder, file)}'")

    # Optional: add a small delay to ensure VS Code has time to open
    sleep 1
  end
end
