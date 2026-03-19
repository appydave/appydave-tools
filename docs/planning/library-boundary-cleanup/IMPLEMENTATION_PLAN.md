# IMPLEMENTATION_PLAN.md — library-boundary-cleanup

**Goal**: Fix two architectural boundary violations introduced by extract-vat-cli, then fill the test gaps they blocked. Prerequisite for B007 (parallelism) and clean library boundaries.
**Started**: 2026-03-19
**Target**: 4 items complete; 847+ examples passing; rubocop 0 offenses; no regressions

## Summary
- Total: 4 | Complete: 3 | In Progress: 1 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [x] B036 — tests-s3-scan-command — 10 behaviour examples replacing 2 smoke tests (happy path, manifest missing, empty results, orphaned projects, scan_all partial). 861 examples, 0 failures. 86.43% coverage. v0.76.10. Commit: de9d118.
- [~] B037 — tests-local-sync-status — Add :partial case, local_file_count assertion, Zone.Identifier exclusion, unknown format guard

## Complete
- [x] B034 — extract-exit-calls — UsageError added to errors.rb; exit 1 replaced in s3_scan_command.rb (1) and s3_arg_parser.rb (4); show_share_usage_and_exit renamed. 847 examples, 0 failures. v0.76.8. Commit: 87bb43a.
- [x] B035 — extract-env-side-effect — ENV['BRAND_PATH'] removed from s3_arg_parser.rb (3 locations); brand_path: returned in all 3 result hashes; 8 VatCLI callers updated. 847 examples, 0 failures. v0.76.9. Commit: 762da4b.

## Complete

## Failed / Needs Retry

## Notes & Decisions

### Wave Plan

**Wave 1 — B034** (alone)
- Touches: `s3_scan_command.rb`, `s3_arg_parser.rb`, `errors.rb`
- No parallel candidates — all three files must be edited together

**Wave 2 — B035** (after B034)
- Touches: `s3_arg_parser.rb`, `bin/dam`
- Cannot run with B034 (shared `s3_arg_parser.rb`)
- No behaviour change — moves ENV side-effect to CLI layer only

**Wave 3 — B036 + B037** (parallel — different spec files, no shared edits)
- B036: `spec/appydave/tools/dam/s3_scan_command_spec.rb`
- B037: `spec/appydave/tools/dam/local_sync_status_spec.rb`
- Both depend on B034 being complete (exceptions must exist before testing them)

### Sequencing Constraints
- B034 must complete before B035 (both touch s3_arg_parser.rb)
- B034 must complete before B036 (can't test raised exceptions until they exist)
- B035 must complete before B036 + B037 (ENV side-effect removal may affect test setup)
- B036 and B037 are fully parallel once B034 + B035 are done

### Exit Locations Confirmed (read 2026-03-19)
- `S3ScanCommand#scan_single` line 55: manifest not found → raise `ConfigurationError`
- `S3ArgParser#parse_s3` line 25: PWD auto-detect fail → raise `UsageError`
- `S3ArgParser#parse_s3` line 43: invalid brand → raise `UsageError`
- `S3ArgParser#parse_discover` line 100: missing brand/project args → raise `UsageError`
- `S3ArgParser#show_share_usage_and_exit` line 131: missing share args → raise `UsageError`

### ENV Side-Effect Locations Confirmed (read 2026-03-19)
- `S3ArgParser#parse_s3` line 51: `ENV['BRAND_PATH'] = ...`
- `S3ArgParser#parse_share` line 82: `ENV['BRAND_PATH'] = ...`
- `S3ArgParser#parse_discover` line 108: `ENV['BRAND_PATH'] = ...`
- Fix: return `brand_path:` in each result hash; update VatCLI callers to set ENV there

### VatCLI Rescue Blocks
- `s3_scan_command`, `s3_up_command`, etc. already rescue `StandardError => e` and `puts "❌ Error: #{e.message}"`
- No VatCLI rescue changes needed for B034 — existing rescues already catch DamError (which inherits from StandardError)
