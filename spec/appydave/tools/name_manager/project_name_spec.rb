# frozen_string_literal: true

Appydave::Tools::Configuration::Config.configure do |config|
  config.config_path = File.expand_path('~/.config/appydave') # optional, as this is already the default
  config.register(:settings, Appydave::Tools::Configuration::SettingsConfig)
  config.register(:channels, Appydave::Tools::Configuration::ChannelsConfig)
  config.register(:channel_projects, Appydave::Tools::Configuration::ChannelProjectsConfig)
end

Appydave::Tools::Configuration::Config.load
Appydave::Tools::Configuration::Config.debug

RSpec.describe Appydave::Tools::NameManager::ProjectName do
  describe '#initialize' do
    let(:instance) { described_class.new(file_name) }

    context 'with absolute file path' do
      let(:file_name) { '/path/to/a27-ac-categorize-mp4.mp4' }

      describe '#sequence' do
        subject { instance.sequence }

        it { is_expected.to eq('a27') }
      end

      # describe '#channel_code' do
      #   subject { instance.channel_code }

      #   it { is_expected.to eq('ac') }
      # end

      # it 'parses the file name correctly' do
      #   project = described_class.new('/path/to/a27-ac-categorize-mp4.mp4')
      #   expect(project.sequence).to eq('a27')
      #   expect(project.channel_code).to eq('ac')e
      #   expect(project.project_name).to eq('categorize-mp4')
      # end
    end
  end
  #   context 'with relative file path' do
  #     it 'parses the file name correctly' do
  #       project = ProjectName.new('relative/path/a27-categorize-mp4.mp4')
  #       expect(project.sequence).to eq('a27')
  #       expect(project.channel_code).to be_nil
  #       expect(project.project_name).to eq('categorize-mp4')
  #     end
  #   end

  #   context 'with file name only' do
  #     it 'parses the file name correctly' do
  #       project = ProjectName.new('a27-ac-categorize-mp4')
  #       expect(project.sequence).to eq('a27')
  #       expect(project.channel_code).to eq('ac')
  #       expect(project.project_name).to eq('categorize-mp4')
  #     end
  #   end
  # end

  # describe '#generate_name' do
  #   it 'generates the correct project name with channel code' do
  #     project = ProjectName.new('a27-ac-categorize-mp4')
  #     expect(project.generate_name).to eq('a27-ac-categorize-mp4')
  #   end

  #   it 'generates the correct project name without channel code' do
  #     project = ProjectName.new('a27-categorize-mp4')
  #     expect(project.generate_name).to eq('a27-categorize-mp4')
  #   end

  #   it 'generates the project name in lowercase dash notation' do
  #     project = ProjectName.new('A27-AC-CATEGORIZE-MP4')
  #     expect(project.generate_name).to eq('a27-ac-categorize-mp4')
  #   end
  # end

  # describe '#to_s' do
  #   it 'returns the generated project name' do
  #     project = ProjectName.new('a27-ac-categorize-mp4')
  #     expect(project.to_s).to eq('a27-ac-categorize-mp4')
  #   end
  # end
end
