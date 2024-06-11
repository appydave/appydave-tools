# frozen_string_literal: true

RSpec.describe 'OpenAI configuration setup' do
  let(:mock_configuration) { double('OpenAI::Configuration', access_token: 'mock_access_token', organization_id: 'mock_organization_id') }

  before do
    allow(OpenAI).to receive(:configuration).and_return(mock_configuration)
  end

  it 'has openai access token' do
    expect(OpenAI.configuration.access_token).not_to be_nil
  end

  it 'has openai organization id' do
    expect(OpenAI.configuration.organization_id).not_to be_nil
  end
end
