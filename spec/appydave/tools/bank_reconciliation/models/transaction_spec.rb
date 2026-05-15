# frozen_string_literal: true

RSpec.describe Appydave::Tools::BankReconciliation::Models::Transaction do
  subject { instance }

  let(:instance) do
    described_class.new(
      bsb_number: bsb_number,
      account_number: account_number,
      transaction_date: transaction_date,
      narration: narration,
      cheque_number: cheque_number,
      debit: debit,
      credit: credit,
      balance: balance,
      transaction_type: transaction_type
    )
  end

  # Raw transaction attributes
  let(:bsb_number) { '303-111' }
  let(:account_number) { '1234567' }
  let(:transaction_date) { '12/12/2023' }
  let(:narration) { 'CapitalTransfer' }
  let(:cheque_number) { '' }
  let(:debit) { '-50.00' }
  let(:credit) { '' }
  let(:balance) { '0.50' }
  let(:transaction_type) { 'TFD' }

  # Reconciled transaction attributes
  let(:platform) { 'BankWest' }
  let(:coa_code) { '1000' }
  let(:coa_match_type) { 'fuzzy' }
  let(:account_name) { 'Main Account' }

  context 'when initialized from raw transation' do
    it do
      expect(subject).to have_attributes(
        bsb_number: '303-111',
        account_number: '1234567',
        transaction_date: Date.strptime('12/12/2023', '%d/%m/%Y'),
        narration: 'CapitalTransfer',
        cheque_number: '',
        debit: '-50.00',
        credit: '',
        balance: '0.50',
        transaction_type: 'TFD',
        platform: nil,
        coa_code: nil,
        coa_match_type: nil,
        account_name: nil,
        source_files: []
      )
    end

    context 'when naration has extra spaces' do
      subject { instance.narration }

      let(:narration) { '  Capital         Transfer   ' }

      it { is_expected.to eq('Capital Transfer') }
    end

    context 'when updated with reconciled transaction attributes' do
      before do
        instance.platform = platform
        instance.coa_code = coa_code
        instance.coa_match_type = coa_match_type
        instance.account_name = account_name
      end

      it 'updates the transaction attributes' do
        expect(subject.platform).to eq(platform)
        expect(subject.coa_code).to eq(coa_code)
        expect(subject.coa_match_type).to eq(coa_match_type)
        expect(subject.account_name).to eq(account_name)
      end
    end

    context 'when source file is added' do
      before do
        instance.add_source_file('file1.csv')
        instance.add_source_file('file2.csv')
        instance.add_source_file('file1.csv')
      end

      it 'adds the source file' do
        expect(subject.source_files.size).to eq(2)
        expect(subject.source_files).to eq(['file1.csv', 'file2.csv'])
      end
    end
  end

  context 'when initialized from reconciled transation' do
    let(:instance) do
      described_class.new(
        bsb_number: bsb_number,
        account_number: account_number,
        transaction_date: transaction_date,
        narration: narration,
        cheque_number: cheque_number,
        debit: debit,
        credit: credit,
        balance: balance,
        transaction_type: transaction_type,
        platform: platform,
        coa_code: coa_code,
        coa_match_type: coa_match_type,
        account_name: account_name
      )
    end

    it do
      expect(subject).to have_attributes(
        bsb_number: '303-111',
        account_number: '1234567',
        transaction_date: Date.strptime('12/12/2023', '%d/%m/%Y'),
        narration: 'CapitalTransfer',
        cheque_number: '',
        debit: '-50.00',
        credit: '',
        balance: '0.50',
        transaction_type: 'TFD',
        platform: 'BankWest',
        coa_code: '1000',
        coa_match_type: 'fuzzy',
        account_name: 'Main Account',
        source_files: []
      )
    end
  end
end
