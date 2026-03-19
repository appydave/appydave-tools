# IMPLEMENTATION_PLAN.md — final-test-gaps

**Goal**: Close remaining test quality gaps surfaced by the test-quality-audit: file_collector json/aider/error paths, cli_spec body assertions, add_spec data integrity, update_spec field isolation
**Started**: 2026-03-19
**Target**: All 4 work units complete; 817+ examples passing; rubocop clean; no regressions; regression catch rate meaningfully above 55%

## Summary
- Total: 4 | Complete: 0 | In Progress: 4 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [~] fix-b023 — file_collector_spec: add json format, aider format, and error path tests
- [~] fix-b028 — cli_spec: add file body content assertions to -i and -e tests
- [~] fix-b029 — add_spec: validate ALL returned location data fields match input attrs (path, jump, tags, description)
- [~] fix-b030 — update_spec: verify non-updated fields are unchanged on both updated record and sibling records

## Complete

## Failed / Needs Retry

## Notes & Decisions
- All 4 work units are independent — parallel wave
- Test-only campaign: no lib/ production code changes
- B019 and B015 already fixed in prior commits — closed without campaign
- B028 scope: -i tests check `# file: test.rb` header but not body; -e tests same gap. Add body content assertions only (do NOT rewrite existing assertions)
- B029 scope: "returns the created location data" test at line 35-41 of add_spec.rb — extend it to assert path/jump/tags/description. Add as a new 'it' block rather than modifying existing example.
- B030 scope: two gaps — (1) updated record: non-updated fields stay the same; (2) sibling record: not just key_exists? but fields are identical
- B023 scope: Options struct has :prompt field (keyword_init). Aider tests need `prompt: 'my prompt'` in options.
