# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::Models::YoutubeAutomationConfig do
  let(:temp_folder) { Dir.mktmpdir }
  let(:youtube_automation_config) { described_class.new }
  let(:config_file) { File.join(temp_folder, 'youtube-automation.json') }
  let(:config_data) do
    {
      'workflow_groups' => [
        { 'group' => '01', 'description' => 'Metadata and fact sheet creation' },
        { 'group' => '02', 'description' => 'Transcript creation and editing' }
      ],
      'workflow_steps' => [
        { 'group' => '01', 'sequence' => '1', 'name' => 'basic-meta', 'description' => 'Basic metadata generation' },
        { 'group' => '01', 'sequence' => '2', 'name' => 'basic-factsheet', 'description' => 'Basic fact sheet creation' },
        { 'group' => '01', 'sequence' => '3', 'name' => 'video-types', 'description' => 'Video types identification' },
        { 'group' => '01', 'sequence' => '4', 'name' => 'expanded-factsheet', 'description' => 'Expanded fact sheet creation' },
        { 'group' => '01', 'sequence' => '5', 'name' => 'expand-meta', 'description' => 'Metadata expansion' },
        { 'group' => '02', 'sequence' => '1', 'name' => 'create-script', 'description' => 'Script creation' },
        { 'group' => '02', 'sequence' => '2', 'name' => 'clean-transcription', 'description' => 'Clean transcription' },
        { 'group' => '02', 'sequence' => '3', 'name' => 'transcript-factchecked', 'description' => 'Transcript fact-checking' },
        { 'group' => '02', 'sequence' => '4', 'name' => 'transcript-human-edit', 'description' => 'Human editing of transcript' }
      ]
    }
  end

  before do
    File.write(config_file, config_data.to_json)
    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#workflow_groups' do
    it 'retrieves all workflow groups' do
      groups = youtube_automation_config.workflow_groups
      expect(groups.size).to eq(2)
      expect(groups.first.group).to eq('01')
      expect(groups.first.description).to eq('Metadata and fact sheet creation')
    end
  end

  describe '#workflow_steps' do
    it 'retrieves all workflow steps' do
      steps = youtube_automation_config.workflow_steps
      expect(steps.size).to eq(9)
      expect(steps.first.group).to eq('01')
      expect(steps.first.sequence).to eq('1')
      expect(steps.first.name).to eq('basic-meta')
      expect(steps.first.filename('md')).to eq('01-1-basic-meta.md')
    end
  end

  describe '#get_workflow_group' do
    it 'retrieves a workflow group by group ID' do
      group = youtube_automation_config.get_workflow_group('01')
      expect(group.group).to eq('01')
      expect(group.description).to eq('Metadata and fact sheet creation')
    end
  end

  describe '#get_workflow_steps' do
    it 'retrieves workflow steps by group ID' do
      steps = youtube_automation_config.get_workflow_steps('01')
      expect(steps.size).to eq(5)
      expect(steps.first.group).to eq('01')
      expect(steps.first.sequence).to eq('1')
      expect(steps.first.name).to eq('basic-meta')
      expect(steps.first.filename('md')).to eq('01-1-basic-meta.md')
    end
  end

  describe '#get_sequence' do
    it 'retrieves a workflow step by sequence' do
      step = youtube_automation_config.get_sequence('01-1')
      expect(step.group).to eq('01')
      expect(step.sequence).to eq('1')
      expect(step.name).to eq('basic-meta')
      expect(step.filename('md')).to eq('01-1-basic-meta.md')
    end
  end

  describe '#next_sequence' do
    it 'retrieves the next workflow step by sequence' do
      step = youtube_automation_config.next_sequence('01-1')
      expect(step.group).to eq('01')
      expect(step.sequence).to eq('2')
      expect(step.name).to eq('basic-factsheet')
      expect(step.filename('md')).to eq('01-2-basic-factsheet.md')
    end

    it 'returns nil if there is no next step' do
      step = youtube_automation_config.next_sequence('02-4')
      expect(step).to be_nil
    end
  end

  describe '#previous_sequence' do
    it 'retrieves the previous workflow step by sequence' do
      step = youtube_automation_config.previous_sequence('01-2')
      expect(step.group).to eq('01')
      expect(step.sequence).to eq('1')
      expect(step.name).to eq('basic-meta')
      expect(step.filename('md')).to eq('01-1-basic-meta.md')
    end

    it 'returns nil if there is no previous step' do
      step = youtube_automation_config.previous_sequence('01-1')
      expect(step).to be_nil
    end
  end
end
