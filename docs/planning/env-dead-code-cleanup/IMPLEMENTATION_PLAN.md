# IMPLEMENTATION_PLAN.md — env-dead-code-cleanup

**Goal**: Remove confirmed dead code (10× `ENV['BRAND_PATH']` in bin/dam) and strengthen s3_scan_command_spec data-value assertions. Closes B038 + B039 from the library-boundary-cleanup audit.
**Started**: 2026-03-20
**Target**: Both items complete; 861+ examples passing; rubocop 0 offenses; no regressions

## Summary
- Total: 2 | Complete: 2 | In Progress: 0 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [x] B038 — remove-env-dead-code — All 10 ENV['BRAND_PATH'] assignments removed from bin/dam; 0 cascade removals (options still used for other keys). CI fix needed: git add . staged s3_scan_command_spec.rb with pre-existing RSpec/RepeatedExample offense — fixed via second commit. 860 examples, 0 failures. Commits: 5c11027, 5711e4e.
- [x] B039 — strengthen-s3-scan-spec — Field-value assertions on both not_to be_empty checks; LocalSyncStatus stub removed (runs for real against fixture filesystem, returns :no_files). 861 examples, 0 failures. v0.76.12. Commit: 7f1fc5a.

## Complete

## Failed / Needs Retry

## Notes & Decisions

### Wave Plan

**Wave 1 — B038 + B039 in parallel**
- B038 touches `bin/dam` only
- B039 touches `spec/appydave/tools/dam/s3_scan_command_spec.rb` only
- No shared files — safe to run in parallel

### B038: All 10 ENV assignments confirmed dead (2026-03-20)

| Line | Method | Form |
|------|--------|------|
| 158 | s3_up_command | `options[:brand_path]` |
| 169 | s3_down_command | `options[:brand_path]` |
| 180 | s3_status_command | `options[:brand_path]` |
| 191 | s3_cleanup_remote_command | `options[:brand_path]` |
| 202 | s3_cleanup_local_command | `options[:brand_path]` |
| 213 | s3_archive_command | `options[:brand_path]` |
| 224 | s3_share_command | `options[:brand_path]` |
| 238 | s3_discover_command | `options[:brand_path]` |
| 285 | generate_single_manifest | `Config.brand_path(brand_arg)` |
| 332 | sync_ssd_command | `Config.brand_path(brand_arg)` |

- `grep -rn "BRAND_PATH" lib/ spec/` → 0 results (confirmed 2026-03-20)
- ManifestGenerator and SyncFromSsd do not read ENV['BRAND_PATH'] (confirmed 2026-03-20)

### B039: What to strengthen in s3_scan_command_spec

- Replace `expect(project[:storage][:s3]).not_to be_empty` with `include(file_count: 3, total_bytes: 1_500_000)`
- Remove `allow(Appydave::Tools::Dam::LocalSyncStatus).to receive(:enrich!)` stub — let it run for real
- If LocalSyncStatus.enrich! needs the s3-staging path to exist, create it in the fixture setup
