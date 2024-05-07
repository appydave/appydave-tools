# frozen_string_literal: true

RSpec.describe Appydave::Tools do
  it 'has a version number' do
    expect(Appydave::Tools::VERSION).not_to be_nil
  end

  it 'has a standard error' do
    expect { raise Appydave::Tools::Error, 'some message' }
      .to raise_error('some message')
  end
end
