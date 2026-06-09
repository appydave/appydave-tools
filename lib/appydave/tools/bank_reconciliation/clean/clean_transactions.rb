# frozen_string_literal: true

require 'clipboard'

module Appydave
  module Tools
    module BankReconciliation
      module Clean
        # Clean transactions
        class CleanTransactions
          include KLog::Logging
          include Appydave::Tools::Configuration::Configurable
          include Appydave::Tools::Debuggable

          attr_reader :transaction_folder
          attr_reader :output_folder
          attr_reader :transactions

          # (config_file)
          def initialize(transaction_folder: nil, output_folder: nil, debug: false)
            @debug = debug
            # needs to use config.bank_reconciliation.transaction_folder
            transaction_folder ||= '/Volumes/Expansion/Sync/bank-reconciliation/original-transactions'
            output_folder ||= File.join(transaction_folder, 'clean')

            @transaction_folder = transaction_folder
            @output_folder = output_folder
          end

          def clean_transactions(input_globs, output_file)
            log_info("Starting transaction cleaning with input patterns: #{input_globs}")

            raw_transactions = grab_raw_transactions(input_globs)
            log_info("Total raw transactions collected: #{raw_transactions.size}")

            transactions, duplicates_count = deduplicate_across_files(raw_transactions)
            log_info("Duplicates found and removed: #{duplicates_count}")

            transactions = Mapper.new.map(transactions)
            log_info('Transactions mapped to chart of accounts and bank accounts')

            log_kv 'Deduped consolidated transactions', duplicates_count if duplicates_count.positive?

            save_to_csv(transactions, output_file)

            csv_to_clipboard(output_file)

            @transactions = transactions
          end

          private

          def grab_raw_transactions(input_globs)
            original_dir = Dir.pwd
            transactions = []

            begin
              Dir.chdir(transaction_folder)

              input_globs.each do |glob|
                Dir.glob(glob).each do |file|
                  log_kv 'Reading transactions from', file
                  raw_transactions = ReadTransactions.new(file).read
                  deduped_transactions, duplicates_count = deduplicate_within_file(raw_transactions)

                  if duplicates_count.positive?
                    log_kv 'Duplicates count within file', duplicates_count
                    log_kv 'File', file
                  end

                  transactions += deduped_transactions
                end
              end
            ensure
              Dir.chdir(original_dir)
            end

            transactions
          end

          def deduplicate_within_file(transactions)
            unique_transactions = transactions.uniq do |transaction|
              [
                transaction.bsb_number,
                transaction.account_number,
                transaction.transaction_date,
                transaction.narration,
                transaction.cheque_number,
                transaction.debit,
                transaction.credit,
                transaction.balance,
                transaction.transaction_type
              ]
            end

            duplicates = transactions.size - unique_transactions.size

            [unique_transactions, duplicates]
          end

          def deduplicate_across_files(transactions)
            grouped_transactions = transactions.group_by do |transaction|
              [
                transaction.bsb_number,
                transaction.account_number,
                transaction.transaction_date,
                transaction.narration,
                transaction.cheque_number,
                transaction.debit,
                transaction.credit,
                transaction.balance,
                transaction.transaction_type
              ]
            end

            unique_transactions = []
            duplicates_count = 0

            grouped_transactions.each_value do |dupes|
              unique_transaction = dupes.first
              unique_transaction.source_files = dupes.flat_map(&:source_files).uniq
              duplicates_count += dupes.size - 1
              unique_transactions << unique_transaction
            end

            [unique_transactions, duplicates_count]
          end

          def full_output_file(output_file)
            File.join(output_folder, output_file)
          end

          def save_to_csv(transactions, output_file)
            FileUtils.mkdir_p(output_folder)
            output_file = full_output_file(output_file)
            # puts "Output file: #{output_file}"

            # lets sort the transactions by the by the transaction date which is formated as 2023-07-10
            transactions.sort_by!(&:transaction_date)

            CSV.open(output_file, 'w') do |csv|
              csv << Appydave::Tools::BankReconciliation::Models::Transaction.csv_headers
              transactions.each do |transaction|
                csv << transaction.to_csv_row
              end
            end

            log_kv('Transaction Output File', full_output_file(output_file))
          end

          def csv_to_clipboard(output_file)
            Clipboard.copy(File.read(full_output_file(output_file)))
            log_info('Transactions copied to clipboard')
          end
        end
      end
    end
  end
end
