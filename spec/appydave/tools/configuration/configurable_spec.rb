# frozen_string_literal: true

require 'rspec'
require 'tmpdir'

RSpec.describe Appydave::Tools::Configuration::Configurable do
  Appydave::Tools::Configuration::Config.configure

  let(:temp_folder) { Dir.mktmpdir }
  let(:test_class) do
    Class.new do
      include Appydave::Tools::Configuration::Configurable

      def settings
        config.settings
      end

      def channels
        config.channels
      end

      def bank_reconciliation
        config.bank_reconciliation
      end

      def unknown
        config.unknown
      end
    end
  end
  let(:test_configurable) { test_class.new }
  let(:config_path) { File.join(temp_folder, '.config/appydave') }

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#config' do
    context 'when default configurations are available' do
      it 'returns the settings configuration' do
        expect(test_configurable.settings).to be_an_instance_of(Appydave::Tools::Configuration::Models::SettingsConfig)
      end

      it 'returns the channels configuration' do
        expect(test_configurable.channels).to be_an_instance_of(Appydave::Tools::Configuration::Models::ChannelsConfig)
      end

      it 'returns the bank reconciliation configuration' do
        expect(test_configurable.bank_reconciliation).to be_an_instance_of(Appydave::Tools::Configuration::Models::BankReconciliationConfig)
      end
    end

    context 'when configurations not configured' do
      it 'raises an error' do
        expect { test_configurable.unknown }.to raise_error(Appydave::Tools::Error, 'Configuration not available: unknown')
      end
    end
  end
end
