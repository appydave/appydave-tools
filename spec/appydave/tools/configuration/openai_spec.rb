# frozen_string_literal: true

RSpec.describe 'OpenAI configuration setup' do
  it 'has openai access token' do
    expect(OpenAI.configuration.access_token).not_to be_nil
  end

  it 'has openai organization id' do
    expect(OpenAI.configuration.organization_id).not_to be_nil
  end
end
