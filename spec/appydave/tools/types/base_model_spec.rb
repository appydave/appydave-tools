# frozen_string_literal: true

RSpec.describe Appydave::Tools::Types::BaseModel do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(ActiveModel::Model) }
  it { is_expected.to be_a(ActiveModel::Attributes) }
end
