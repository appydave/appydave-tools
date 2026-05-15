# Bank reconciliation

[ChatGPT conversation](https://chatgpt.com/c/5d382562-95e5-4243-9b74-c3807d363486)


## Code structure

```bash
├─ lib
│ ├─ appydave
│ │ └─ tools
│ │   ├─ bank_reconciliation
│ │   │ ├─ clean
│ │   │ │ ├─ read_transactions.rb
│ │   │ │ ├─ transaction_cleaner.rb
│ │   │ ├─ models
│ │   │ │ ├─ raw_transaction.rb
│ │   │ │ └─ reconciled_transaction.rb
│ │   └─ configuration
│ │     └─ models
│ │       └─ bank_reconciliation_config.rb
└─ spec
  ├─ appydave
  │ ├─ tools
  │ │ ├─ bank_reconciliation
  │ │ │ ├─ clean
  │ │ │ │ ├─ read_transactions_spec.rb
  │ │ │ ├─ models
  │ │ │ │ └─ raw_transaction_spec.rb
  │ │ └─ configuration
  │ │   └─ models
  │ │     └─ bank_reconciliation_config_spec.rb
  └─ fixtures
    └─ bank-reconciliation
      └─ bank-west.csv
```