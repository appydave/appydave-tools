# frozen_string_literal: true

RSpec.describe Appydave::Tools::BankReconciliation::Clean::Mapper do
  let(:narration) { 'Capital Transfer' }
  let(:configured_account_number) { '1234567' }
  let(:transaction) do
    Appydave::Tools::BankReconciliation::Models::Transaction.new(
      bsb_number: '303-111',
      account_number: '1234567',
      transaction_date: '12/12/2023',
      narration: narration,
      cheque_number: '',
      debit: '-50.00',
      credit: '',
      balance: '0.50',
      transaction_type: 'TFD'
    )
  end
  let(:temp_folder) { Dir.mktmpdir }
  let(:config_file) { File.join(temp_folder, 'bank-reconciliation.json') }
  let(:config_data) do
    {
      chart_of_accounts: [
        { 'code' => 'internal_transfer', 'narration' => 'Capital Transfer' },
        { 'code' => 'commbank', 'narration' => 'Capital Transfer to Commonwealth Bank' },
        { 'code' => 'wise', 'narration' => 'Capital Transfer Wise' },
        { 'code' => 'internal_transfer', 'narration' => 'PayWise' },
        { code: 'PSYCHOLOGY', narration: 'MARIANNE GABRIEL' },
        { code: 'FRIEND', narration: 'Nick Jones' }
      ],
      bank_accounts: [
        { 'account_number' => configured_account_number, 'bsb' => '303-111', 'name' => 'Test Account', 'platform' => 'Test Bank' }
      ]
    }
  end

  let(:instance) { described_class.new }

  before do
    File.write(config_file, config_data.to_json)

    Appydave::Tools::Configuration::Config.configure do |config|
      config.config_path = temp_folder
      config.register(:bank_reconciliation, Appydave::Tools::Configuration::Models::BankReconciliationConfig)
    end
  end

  after do
    FileUtils.remove_entry(temp_folder)
    Appydave::Tools::Configuration::Config.reset
  end

  describe '#map' do
    subject { instance.map([transaction]).first }

    context 'when bank account matches' do
      it { is_expected.to have_attributes(account_name: 'Test Account', platform: 'Test Bank') }

      context 'when bank account does not match' do
        let(:configured_account_number) { '7654321' }

        it { is_expected.to have_attributes(account_name: nil, platform: nil) }
      end
    end

    context 'when narration matches exactly' do
      let(:narration) { 'Capital Transfer' }

      it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: 'equality') }

      context 'when narration is strpped of spaces' do
        let(:narration) { 'CapitalTransfer' }

        it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: 'equality') }
      end
    end

    context 'when testing trigram confidence' do
      context 'when 90%' do
        let(:narration) { 'Capital Transfer1' }

        it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: '90%') }
      end

      context 'when 80%' do
        let(:narration) { 'Capital Transfer A' }

        it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: '80%') }
      end

      context 'when 70%' do
        let(:narration) { 'Capital Transfer Bob' }

        it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: '70%') }
      end

      context 'when alternative coa example 1' do
        let(:narration) { 'Capital Transfer Wis' }

        it { is_expected.to have_attributes(coa_code: 'wise', coa_match_type: '90%') }
      end

      context 'when alternative coa example 2' do
        let(:narration) { 'Capital Transfer Commonweal' }

        it { is_expected.to have_attributes(coa_code: 'commbank', coa_match_type: '60%') }
      end

      context 'when Case Insensitive Match' do
        let(:narration) { 'MARIANNEGABRIEL' }

        it { is_expected.to have_attributes(coa_code: 'PSYCHOLOGY', coa_match_type: 'equality') }
      end

      context 'when starts with' do
        let(:narration) { 'Pay Wise Account' }

        it { is_expected.to have_attributes(coa_code: 'internal_transfer', coa_match_type: 'starts_with') }
      end

      context 'when includes' do
        let(:narration) { 'To Nick Jones 06:33AM 16Jul NicholasJones' }

        it { is_expected.to have_attributes(coa_code: 'FRIEND', coa_match_type: 'includes') }
      end
    end
  end
end
