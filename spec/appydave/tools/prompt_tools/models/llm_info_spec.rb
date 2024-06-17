# frozen_string_literal: true

RSpec.describe Appydave::Tools::PromptTools::Models::LlmInfo do
  subject { described_class.new }

  it { is_expected.to have_attributes(platform: 'openai', model: 'gpt-4o') }
end
