# IMPLEMENTATION_PLAN.md — batch-a-features

**Goal**: Four independent improvements batched into one parallel wave: token counting for gpt_context, progress indicators for dam S3 commands, terminal-width-aware column separators, and brand resolution integration tests.
**Started**: 2026-03-20
**Target**: All 4 complete, 860+ examples passing, rubocop 0 offenses

## Summary
- Total: 4 | Complete: 0 | In Progress: 4 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [~] B001 — gpt-context-token-counting — Add --tokens flag to gpt_context; print estimated token count + threshold warnings
- [~] B009 — dam-progress-indicators — Add before/after progress messages to s3_up, s3_down, s3_status, archive, sync_ssd in bin/dam
- [~] B010 — dam-column-widths — Terminal-width-aware separator lines + path truncation in project_listing.rb
- [~] B012 — brand-resolution-integration-tests — Integration spec covering brand→project resolution chain end-to-end

## Complete

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
