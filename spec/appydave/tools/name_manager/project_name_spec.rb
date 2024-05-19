# frozen_string_literal: true

RSpec.describe Appydave::Tools::NameManager::ProjectName do
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'channels.json') }
  let(:channels_data) do
    {
      'channels' => {
        'something' => {
          'code' => 'xmen'
        }
      }
    }
  end

  before do
    File.write(config_file, channels_data.to_json)
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
      config.register(:channels, Appydave::Tools::Configuration::ChannelsConfig)
    end
  end

  describe '#initialize' do
    subject { instance }

    let(:instance) { described_class.new(file_name) }

    context 'when channel code is present' do
      let(:file_name) { 'a27-xmen-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'xmen', project_name: 'my-video-project') }
    end

    context 'when channel code is not present' do
      let(:file_name) { 'a27-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: nil, project_name: 'my-video-project') }
    end

    context 'when absolute file path' do
      let(:file_name) { '/path/to/a27-xmen-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'xmen', project_name: 'my-video-project') }
    end

    context 'when relative file path' do
      let(:file_name) { 'path/to/a27-xmen-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'xmen', project_name: 'my-video-project') }
    end
  end
end
