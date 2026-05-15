# frozen_string_literal: true

RSpec.describe Appydave::Tools::Configuration::Models::BankReconciliationConfig do
  let(:temp_folder) { Dir.mktmpdir }
  let(:bank_reconciliation_config) { described_class.new }
  let(:config_file) { File.join(temp_folder, 'bank-reconciliation.json') }
  let(:config_data) do
    {
      'bank_accounts' => [
        {
          'account_number' => '123456',
          'bsb' => '123-456',
          'name' => 'Main Account',
          'platform' => 'Big Bank'
        },
        {
          'account_number' => '654321',
          'bsb' => nil,
          'name' => 'Staff Payment',
          'platform' => 'Wise'
        }
      ],
      'chart_of_accounts' => [
        {
          'code' => '1000',
          'narration' => 'Cash at Bank'
        },
        {
          'code' => '2000',
          'narration' => 'Accounts Receivable'
        }
      ]
    }
  end

  before do
    File.write(config_file, config_data.to_json)

    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '#bank_accounts' do
    it 'retrieves all bank accounts' do
      accounts = bank_reconciliation_config.bank_accounts

      expect(accounts.size).to eq(2)
    end
  end

  describe '#chart_of_accounts' do
    it 'retrieves all chart of account entries' do
      entries = bank_reconciliation_config.chart_of_accounts

      expect(entries.size).to eq(2)
      expect(entries.first.code).to eq('1000')
      expect(entries.first.narration).to eq('Cash at Bank')
      expect(entries.last.code).to eq('2000')
      expect(entries.last.narration).to eq('Accounts Receivable')
    end
  end

  describe '#get_bank_account' do
    it 'retrieves a bank account by account number and BSB' do
      account = bank_reconciliation_config.get_bank_account('123456', '123-456')

      expect(account).not_to be_nil
      expect(account.account_number).to eq('123456')
      expect(account.bsb).to eq('123-456')
      expect(account.name).to eq('Main Account')
      expect(account.platform).to eq('Big Bank')
    end

    it 'retrieves a bank account by account number without BSB' do
      account = bank_reconciliation_config.get_bank_account('654321')

      expect(account).not_to be_nil
      expect(account.account_number).to eq('654321')
      expect(account.bsb).to be_nil
      expect(account.name).to eq('Staff Payment')
      expect(account.platform).to eq('Wise')
    end

    it 'returns nil for non-existent account' do
      account = bank_reconciliation_config.get_bank_account('000000', '000-000')

      expect(account).to be_nil
    end
  end

  describe '#get_chart_of_account' do
    it 'retrieves a chart of account entry by code' do
      entry = bank_reconciliation_config.get_chart_of_account('1000')

      expect(entry).not_to be_nil
      expect(entry.code).to eq('1000')
      expect(entry.narration).to eq('Cash at Bank')
    end

    it 'returns nil for non-existent code' do
      entry = bank_reconciliation_config.get_chart_of_account('9999')

      expect(entry).to be_nil
    end
  end
end
