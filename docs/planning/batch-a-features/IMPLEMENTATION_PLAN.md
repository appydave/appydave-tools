# IMPLEMENTATION_PLAN.md — batch-a-features

**Goal**: Four independent improvements batched into one parallel wave: token counting for gpt_context, progress indicators for dam S3 commands, terminal-width-aware column separators, and brand resolution integration tests.
**Started**: 2026-03-20
**Target**: All 4 complete, 860+ examples passing, rubocop 0 offenses

## Summary
- Total: 4 | Complete: 4 | In Progress: 0 | Pending: 0 | Failed: 0

## Pending

## In Progress

## Complete
- [x] B012 — brand-resolution-integration-tests — 10 examples: Config.brand_path, BrandResolver.expand, ProjectResolver.resolve + detect_from_pwd. Note: resolve raises RuntimeError not typed exception. 870 examples. v0.76.14. Commit: af571e7.
- [x] B001 — gpt-context-token-counting — --tokens/-t flag added; warn (not $stderr.puts — Style/StderrPuts) to stderr; thresholds at 100k+200k. 870 examples. v0.77.0. Commit: 2c6b9c4.
- [x] B010 — dam-column-widths — 9 separator lines terminal-width-aware; truncate_path helper added; 4 shorten_path calls updated; require 'io/console' added. Bundled into B001 commit. v0.77.0.
- [x] B009 — dam-progress-indicators — 5 commands updated (s3_up, s3_down, s3_status, archive, sync_ssd) with verb/dry_run-aware progress messages. 870 examples. v0.77.1. Commit: 3fec530.

## Failed / Needs Retry

## Notes & Decisions

### Wave Plan
All 4 work units touch different files — run in parallel, one wave.

| WU | Files |
|----|-------|
| B001 | `lib/gpt_context/options.rb`, `bin/gpt_context.rb` |
| B009 | `bin/dam` |
| B010 | `lib/dam/project_listing.rb` |
| B012 | `spec/appydave/tools/dam/brand_resolution_integration_spec.rb` (new) |

### kfix hygiene
kfix runs `git add .` internally. Ensure working tree contains ONLY intended files before calling kfix.
The other agents' in-progress changes will NOT appear in your working tree (each agent works independently).
Safe to call kfix once your specific files are the only changes present.
