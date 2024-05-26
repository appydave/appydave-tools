# frozen_string_literal: true

require 'rspec'
require 'tmpdir'

RSpec.describe Appydave::Tools::Configuration::Config do
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_base_path) { File.join(temp_folder, '.config/appydave') }

  after do
    FileUtils.remove_entry(temp_folder)
  end

  # describe '.load' do
  #   it 'loads configuration for all components' do
  #     # allow_any_instance_of(Appydave::Tools::Configuration::ConfigBase).to receive(:load_config)
  #     # described_class.load
  #     # expect(Appydave::Tools::Configuration::ConfigBase).to have_received(:load_config).at_least(:once)
  #   end
  # end

  # describe '.save' do
  #   it 'saves all modified configurations' do
  #     # allow_any_instance_of(Appydave::Tools::Configuration::ConfigBase).to receive(:save)
  #     # described_class.save
  #     # expect(Appydave::Tools::Configuration::ConfigBase).to have_received(:save).at_least(:once)
  #   end
  # end

  describe '.edit' do
    before do
      described_class.configure do |config|
        config.config_path = config_base_path
      end
    end

    it 'opens the configuration directory in the default editor' do
      allow(Open3).to receive(:capture3).and_return(['output from vscode', '', instance_double(Process::Status, exitstatus: 0)])

      expect { described_class.edit }.to output("Edit configuration: #{config_base_path}\n").to_stdout

      expect(Open3).to have_received(:capture3).with("code  --folder-uri '#{config_base_path}'")
    end
  end

  context 'when configuring a new component' do
    before do
      described_class.configure do |config|
        config.config_path = config_base_path
        config.register(:component1, Appydave::Tools::Configuration::Models::ConfigBase)
      end
    end

    it 'registers the component configuration' do
      expect(described_class.component1).to be_an_instance_of(Appydave::Tools::Configuration::Models::ConfigBase)
    end

    it 'responds to the component method' do
      expect(described_class.respond_to?(:component1)).to be(true)
    end

    it 'does not respond to an unknown method' do
      expect(described_class.respond_to?(:unknown_component)).to be(false)
    end
  end

  context 'when configuring child components' do
    context 'with settings component' do
      before do
        described_class.configure do |config|
          config.config_path = config_base_path
          config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
        end
      end

      it 'registers the settings configuration' do
        expect(described_class.settings).to be_an_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
      end

      describe '.settings' do
        let(:settings) { described_class.settings }

        context 'when loading the settings' do
          it 'loads the settings' do
            settings.load
            expect(settings.data).to eq({})
          end

          context 'when setting a new value' do
            it 'sets a new value' do
              settings.set('email', 'appydave@appydave.com')
              expect(settings.get('email')).to eq('appydave@appydave.com')
            end

            context 'when forgetting to save the settings' do
              it 'does not persist the changes' do
                settings.load
                expect(settings.get('email')).to be_nil
              end

              context 'when saving the settings' do
                it 'persists the changes' do
                  settings.set('email', 'appydavecoding@appydave.com')
                  settings.save

                  reloaded_settings = Appydave::Tools::Configuration::Models::SettingsConfig.new
                  expect(reloaded_settings.get('email')).to eq('appydavecoding@appydave.com')
                end
              end
            end
          end
        end
      end
    end

    context 'with channels component' do
      before do
        described_class.configure do |config|
          config.config_path = config_base_path
          config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
        end
      end

      it 'registers the channels configuration' do
        expect(described_class.channels).to be_an_instance_of(Appydave::Tools::Configuration::Models::ChannelsConfig)
      end

      describe '.channels' do
        let(:channels) { described_class.channels }

        context 'when loading the channels' do
          it 'loads the channels' do
            channels.load
            expect(channels.data).to eq({ 'channels' => {} })
          end

          context 'when setting new channel information' do
            it 'sets new channel information' do
              new_channel_info = Appydave::Tools::Configuration::Models::ChannelsConfig::ChannelInfo.new('nc',
                                                                                                         'code' => 'nc',
                                                                                                         'name' => 'New Channel',
                                                                                                         'youtube_handle' => '@newchannel')

              channels.set_channel('nc', new_channel_info)
              channels.save

              reloaded_channels = Appydave::Tools::Configuration::Models::ChannelsConfig.new
              reloaded_channel_info = reloaded_channels.get_channel('nc')

              expect(reloaded_channel_info.name).to eq('New Channel')
              expect(reloaded_channel_info.youtube_handle).to eq('@newchannel')
            end
          end
        end
      end
    end

    context 'with channel projects component' do
      before do
        described_class.configure do |config|
          config.config_path = config_base_path
          config.register(:channel_projects, Appydave::Tools::Configuration::Models::ChannelProjectsConfig)
        end
      end

      it 'registers the channel projects configuration' do
        expect(described_class.channel_projects).to be_an_instance_of(Appydave::Tools::Configuration::Models::ChannelProjectsConfig)
      end

      describe '.channel_projects' do
        let(:channel_projects) { described_class.channel_projects }

        context 'when loading the channel projects' do
          it 'loads the channel projects' do
            channel_projects.load
            expect(channel_projects.data).to eq({ 'channel_projects' => {} })
          end

          context 'when setting new channel project information' do
            it 'sets new channel project information' do
              new_channel_info = Appydave::Tools::Configuration::Models::ChannelProjectsConfig::ChannelInfo.new(
                'content_projects' => '/new/path/to/dropbox/folder',
                'video_projects' => '/new/path/to/active/projects',
                'published_projects' => '/new/path/to/published/archive',
                'abandoned_projects' => '/new/path/to/failed/archive'
              )

              channel_projects.set_channel_info('new_channel', new_channel_info)
              channel_projects.save

              reloaded_channel_projects = Appydave::Tools::Configuration::Models::ChannelProjectsConfig.new
              reloaded_channel_info = reloaded_channel_projects.get_channel_info('new_channel')

              expect(reloaded_channel_info.content_projects).to eq('/new/path/to/dropbox/folder')
              expect(reloaded_channel_info.video_projects).to eq('/new/path/to/active/projects')
              expect(reloaded_channel_info.published_projects).to eq('/new/path/to/published/archive')
              expect(reloaded_channel_info.abandoned_projects).to eq('/new/path/to/failed/archive')
            end
          end
        end
      end
    end
  end
end
