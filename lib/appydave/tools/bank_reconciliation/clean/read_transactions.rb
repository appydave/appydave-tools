# frozen_string_literal: true

module Appydave
  module Tools
    module BankReconciliation
      module Clean
        # Read transactions from a CSV file
        class ReadTransactions
          WISE_HEADER_PREFIX = 'ID,Status,Direction,"Created on","Finished on","Source fee amount",' \
                               '"Source fee currency","Target fee amount","Target fee currency","Source name",' \
                               '"Source amount (after fees)","Source currency","Target name",' \
                               '"Target amount (after fees)","Target currency","Exchange rate",Reference,Batch'
          attr_reader :platform
          attr_reader :transactions

          def initialize(file)
            @file = file
          end

          def read
            csv_lines = File.read(@file).lines

            @platform = detect_platform(csv_lines)

            case platform
            when :bankwest
              read_bankwest(csv_lines)
            when :bankwest2
              read_bankwest2(csv_lines)
            when :commonwealth1
              read_commonwealth1(csv_lines)
            when :wise
              read_wise(csv_lines)
            else
              raise Appydave::Tools::Error, 'Unknown platform X'
            end
          end

          private

          def read_bankwest(csv_lines)
            @transactions = []

            # Skip the header line and parse each subsequent line
            CSV.parse(csv_lines.join, headers: true).each do |row|
              transaction = Models::Transaction.new(
                bsb_number: row['BSB Number'] || '',
                account_number: row['Account Number'] || '',
                transaction_date: row['Transaction Date'],
                narration: row['Narration'],
                cheque_number: row['Cheque Number'],
                debit: row['Debit'],
                credit: row['Credit'],
                balance: row['Balance'],
                transaction_type: row['Transaction Type']
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          def read_bankwest2(csv_lines)
            @transactions = []

            # Skip the header line and parse each subsequent line
            CSV.parse(csv_lines.join, headers: true).each do |row|
              values = row['BSB / Account Number'].split(' - ')

              transaction = Models::Transaction.new(
                bsb_number: values.length > 1 ? values.first : '',
                account_number: values.length > 1 ? values.last : row['BSB / Account Number'],
                transaction_date: row['Transaction Date'],
                narration: row['Narration'],
                cheque_number: row['Cheque Number'],
                debit: row['Debit'],
                credit: row['Credit'],
                balance: row['Balance'],
                transaction_type: row['Transaction Type']
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          def read_commonwealth1(csv_lines)
            @transactions = []

            # Skip the header line and parse each subsequent line
            CSV.parse(csv_lines.join, headers: true).each do |row|
              transaction = Models::Transaction.new(
                bsb_number: row['bsb_number'],
                account_number: row['account_number'],
                transaction_date: row['transaction_date'],
                narration: row['description'],
                cheque_number: '',
                debit: row['amount'].to_f.negative? ? row['amount'] : '',
                credit: row['amount'].to_f.positive? ? row['amount'] : '',
                balance: row['balance'],
                transaction_type: ''
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          # Wise CSV header:
          # ID,Status,Direction,"Created on","Finished on","Source fee amount","Source fee currency",
          # "Target fee amount","Target fee currency","Source name","Source amount (after fees)",
          # "Source currency","Target name","Target amount (after fees)","Target currency",
          # "Exchange rate",Reference,Batch
          def read_wise(csv_lines)
            @transactions = []

            # Skip the header line and parse each subsequent line
            CSV.parse(csv_lines.join, headers: true).each do |row|
              transaction = Models::Transaction.new(
                bsb_number: '',
                account_number: 'WISE',
                transaction_date: row['Created on'],
                narration: row['Reference'] || '',
                cheque_number: "#{row['Source currency']}|#{row['Target currency']}|#{row['Exchange rate']}|#{row['Target name']}", # DON"T have a better field yet
                debit: row['Source amount (after fees)'],
                credit: '',
                balance: '',
                transaction_type: ''
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          # For bankwest the first row is the CSV will look like:
          # BSB Number,Account Number,Transaction Date,Narration,Cheque Number,Debit,Credit,Balance,Transaction Type
          def detect_platform(csv_lines)
            return :bankwest if csv_lines.first.start_with?('BSB Number,Account Number,Transaction Date,Narration,Cheque Number,Debit,Credit,Balance,Transaction Type')
            return :bankwest2 if csv_lines.first.start_with?('Account Name,BSB / Account Number,Transaction Date,Narration,Cheque Number,Debit,Credit,Balance,Transaction Type')
            return :commonwealth1 if csv_lines.first.start_with?('bsb_number,account_number,transaction_date,amount,description,balance') # Standard Account
            return :commonwealth2 if csv_lines.first.start_with?('transaction_date,narration,debit_credit_amount,debit_credit_currency,balance_amount,balance_currency') # Travel Money
            return :wise if csv_lines.first.start_with?(WISE_HEADER_PREFIX)

            puts "Unknown platform detected. CSV columns are: #{csv_lines.first.strip}"
            raise Appydave::Tools::Error, 'Unknown platform'
          end
        end
      end
    end
  end
end
