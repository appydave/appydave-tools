# IMPLEMENTATION_PLAN.md — final-test-gaps

**Goal**: Close remaining test quality gaps surfaced by the test-quality-audit: file_collector json/aider/error paths, cli_spec body assertions, add_spec data integrity, update_spec field isolation
**Started**: 2026-03-19
**Target**: All 4 work units complete; 817+ examples passing; rubocop clean; no regressions; regression catch rate meaningfully above 55%

## Summary
- Total: 4 | Complete: 4 | In Progress: 0 | Pending: 0 | Failed: 0

## Pending

## In Progress

## Complete
- [x] fix-b023 — file_collector_spec: +10 examples (5 json, 4 aider, 1 error path). Key fix: json exclusion test needed `exclude_patterns: ['excluded/**/*']` not `[]`. Nonexistent dir test used non-matching glob to avoid false positives. 830 examples, 85.92% coverage.
- [x] fix-b028 — cli_spec: +6 body assertions across -i (3) and -e (3) blocks. No new example count (assertions added to existing `it` blocks). 830 examples, v0.76.3 released.
- [x] fix-b029 — add_spec: +1 example asserting path/jump/tags/description. Confirmed `location.to_h` uses symbol keys and `.compact`. 830 examples.
- [x] fix-b030 — update_spec: +2 examples (non-updated fields on updated record; sibling record field isolation). 11→13 examples. 830 examples.

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
