# Bank Reconciliation

Process and reconcile bank transaction data with filtering, transformation, and cleanup capabilities.

## What It Does

**Bank Reconciliation** handles financial transaction processing:

- Cleans and normalizes transaction CSV data
- Transforms transaction formats for analysis
- Filters transactions by criteria
- Processes transaction batches
- Handles multiple bank CSV formats
- Prepares data for reconciliation systems

## How to Use

### Clean Transactions

Normalize transaction CSV files:

```bash
bank_reconciliation clean -i "*.csv" -f ./transactions -o cleaned_transactions.csv
```

### Transform Transactions

Convert transactions to different formats:

```bash
bank_reconciliation transform -i "*.csv" -f ./transactions -o transformed.csv
```

### Process Transactions

Full processing pipeline:

```bash
bank_reconciliation process -i "*.csv" -f ./transactions -o processed.csv
```

### Filter Transactions

Select specific transactions:

```bash
bank_reconciliation filter -i "*.csv" -f ./transactions -o filtered.csv
```

## Command Reference

### Clean Command
```bash
bank_reconciliation clean [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Include Pattern | `-i` | `--include PATTERN` | GLOB pattern for source files |
| Transaction Folder | `-f` | `--transaction FOLDER` | Folder with CSV files |
| Output File | `-o` | `--output FILE` | Output CSV file |
| Help | `-h` | `--help` | Show help |

### Transform Command
```bash
bank_reconciliation transform [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Include Pattern | `-i` | `--include PATTERN` | GLOB pattern for source files |
| Transaction Folder | `-f` | `--transaction FOLDER` | Folder with CSV files |
| Output File | `-o` | `--output FILE` | Output file |
| Format | `-F` | `--format FORMAT` | Output format (csv, json, etc.) |
| Help | `-h` | `--help` | Show help |

### Process Command
```bash
bank_reconciliation process [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Include Pattern | `-i` | `--include PATTERN` | GLOB pattern for source files |
| Transaction Folder | `-f` | `--transaction FOLDER` | Folder with CSV files |
| Output File | `-o` | `--output FILE` | Output file |
| Help | `-h` | `--help` | Show help |

### Filter Command
```bash
bank_reconciliation filter [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Include Pattern | `-i` | `--include PATTERN` | GLOB pattern for source files |
| Transaction Folder | `-f` | `--transaction FOLDER` | Folder with CSV files |
| Output File | `-o` | `--output FILE` | Output file |
| Min Amount | `-m` | `--min-amount AMOUNT` | Minimum transaction amount |
| Max Amount | `-M` | `--max-amount AMOUNT` | Maximum transaction amount |
| Help | `-h` | `--help` | Show help |

## Use Cases for AI Agents

### 1. Transaction Data Cleanup
```bash
# AI orchestrates cleaning of multiple bank exports
bank_reconciliation clean -i "*.csv" -f ./monthly-statements
```
**AI discovers**: Data quality issues, formatting inconsistencies. Can systematically clean transaction data.

### 2. Bank Format Unification
```bash
# Convert multiple bank formats to standard
# Different banks export different CSV layouts
# Transform normalizes to single format
bank_reconciliation transform -i "*.csv" -f ./exports
```
**AI discovers**: Format variations across banks. Can unify disparate data sources.

### 3. Reconciliation Preparation
```bash
# Process transactions before reconciliation
# Clean, transform, and normalize in sequence
bank_reconciliation process -i "*.csv" -f ./transactions
```
**AI discovers**: Full workflow. Can prepare data for reconciliation system.

### 4. Large Transaction Filtering
```bash
# Identify high-value transactions
bank_reconciliation filter -i "*.csv" -f ./transactions -m 1000
```
**AI discovers**: Transaction patterns, high-value activity. Can analyze spending by category.

### 5. Fraud Detection Preparation
```bash
# Extract unusual transactions for review
bank_reconciliation filter -i "*.csv" -f ./transactions
# AI analyzes filtered results for anomalies
```
**AI discovers**: Transaction dataset. Can identify suspicious patterns.

### 6. Tax Reporting
```bash
# Filter transactions for tax categories
# Process Q1, Q2, Q3, Q4 separately
bank_reconciliation process -i "q1*.csv" -o "q1-reconciled.csv"
```
**AI discovers**: Quarterly data. Can prepare tax reporting documents.

### 7. Vendor Analysis
```bash
# Process all transactions
# AI analyzes to identify top vendors
# Groups spending by vendor
bank_reconciliation process -i "*.csv" -f ./all-transactions
```
**AI discovers**: Complete transaction data. Can generate vendor reports.

### 8. Budget vs. Actual
```bash
# Process actual transactions
# AI compares against budget
# Calculates variances
bank_reconciliation process -i "*.csv" -f ./actual-spend
```
**AI discovers**: Spending patterns. Can reconcile against budget.

### 9. Batch Reconciliation
```bash
# Process multiple months of data
for month in jan feb mar apr may jun; do
  bank_reconciliation process -i "$month*.csv" -o "$month-processed.csv"
done
```
**AI discovers**: Monthly patterns, trends. Can automate recurring reconciliation.

### 10. Data Quality Audit
```bash
# Clean, then compare before/after
# Identify what was changed
# Assess data quality improvements
bank_reconciliation clean -i "*.csv" -f ./raw -o ./cleaned
```
**AI discovers**: Data issues, cleaning effectiveness. Can audit data quality metrics.

## Supported Bank Formats

The tool handles CSV export formats from:

- Major US Banks (Chase, Bank of America, Wells Fargo, etc.)
- International Banks (different date/amount formats)
- Credit Card Issuers (Visa, Mastercard processors)
- Investment Platforms (broker exports)
- Payment Services (PayPal, Stripe, Square)

## Transaction CSV Structure

Expected columns (flexible, auto-detected):

```
Date | Description | Amount | Balance | Type | Reference
-----|-------------|--------|---------|------|----------
1/1  | Starbucks   | -5.00  | 1000    | DR   | COFFEE123
1/2  | Salary      | 5000   | 6000    | CR   | PAYROLL
```

## Workflow Integration

Typical reconciliation workflow:

```
1. Export from Banks (manual or API)
2. Clean Data (bank_reconciliation clean)
3. Transform if Needed (bank_reconciliation transform)
4. Filter as Needed (bank_reconciliation filter)
5. Load to Accounting System (QuickBooks, etc.)
6. Reconcile (accounting software)
7. Report (taxes, budgets, analysis)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "File not found" | Verify CSV files exist in specified folder |
| "Invalid CSV format" | Use `clean` command first to fix formatting |
| "No data processed" | Check include pattern (e.g., `*.csv` not `*.txt`) |
| "Amount format error" | Ensure amounts are numeric, clean first |

## Tips & Tricks

1. **Always clean first**: `clean` fixes encoding and formatting issues
2. **Keep raw exports**: Backup original CSVs before processing
3. **Use patterns efficiently**: `-i "*.csv"` or `-i "201[0-9]-*.csv"`
4. **Process by period**: Monthly/quarterly processing is easier to debug
5. **Validate output**: Check processed CSV before importing to accounting system

## Example Workflow

```bash
# Step 1: Export from banks
# Download CSVs from Chase, Bank of America, Credit Card companies

# Step 2: Clean all exports
bank_reconciliation clean -i "*.csv" -f ./exports -o all-cleaned.csv

# Step 3: Transform to standard format
bank_reconciliation transform -i "all-cleaned.csv" -F "csv" -o standard-format.csv

# Step 4: Process for reconciliation
bank_reconciliation process -i "standard-format.csv" -o reconciliation-ready.csv

# Step 5: Load into accounting system
# Import reconciliation-ready.csv into QuickBooks, Xero, Wave, etc.

# Step 6: Manual reconciliation review
# Compare against bank statements
# Mark items as reconciled
```

---

**Status**: Private financial tool - Not for public use
**Security**: All transaction data is sensitive - Keep locally, never share
**Related**: Configuration management for secure storage

**Note**: Bank reconciliation is a private tool for personal financial management. Keep data secure and local.
