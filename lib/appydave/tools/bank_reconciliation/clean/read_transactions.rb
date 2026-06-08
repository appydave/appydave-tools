# frozen_string_literal: true

require 'bigdecimal'

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
          PAYPAL_HEADER_PREFIX = '"Date","Time","Time zone","Name","Type","Status","Currency",' \
                                 '"Amount","Fees","Total","Exchange Rate","Receipt ID","Balance",' \
                                 '"Transaction ID","Item Title"'
          # Exact match — short header risks start_with? collision with future formats
          COMMONWEALTH_SIMPLE_HEADER = 'Date,Amount,Description,Balance'
          attr_reader :platform
          attr_reader :transactions

          def initialize(file)
            @file = file
          end

          def read
            csv_lines = File.read(@file).lines
            csv_lines[0] = csv_lines[0].sub("\xEF\xBB\xBF", '') if csv_lines[0]&.start_with?("\xEF\xBB\xBF")

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
            when :paypal
              read_paypal(csv_lines)
            when :commonwealth_simple
              read_commonwealth_simple(csv_lines)
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

            CSV.parse(csv_lines.join, headers: true).each do |row|
              amount   = row['Source amount (after fees)']
              incoming = row['Direction'].to_s.strip.upcase == 'IN'

              puts "Wise: unexpected Direction '#{row['Direction']}' on row #{row['ID']} — defaulting to debit" \
                unless %w[IN OUT].include?(row['Direction'].to_s.strip.upcase)

              transaction = Models::Transaction.new(
                bsb_number: '',
                account_number: 'WISE',
                transaction_date: row['Created on'],
                narration: row['Reference'] || '',
                cheque_number: "#{row['Source currency']}|#{row['Target currency']}|#{row['Exchange rate']}|#{row['Target name']}",
                debit: incoming ? '' : amount,
                credit: incoming ? amount : '',
                balance: '',
                transaction_type: ''
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          # PayPal CSV header:
          # "Date","Time","Time zone","Name","Type","Status","Currency","Amount","Fees","Total",
          # "Exchange Rate","Receipt ID","Balance","Transaction ID","Item Title"
          def read_paypal(csv_lines)
            @transactions = []

            CSV.parse(csv_lines.join, headers: true).each do |row|
              next if row['Date'].to_s.strip.empty?

              name      = row['Name'].to_s.strip
              item      = row['Item Title'].to_s.strip
              narration = name.empty? ? item : name
              currency  = row['Currency'].to_s.strip
              narration = "#{narration} (#{currency})" if !currency.empty? && currency != 'AUD'

              amount = row['Amount'].to_s.strip
              debit  = amount.to_f.negative? ? amount : ''
              credit = amount.to_f.positive? ? amount : ''

              transaction = Models::Transaction.new(
                bsb_number: '',
                account_number: 'PAYPAL',
                transaction_date: row['Date'],
                narration: narration,
                cheque_number: '',
                debit: debit,
                credit: credit,
                balance: row['Balance'],
                transaction_type: row['Type'].to_s
              )
              transaction.add_source_file(@file)
              @transactions << transaction
            end

            @transactions
          end

          # CBA 4-column export (Date,Amount,Description,Balance). The CSV carries
          # no account identity, so we tag rows with the generic identifier 'CBA-SIMPLE'
          # and let the downstream mapper resolve it via the local
          # ~/.config/appydave/bank-reconciliation.json config (same pattern as WISE
          # and PAYPAL). Real BSB / account number stay out of source.
          def read_commonwealth_simple(csv_lines)
            @transactions = []

            CSV.parse(csv_lines.join, headers: true).each do |row|
              next if row['Date'].to_s.strip.empty?

              amount = parse_signed_amount(row['Amount'])
              debit  = amount.negative? ? amount.to_s('F') : ''
              credit = amount.positive? ? amount.to_s('F') : ''

              transaction = Models::Transaction.new(
                bsb_number: '',
                account_number: 'CBA-SIMPLE',
                transaction_date: row['Date'],
                narration: row['Description'].to_s,
                cheque_number: nil,
                debit: debit,
                credit: credit,
                balance: parse_signed_amount(row['Balance']).to_s('F'),
                transaction_type: nil
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
            return :paypal if csv_lines.first.start_with?(PAYPAL_HEADER_PREFIX)
            return :commonwealth_simple if csv_lines.first.strip == COMMONWEALTH_SIMPLE_HEADER

            puts "Unknown platform detected. CSV columns are: #{csv_lines.first.strip}"
            raise Appydave::Tools::Error, 'Unknown platform'
          end

          def parse_signed_amount(str)
            return BigDecimal('0') if str.nil? || str.to_s.strip.empty?

            clean = str.to_s.gsub(/[$,\s"]/, '')
            return BigDecimal('0') if clean.empty?

            case clean[0]
            when '+' then BigDecimal(clean[1..])
            when '-' then -BigDecimal(clean[1..])
            else BigDecimal(clean)
            end
          end
        end
      end
    end
  end
end
