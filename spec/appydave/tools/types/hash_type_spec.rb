# frozen_string_literal: true

RSpec.describe Appydave::Tools::Types::HashType do
  subject { instance }

  let(:instance) { described_class.new }

  describe '#cast' do
    context 'when value is a string' do
      subject { instance.cast(value) }

      let(:value) { '{"a":1,"b":2,"c":3}' }

      it { is_expected.to eq('a' => 1, 'b' => 2, 'c' => 3) }
    end

    context 'when value is a hash' do
      subject { instance.cast(value) }

      let(:value) { { a: 1, b: 2, c: 3 } }

      it { is_expected.to eq(a: 1, b: 2, c: 3) }
    end

    context 'when value is not a string or hash' do
      it 'raises an ArgumentError' do
        expect { instance.cast(123) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#serialize' do
    context 'when value is a hash' do
      subject { instance.serialize(value) }

      let(:value) { { a: 1, b: 2, c: 3 } }

      it { is_expected.to eq('{"a":1,"b":2,"c":3}') }
    end
  end
end
