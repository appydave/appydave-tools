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
      described_class.reset
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
      described_class.reset
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
        described_class.reset
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
        described_class.reset
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
                                                                                                         'youtube_handle' => '@newchannel',
                                                                                                         'locations' => {
                                                                                                           'content_projects' => '/path/to/content/projects',
                                                                                                           'video_projects' => '/path/to/video/projects',
                                                                                                           'published_projects' => '/path/to/published/projects',
                                                                                                           'abandoned_projects' => '/path/to/abandoned/projects'
                                                                                                         })

              channels.set_channel('nc', new_channel_info)
              channels.save

              reloaded_channels = Appydave::Tools::Configuration::Models::ChannelsConfig.new
              reloaded_channel_info = reloaded_channels.get_channel('nc')

              expect(reloaded_channel_info.name).to eq('New Channel')
              expect(reloaded_channel_info.youtube_handle).to eq('@newchannel')

              expect(reloaded_channel_info.locations.content_projects).to eq('/path/to/content/projects')
              expect(reloaded_channel_info.locations.video_projects).to eq('/path/to/video/projects')
              expect(reloaded_channel_info.locations.published_projects).to eq('/path/to/published/projects')
              expect(reloaded_channel_info.locations.abandoned_projects).to eq('/path/to/abandoned/projects')
            end
          end
        end
      end
    end

    # context 'with bank reconciliation component' do
    #   before do
    #     described_class.configure do |config|
    #       config.config_path = config_base_path
    #       config.register(:bank_reconciliation, Appydave::Tools::Configuration::Models::BankReconciliationConfig)
    #     end
    #   end

    #   it 'registers the bank reconciliation configuration' do
    #     expect(described_class.bank_reconciliation).to be_an_instance_of(Appydave::Tools::Configuration::Models::BankReconciliationConfig)
    #   end

    #   describe '.bank_reconciliation' do
    #     let(:bank_reconciliation) { described_class.bank_reconciliation }

    #     context 'when loading the bank reconciliation' do
    #       it 'loads the bank reconciliation' do
    #         bank_reconciliation.load
    #         expect(bank_reconciliation.data).to eq({ 'bank_accounts' => [], 'chart_of_accounts' => [] })
    #       end
    #     end
    #   end
    # end
  end
end
