# frozen_string_literal: true

RSpec.describe Appydave::Tools::NameManager::ProjectName do
  let(:project) { described_class.new(file_name) }
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'channels.json') }
  let(:channels_data) do
    {
      'channels' => {
        'some_channel' => {
          'code' => 'xmen'
        },
        'another_channel' => {
          'code' => 'x'
        }
      }
    }
  end

  before do
    File.write(config_file, channels_data.to_json)
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
      config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
    end
  end

  describe '#initialize' do
    subject { project }

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

  describe '#generate_name' do
    subject { project.generate_name }

    let(:file_name) { 'a27-xmen-aa-bbb-cccc' }

    it { is_expected.to eq('a27-xmen-aa-bbb-cccc') }

    context 'when sequence is changed' do
      before { project.sequence = 'a28' }

      it { is_expected.to eq('a28-xmen-aa-bbb-cccc') }
    end

    context 'when channel code is changed' do
      before { project.channel_code = 'x' }

      it { is_expected.to eq('a27-x-aa-bbb-cccc') }
    end

    context 'when channel code is nil' do
      before { project.channel_code = nil }

      it { is_expected.to eq('a27-aa-bbb-cccc') }
    end

    context 'when channel code is invalid' do
      before { project.channel_code = 'invalid' }

      it { is_expected.to eq('a27-aa-bbb-cccc') }
    end

    context 'when project name is changed' do
      before { project.project_name = 'my-new-project' }

      it { is_expected.to eq('a27-xmen-my-new-project') }
    end
  end
end
