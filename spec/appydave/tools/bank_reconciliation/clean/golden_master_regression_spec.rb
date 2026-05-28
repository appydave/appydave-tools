# frozen_string_literal: true

# Golden-master regression: runs the resurrected pipeline against 9 historical
# raw bank exports and compares the output against a baseline captured on
# 2026-05-28. This proves the resurrection is structurally identical and
# locks down behavior going forward — any code or config change that produces
# a different output triggers a failure.
#
# Baseline history:
#   baseline-2026-05-15.csv — original resurrection baseline (Wise all rows as debit)
#   baseline-2026-05-28.csv — re-captured after Wise Direction fix (IN→credit, OUT→debit)
#
# Note: the original July-2025 `clean_transactions.csv` is preserved at
# spec/fixtures-private/golden/clean_transactions.csv but is NOT used as the
# assertion target — it diverges from a clean pipeline run (manual edits +
# COA evolution after generation: CAPITAL-TRANSFER → CAPITAL_TRANSFER, ~19
# codes / 477 rows of cumulative drift). The 2026-05-15 baseline is the new
# regression target. See also: structural assertions (row count, headers)
# below which validate against the July-2025 snapshot too.
#
# The fixtures contain real personal banking data and live at
# spec/fixtures-private/ — gitignored, never committed. To populate on a fresh
# machine:
#
#   mkdir -p spec/fixtures-private/{golden,golden-inputs}
#   cp ~/dev/bank-reconciliation/-old-tax-reconciliation/original-transactions/clean/clean_transactions.csv \
#      spec/fixtures-private/golden/
#   cp ~/dev/bank-reconciliation/-old-tax-reconciliation/chart_of_accounts.csv \
#      spec/fixtures-private/golden/
#   cp ~/dev/bank-reconciliation/-old-tax-reconciliation/original-transactions/Transactions_*.csv \
#      spec/fixtures-private/golden-inputs/
#
# Uses the live config at ~/.config/appydave/bank-reconciliation.json. If the
# pipeline output diverges from the golden master, the spec reports the first
# few diff rows so the cause can be inspected.

require 'csv'
require 'tmpdir'
require 'fileutils'

RSpec.describe Appydave::Tools::BankReconciliation::Clean::CleanTransactions, :regression do
  let(:fixtures_dir) { File.expand_path('../../../../fixtures-private', __dir__) }
  let(:golden_dir) { File.join(fixtures_dir, 'golden') }
  let(:july_2025_snapshot) { File.join(golden_dir, 'clean_transactions.csv') }
  let(:current_baseline_path) { File.join(golden_dir, 'baseline-2026-05-28.csv') }
  let(:golden_config_path) { File.join(golden_dir, 'bank-reconciliation.json') }
  let(:inputs_dir) { File.join(fixtures_dir, 'golden-inputs') }
  let(:output_dir) { Dir.mktmpdir('golden-master-output-') }
  let(:output_filename) { 'output.csv' }
  let(:output_path) { File.join(output_dir, output_filename) }

  let(:cleaner) { described_class.new(transaction_folder: inputs_dir, output_folder: output_dir) }

  before do
    skip 'Private fixtures absent — see file header for setup instructions' unless File.exist?(july_2025_snapshot)
    skip 'Current baseline absent — capture via the spec or fixture-setup script' unless File.exist?(current_baseline_path)
    skip 'Snapshot config absent — regenerate via spec/fixtures-private/golden/bank-reconciliation.json' unless File.exist?(golden_config_path)
    skip 'golden-inputs directory empty' if Dir[File.join(inputs_dir, '*.csv')].empty?

    # Point Config at the snapshotted golden-master config — NOT the user's live
    # ~/.config/appydave/bank-reconciliation.json. The snapshot pins the exact
    # bank_accounts + COA + sign_flip_rules that produced clean_transactions.csv
    # in July 2025, so drift in the live config doesn't break this regression.
    Appydave::Tools::Configuration::Config.configure do |c|
      c.config_path = golden_dir
      c.register(:bank_reconciliation, Appydave::Tools::Configuration::Models::BankReconciliationConfig)
    end

    # Avoid clobbering the user's clipboard during test runs.
    allow(cleaner).to receive(:csv_to_clipboard)
  end

  after do
    FileUtils.rm_rf(output_dir)
    Appydave::Tools::Configuration::Config.reset
  end

  describe 'structural fidelity against July-2025 snapshot' do
    # These assertions prove the resurrected pipeline still produces the same
    # SHAPE of output as the original: same row count, same columns. They
    # ignore COA categorisation drift (which evolved post-generation).
    before do
      cleaner.clean_transactions(['*.csv'], output_filename)
    end

    let(:july_2025_rows) { CSV.read(july_2025_snapshot, headers: true) }
    let(:actual_rows)    { CSV.read(output_path, headers: true) }

    it 'produces the same number of rows as the July-2025 snapshot' do
      expect(actual_rows.size).to eq(july_2025_rows.size),
                                  "Expected #{july_2025_rows.size} rows, got #{actual_rows.size}"
    end

    it 'produces the same column headers as the July-2025 snapshot' do
      expect(actual_rows.headers).to eq(july_2025_rows.headers)
    end
  end

  describe 'byte-for-byte against 2026-05-15 baseline (forward regression guard)' do
    # This assertion locks in the EXACT output the resurrected pipeline produces
    # today. Any future code or config change that alters output will fail this
    # spec — letting us catch regressions immediately. To intentionally update
    # the baseline (e.g., after a fix), regenerate baseline-2026-05-15.csv (or
    # rename to a new dated baseline) and commit alongside the change.
    before do
      cleaner.clean_transactions(['*.csv'], output_filename)
    end

    let(:expected_rows) { CSV.read(current_baseline_path, headers: true) }
    let(:actual_rows)   { CSV.read(output_path, headers: true) }

    it 'produces semantically identical rows' do
      diffs = []
      max_rows = [actual_rows.size, expected_rows.size].min

      max_rows.times do |i|
        actual_h = actual_rows[i]&.to_h
        expected_h = expected_rows[i]&.to_h
        next if actual_h == expected_h

        diffs << { index: i, expected: expected_h, actual: actual_h }
        break if diffs.size >= 5
      end

      expect(diffs).to be_empty, build_diff_message(diffs, expected_rows.size, actual_rows.size)
    end
  end

  def build_diff_message(diffs, expected_count, actual_count)
    lines = ["Golden-master mismatch — first #{diffs.size} diff row(s):"]
    diffs.each do |d|
      lines << ''
      lines << "  Row #{d[:index]}:"
      lines << '    EXPECTED:'
      d[:expected]&.each { |k, v| lines << "      #{k}: #{v.inspect}" }
      lines << '    ACTUAL:'
      d[:actual]&.each { |k, v| lines << "      #{k}: #{v.inspect}" }
    end
    lines << ''
    lines << "(Expected #{expected_count} rows total, actual #{actual_count} rows)"
    lines.join("\n")
  end
end
