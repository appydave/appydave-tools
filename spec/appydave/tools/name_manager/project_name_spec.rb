# frozen_string_literal: true

RSpec.describe Appydave::Tools::NameManager::ProjectName do
  before { Appydave::Tools::Configuration::Config.configure }

  describe '#initialize' do
    subject { instance }

    let(:instance) { described_class.new(file_name) }

    context 'when channel code is present' do
      let(:file_name) { 'a27-ac-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'ac', project_name: 'my-video-project') }
    end

    context 'when channel code is not present' do
      let(:file_name) { 'a27-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: nil, project_name: 'my-video-project') }
    end

    context 'when absolute file path' do
      let(:file_name) { '/path/to/a27-ac-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'ac', project_name: 'my-video-project') }
    end

    context 'when relative file path' do
      let(:file_name) { 'path/to/a27-ac-my-video-project' }

      it { is_expected.to have_attributes(sequence: 'a27', channel_code: 'ac', project_name: 'my-video-project') }
    end
  end
end
