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

    it 'creates error with fuzzy match suggestions' do
      suggestions = %w[appydave voz]
      error = described_class.new('appydav', nil, suggestions)

      expect(error.message).to include('Brand directory not found: appydav')
      expect(error.message).to include('Did you mean?')
      expect(error.message).to include('  - appydave')
      expect(error.message).to include('  - voz')
    end

    it 'creates error with suggestions and available brands' do
      available = "  appydave - AppyDave\n  voz - vOz"
      suggestions = %w[appydave]
      error = described_class.new('appydav', available, suggestions)

      expect(error.message).to include('Brand directory not found: appydav')
      expect(error.message).to include('Did you mean?')
      expect(error.message).to include('  - appydave')
      expect(error.message).to include('Available brands:')
      expect(error.message).to include('appydave - AppyDave')
    end

    it 'handles nil suggestions' do
      available = "  appydave - AppyDave"
      error = described_class.new('invalid-brand', available, nil)

      expect(error.message).to include('Brand directory not found: invalid-brand')
      expect(error.message).not_to include('Did you mean?')
      expect(error.message).to include('Available brands:')
    end

    it 'handles empty suggestions' do
      available = "  appydave - AppyDave"
      error = described_class.new('invalid-brand', available, [])

      expect(error.message).to include('Brand directory not found: invalid-brand')
      expect(error.message).not_to include('Did you mean?')
      expect(error.message).to include('Available brands:')
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
