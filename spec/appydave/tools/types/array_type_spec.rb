# frozen_string_literal: true

RSpec.describe Appydave::Tools::Types::ArrayType do
  subject { instance }

  let(:instance) { described_class.new }

  describe '#cast' do
    context 'when value is a string' do
      subject { instance.cast(value) }

      let(:value) { 'a,b,c' }

      it { is_expected.to eq(%w[a b c]) }
    end

    context 'when value is an array' do
      subject { instance.cast(value) }

      let(:value) { %w[a b c] }

      it { is_expected.to eq(%w[a b c]) }
    end

    context 'when value is not a string or array' do
      it 'raises an ArgumentError' do
        expect { instance.cast(123) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#serialize' do
    context 'when value is an array' do
      subject { instance.serialize(value) }

      let(:value) { %w[a b c] }

      it { is_expected.to eq('a,b,c') }
    end
  end
end
