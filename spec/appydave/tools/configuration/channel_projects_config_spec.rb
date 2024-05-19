# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::ChannelProjectsConfig do
  let(:channel_projects) { described_class.new }
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'channel-projects.json') }
  let(:config_data) do
    {
      'channel_projects' => {
        'appydave' => {
          'content_projects' => '/somepath/Dropbox/team-appydave',
          'video_projects' => '/somepath/tube-channels/appy-dave/active',
          'published_projects' => '/somepath/content-archive/published',
          'abandoned_projects' => '/somepath/content-archive/failed'
        },
        'appydave_coding' => {
          'content_projects' => '/somepath/Dropbox/team-appydavecoding',
          'video_projects' => '/somepath/tube-channels/appy-dave/active',
          'published_projects' => '/somepath/content-archive/published/coding',
          'abandoned_projects' => '/somepath/content-archive/failed/coding'
        }
      }
    }
  end

  before do
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
    File.write(config_file, config_data.to_json)
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#initialize' do
    describe '.name' do
      subject { channel_projects.name }

      it { is_expected.to eq('ChannelProjects') }
    end

    describe '.config_name' do
      subject { channel_projects.config_name }

      it { is_expected.to eq('channel-projects') }
    end

    describe '.config_path' do
      subject { channel_projects.config_path }

      it { is_expected.to eq(config_file) }
    end

    describe '.data' do
      subject { channel_projects.data }

      it { is_expected.to eq(config_data) }
    end
  end

  describe '#get_channel_info' do
    it 'retrieves existing channel information by string name' do
      channel_info = channel_projects.get_channel_info('appydave')

      expect(channel_info.content_projects).to eq('/somepath/Dropbox/team-appydave')
      expect(channel_info.video_projects).to eq('/somepath/tube-channels/appy-dave/active')
      expect(channel_info.published_projects).to eq('/somepath/content-archive/published')
      expect(channel_info.abandoned_projects).to eq('/somepath/content-archive/failed')
    end

    it 'retrieves existing channel information by symbol name' do
      channel_info = channel_projects.get_channel_info(:appydave)

      expect(channel_info.content_projects).to eq('/somepath/Dropbox/team-appydave')
      expect(channel_info.video_projects).to eq('/somepath/tube-channels/appy-dave/active')
      expect(channel_info.published_projects).to eq('/somepath/content-archive/published')
      expect(channel_info.abandoned_projects).to eq('/somepath/content-archive/failed')
    end

    it 'returns default channel information for a non-existent channel' do
      channel_info = channel_projects.get_channel_info('nonexistent_channel')

      expect(channel_info.content_projects).to eq('')
      expect(channel_info.video_projects).to eq('')
      expect(channel_info.published_projects).to eq('')
      expect(channel_info.abandoned_projects).to eq('')
    end
  end

  describe '#set_channel_info' do
    let(:new_channel_info) do
      Appydave::Tools::Configuration::ChannelProjectsConfig::ChannelInfo.new(
        'content_projects' => '/new/path/to/dropbox/folder',
        'video_projects' => '/new/path/to/active/projects',
        'published_projects' => '/new/path/to/published/archive',
        'abandoned_projects' => '/new/path/to/failed/archive'
      )
    end

    it 'sets new channel information and persists it' do
      channel_projects.set_channel_info('new_channel', new_channel_info)
      channel_projects.save

      reloaded_channel_projects = described_class.new
      reloaded_channel_info = reloaded_channel_projects.get_channel_info('new_channel')

      expect(reloaded_channel_info.content_projects).to eq('/new/path/to/dropbox/folder')
      expect(reloaded_channel_info.video_projects).to eq('/new/path/to/active/projects')
      expect(reloaded_channel_info.published_projects).to eq('/new/path/to/published/archive')
      expect(reloaded_channel_info.abandoned_projects).to eq('/new/path/to/failed/archive')
    end
  end

  describe '#channel_projects' do
    subject { channel_projects.channel_projects }

    it { is_expected.to have_attributes(length: 2) }
  end
end
