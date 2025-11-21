# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Appydave::Tools::Dam::Errors' do
  describe Appydave::Tools::Dam::DamError do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe Appydave::Tools::Dam::BrandNotFoundError do
    it 'inherits from DamError' do
      expect(described_class).to be < Appydave::Tools::Dam::DamError
    end

    it 'creates error with brand name only' do
      error = described_class.new('invalid-brand')
      expect(error.message).to include('Brand directory not found: invalid-brand')
    end

    it 'creates error with brand name and available brands' do
      available = "  appydave - AppyDave\n  voz - vOz"
      error = described_class.new('invalid-brand', available)

      expect(error.message).to include('Brand directory not found: invalid-brand')
      expect(error.message).to include('Available brands:')
      expect(error.message).to include('appydave - AppyDave')
    end

    it 'handles nil available brands' do
      error = described_class.new('invalid-brand', nil)
      expect(error.message).to eq('Brand directory not found: invalid-brand')
    end

    it 'handles empty available brands' do
      error = described_class.new('invalid-brand', '')
      expect(error.message).to eq('Brand directory not found: invalid-brand')
    end
  end

  describe Appydave::Tools::Dam::ProjectNotFoundError do
    it 'inherits from DamError' do
      expect(described_class).to be < Appydave::Tools::Dam::DamError
    end
  end

  describe Appydave::Tools::Dam::ConfigurationError do
    it 'inherits from DamError' do
      expect(described_class).to be < Appydave::Tools::Dam::DamError
    end
  end

  describe Appydave::Tools::Dam::S3OperationError do
    it 'inherits from DamError' do
      expect(described_class).to be < Appydave::Tools::Dam::DamError
    end
  end

  describe Appydave::Tools::Dam::GitOperationError do
    it 'inherits from DamError' do
      expect(described_class).to be < Appydave::Tools::Dam::DamError
    end
  end
end
