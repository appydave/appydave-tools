# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Bank reconciliation configuration
        class BankReconciliationConfig < ConfigBase
          # Retrieve all bank accounts
          def bank_accounts
            data['bank_accounts'].map do |account|
              BankAccount.new(account)
            end
          end

          def chart_of_accounts
            data['chart_of_accounts'].map do |entry|
              ChartOfAccount.new(entry)
            end
          end

          def get_bank_account(account_number, bsb = nil)
            account_data = data['bank_accounts'].find do |account|
              account['account_number'] == account_number && (account['bsb'].nil? || account['bsb'] == bsb)
            end

            BankAccount.new(account_data) if account_data
          end

          # Retrieve a chart of account entry by code
          def get_chart_of_account(code)
            entry_data = data['chart_of_accounts'].find { |entry| entry['code'] == code }
            ChartOfAccount.new(entry_data) if entry_data
          end

          def print
            log.subheading 'Bank Reconciliation - Accounts'

            tp bank_accounts, :account_number, :bsb, :name, :bank

            log.subheading 'Bank Reconciliation - Chart of Accounts'

            tp chart_of_accounts, :code, :narration
          end

          private

          def default_data
            {
              'bank_accounts' => [],
              'chart_of_accounts' => []
            }
          end

          # Inner class to represent a bank account
          class BankAccount
            attr_accessor :account_number, :bsb, :name, :bank

            def initialize(data)
              @account_number = data['account_number']
              @bsb = data['bsb']
              @name = data['name']
              @bank = data['bank']
            end

            def to_h
              {
                'account_number' => @account_number,
                'bsb' => @bsb,
                'name' => @name,
                'bank' => @bank
              }
            end
          end

          # Inner class to represent a chart of account entry
          class ChartOfAccount
            attr_accessor :code, :narration

            def initialize(data)
              @code = data['code']
              @narration = data['narration']
            end

            def to_h
              {
                'code' => @code,
                'narration' => @narration
              }
            end
          end
        end
      end
    end
  end
end
