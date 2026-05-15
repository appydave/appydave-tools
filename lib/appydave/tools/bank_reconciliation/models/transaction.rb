# frozen_string_literal: true

module Appydave
  module Tools
    module BankReconciliation
      module Models
        # Unified transaction model for raw and reconciled data
        class Transaction
          attr_accessor :bsb_number,
                        :account_number,
                        :transaction_date,
                        :narration,
                        :cheque_number,
                        :debit,
                        :credit,
                        :balance,
                        :transaction_type,
                        :platform,
                        :coa_code,
                        :coa_match_type,
                        :account_name,
                        :source_files,
                        :fin_year

          def initialize(bsb_number: nil,
                         account_number: nil,
                         transaction_date: nil,
                         narration: nil,
                         cheque_number: nil,
                         debit: nil,
                         credit: nil,
                         balance: nil,
                         transaction_type: nil,
                         platform: nil,
                         coa_code: nil,
                         coa_match_type: nil,
                         account_name: nil)
            account_number = account_number&.strip
            @bsb_number = bsb_number&.strip
            @account_number = account_number
            @transaction_date = parse_date(transaction_date)
            @narration = narration&.gsub(/\s{2,}/, ' ')&.strip
            @cheque_number = cheque_number&.strip
            @debit = debit # clean_amount(debit, account_number, coa_code)
            @credit = credit # clean_amount(credit, account_number, coa_code)
            @balance = balance&.strip
            @transaction_type = transaction_type&.strip
            @platform = platform
            @coa_code = coa_code
            @coa_match_type = coa_match_type
            @account_name = account_name
            @source_files = []
            @fin_year = determine_fin_year(@transaction_date)
          end

          def add_source_file(source_file)
            @source_files << source_file.strip unless @source_files.include?(source_file.strip)
          end

          def self.csv_headers
            %i[
              platform
              account_name
              bsb_number
              account_number
              transaction_date
              narration
              debit
              credit
              balance
              transaction_type
              coa_code
              coa_match_type
              source_files
              fin_year
            ]
          end

          def to_csv_row
            [
              @platform,
              @account_name,
              @bsb_number,
              @account_number,
              @transaction_date,
              @narration,
              @debit ? format('%.2f', @debit) : '',
              @credit ? format('%.2f', @credit) : '',
              @balance,
              @transaction_type,
              @coa_code,
              @coa_match_type,
              @source_files.join('; '),
              @fin_year
            ]
          end

          def clean_amount(amount)
            return nil if amount.nil? || amount.strip.empty?

            cleaned_amount = amount.to_f.round(2)

            if swap_plus_minus_for_transactions
              if cleaned_amount.negative?
                cleaned_amount = cleaned_amount.abs
                # else
                #   cleaned_amount *= -1
              end
              puts "Fixed negative amount for account: #{account_number} and COA: #{coa_code}, original amount: #{amount}, fixed amount: #{cleaned_amount}" if coa_code == 'DANCE'
            end
            cleaned_amount
          end

          # Returns true if this transaction's amount should have its sign flipped
          # based on the per-account, per-FY, per-COA rules stored in config.
          #
          # Rules live in ~/.config/appydave/bank-reconciliation.json under
          # `sign_flip_rules` — see BankReconciliationConfig::SignFlipRule.
          # Personal account numbers MUST NOT be hardcoded here; the config file
          # is local-only and never committed to the repo.
          def swap_plus_minus_for_transactions
            sign_flip_rules.any? do |rule|
              (rule.fin_year.nil? || rule.fin_year == fin_year) &&
                rule.account_number == account_number &&
                rule.coa_codes.include?(coa_code)
            end
          end

          private

          def sign_flip_rules
            Appydave::Tools::Configuration::Config.bank_reconciliation.sign_flip_rules
          rescue StandardError
            []
          end


          def parse_date(date_string)
            formats = ['%d/%m/%Y', '%Y-%m-%d %H:%M:%S']
            formats.each do |format|
              return Date.strptime(date_string, format)
            rescue Date::Error
              next
            end
            raise Date::Error, "Invalid date format: #{date_string}"
          end

          def determine_fin_year(date)
            if date.month >= 7
              "#{date.year}-#{date.year + 1}"
            else
              "#{date.year - 1}-#{date.year}"
            end
          end
        end
      end
    end
  end
end
