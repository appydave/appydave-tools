# IMPLEMENTATION_PLAN.md — extract-vat-cli

**Goal**: Extract 4 clusters of business logic from `bin/dam` (1,600-line VatCLI God class) into proper library classes. Prerequisite for parallelism (B007) and S3Operations split (B020).
**Started**: 2026-03-19
**Target**: All 4 complete; 831+ examples passing; rubocop 0 offenses; no regressions

## Summary
- Total: 4 | Complete: 0 | In Progress: 0 | Pending: 4 | Failed: 0

## Pending
- [x] extract-format-bytes — Replaced 4 callers (plan said 3; orphaned-projects loop in display_s3_scan_table was a 4th). format_bytes deleted. rubocop 0 offenses. Commit: 3cd362f.
- [x] extract-local-sync-status — LocalSyncStatus module created, 7 specs added (838 total), both methods gone from VatCLI. Side-fix: restored youtube_automation_config require incorrectly removed in prior commit. v0.76.5.
- [x] extract-s3-scan-command — S3ScanCommand created, 2 smoke tests added (840 total), 3 methods gone from VatCLI. Note: rubocop-disable directives became redundant once methods left God class — needed 2nd kfix to remove them. v0.76.6.
- [~] extract-s3-arg-parser — Extract `parse_s3_args` + `valid_brand?` + `parse_share_args` + `show_share_usage_and_exit` + `parse_discover_args` → new `S3ArgParser` class; add spec

## In Progress

## Complete

## Failed / Needs Retry

## Notes & Decisions

### Sequencing
All 4 work units touch `bin/dam` — they MUST run sequentially, not in parallel. Wave size = 1.
Sequence: extract-format-bytes → extract-local-sync-status → extract-s3-scan-command → extract-s3-arg-parser
`extract-s3-scan-command` depends on `LocalSyncStatus` created in `extract-local-sync-status`.

### New files to create
- `lib/appydave/tools/dam/local_sync_status.rb`
- `lib/appydave/tools/dam/s3_scan_command.rb`
- `lib/appydave/tools/dam/s3_arg_parser.rb`

### Register new files
Add require lines to `lib/appydave/tools.rb` after line 79 (after `repo_push`):
```ruby
require 'appydave/tools/dam/local_sync_status'
require 'appydave/tools/dam/s3_scan_command'
require 'appydave/tools/dam/s3_arg_parser'
```

### format_bytes caller locations in bin/dam
- Line 1510: `display_s3_scan_table` → `format_bytes(data[:total_bytes])`
- Line 696: `display_s3_files` → `format_bytes(size)`
- Line 702: `display_s3_files` → `format_bytes(total_bytes)`
Replace all with: `Appydave::Tools::Dam::FileHelper.format_size(x)`

### FileHelper.format_size vs format_bytes
Both return identical output. `format_size` uses named format tokens (`%<size>.1f`) which satisfies rubocop Style/FormatStringToken. `format_bytes` used positional tokens (`%.1f`) — hence the rubocop-disable. After extraction, the disable comment goes away.

### parse_share_args scope decision
Included `parse_share_args` + `show_share_usage_and_exit` + `parse_discover_args` in S3ArgParser (same ENV['BRAND_PATH'] pattern, same brand/project resolution chain). All 5 parser methods share identical structure and belong together.

### ENV['BRAND_PATH'] residuals
After S3ArgParser extraction, 2 ENV['BRAND_PATH'] assignments remain in VatCLI:
- `generate_single_manifest` (line 278)
- `sync_ssd_command` (line 325)
These are out of scope — leave for a future campaign.

### Do NOT attempt B020 (S3Operations split) in this campaign
Scope is VatCLI extraction only. S3Operations refactor is a separate campaign.
