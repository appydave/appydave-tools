# frozen_string_literal: true

RSpec.describe Appydave::Tools::IndifferentAccessHash do
  subject { instance }

  let(:instance) { described_class.new(data) }
  let(:data) { { a: 1, 'b' => 2, c: 3 } }

  it 'allows access to values with symbol keys' do
    expect(instance[:a]).to eq(1)
    expect(instance[:b]).to eq(2)
  end

  it 'allows access to values with string keys' do
    expect(instance['a']).to eq(1)
    expect(instance['b']).to eq(2)
  end

  it 'allows setting values with symbol keys' do
    instance[:d] = 4
    expect(instance[:d]).to eq(4)
    expect(instance['d']).to eq(4)
  end

  it 'allows setting values with string keys' do
    instance['e'] = 5
    expect(instance[:e]).to eq(5)
    expect(instance['e']).to eq(5)
  end

  it 'allows fetching values with symbol keys' do
    expect(instance.fetch(:a)).to eq(1)
    expect(instance.fetch(:b)).to eq(2)
  end

  it 'allows fetching values with string keys' do
    expect(instance.fetch('a')).to eq(1)
    expect(instance.fetch('b')).to eq(2)
  end

  it 'returns default value if key is not found with fetch' do
    expect(instance.fetch(:missing, 'default')).to eq('default')
  end

  it 'allows deleting values with symbol keys' do
    instance.delete(:a)
    expect(instance[:a]).to be_nil
    expect(instance['a']).to be_nil
  end

  it 'allows deleting values with string keys' do
    instance.delete('b')
    expect(instance[:b]).to be_nil
    expect(instance['b']).to be_nil
  end

  it 'correctly initializes with an initial hash' do
    expect(instance[:a]).to eq(1)
    expect(instance['b']).to eq(2)
    expect(instance[:c]).to eq(3)
  end
end
