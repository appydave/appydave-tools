# frozen_string_literal: true

RSpec.describe Appydave::Tools::BankReconciliation::Clean::ReadTransactions do
  subject { described_class.new(file_path) }

  let(:file_path) { File.join('spec', 'fixtures', 'bank-reconciliation', 'bank-west.csv') }

  describe '#read' do
    context 'when the file is from BankWest' do
      before { subject.read }

      it 'detects the platform as bankwest' do
        expect(subject.platform).to eq(:bankwest)
      end

      it 'reads and parses the transactions correctly' do
        transactions = subject.transactions

        expect(transactions.size).to eq(3)

        first_transaction = transactions[0]

        expect(first_transaction).to have_attributes(
          bsb_number: '303-111',
          account_number: '1234567',
          transaction_date: Date.strptime('12/12/2023', '%d/%m/%Y'),
          narration: 'Capital Transfer',
          cheque_number: nil,
          debit: '-50.00',
          credit: nil,
          balance: '0.50',
          transaction_type: 'TFD',
          source_files: [file_path]
        )
      end
    end
  end
end
