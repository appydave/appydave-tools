# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::S3ScanCommand do
  describe '#scan_single' do
    it 'responds to scan_single' do
      expect(described_class.new).to respond_to(:scan_single)
    end
  end

  describe '#scan_all' do
    it 'responds to scan_all' do
      expect(described_class.new).to respond_to(:scan_all)
    end
  end
end
