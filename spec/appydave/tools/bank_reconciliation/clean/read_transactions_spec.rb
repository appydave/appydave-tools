# frozen_string_literal: true

RSpec.describe Appydave::Tools::BankReconciliation::Clean::ReadTransactions do
  subject { described_class.new(file_path) }

  let(:file_path) { File.join('spec', 'fixtures', 'bank-reconciliation', 'bank-west.csv') }

  describe '#read' do
    context 'when the file is a Wise CSV' do
      let(:file_path) { File.join('spec', 'fixtures', 'bank-reconciliation', 'wise-direction-sample.csv') }

      it 'records Direction=IN rows as credit, not debit' do
        txns = subject.read
        expect(txns[0].credit).to eq('500.00')
        expect(txns[0].debit).to eq('')
      end

      it 'records Direction=OUT rows as debit, not credit' do
        txns = subject.read
        expect(txns[1].debit).to eq('150.00')
        expect(txns[1].credit).to eq('')
      end

      it 'defaults blank Direction to debit for back-compat' do
        txns = subject.read
        expect(txns[2].debit).to eq('75.00')
        expect(txns[2].credit).to eq('')
      end
    end

    context 'when the file is a CBA simple-format CSV' do
      let(:file_path) { File.join('spec', 'fixtures', 'bank-reconciliation', 'commonwealth-simple-sample.csv') }

      it 'detects :commonwealth_simple' do
        subject.read
        expect(subject.platform).to eq(:commonwealth_simple)
      end

      it 'emits one transaction per row and splits debits/credits by sign' do
        txns = subject.read
        expect(txns.size).to eq(4)
        expect(txns[0].credit.to_f).to eq(1000.00)
        expect(txns[0].debit).to eq('')
        expect(txns[1].debit.to_f).to eq(-250.50)
        expect(txns[1].credit).to eq('')
      end

      it 'parses signed amounts with +, -, no-prefix, and zero' do
        txns = subject.read
        expect(txns[2].debit).to eq('')
        expect(txns[2].credit).to eq('')
        expect(txns[3].credit.to_f).to eq(3300.00)
        expect(txns[0].balance.to_f).to eq(1000.00)
      end
    end

    context 'when the file is a PayPal CSV' do
      let(:file_path) { File.join('spec', 'fixtures', 'bank-reconciliation', 'paypal-sample.csv') }

      it 'detects :paypal even with a UTF-8 BOM' do
        subject.read
        expect(subject.platform).to eq(:paypal)
      end

      it 'emits one transaction per data row' do
        txns = subject.read
        expect(txns.size).to eq(3)
      end

      it 'splits debits/credits by sign and tags non-AUD currency in narration' do
        txns = subject.read
        expect(txns[0].credit.to_f).to eq(12.50)
        expect(txns[1].narration).to include('(USD)')
        expect(txns[2].debit.to_f).to eq(-150.00)
        expect(txns[2].narration).to eq('Withdraw to bank')
      end
    end

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
