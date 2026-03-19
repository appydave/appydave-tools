# IMPLEMENTATION_PLAN.md — micro-cleanup

**Goal**: Close 3 small items from the final-test-gaps quality audit: type field assertion (B031), -f json CLI test (B032), file_collector.rb silent-collection fix (B033)
**Started**: 2026-03-19
**Target**: All 3 complete; 830+ examples passing; rubocop clean; no regressions

## Summary
- Total: 3 | Complete: 3 | In Progress: 0 | Pending: 0 | Failed: 0

## Pending

## In Progress

## Complete
- [x] fix-b031 — already committed in prior pass (commit 8eec40c). Assertion `expect(location[:type]).to eq('tool')` found at add_spec.rb line 51. Closed without action.
- [x] fix-b033 — already fixed in commit 13d5f87 (`return '' unless` already in place). Closed without action.
- [x] fix-b032 — added `-f json` subprocess test to cli_spec. 831 examples, 0 failures, v0.76.4. Side issue: kfix accidentally staged pre-existing uncommitted changes to lib/appydave/tools.rb (removed youtube_automation_config require). Fixed in follow-up commit.

## Complete

## Failed / Needs Retry

## Notes & Decisions
- All 3 work units are independent — parallel wave
- B033 is a production code change (1 line) — needs a spec update to confirm the behaviour
- B031 and B032 are test-only
- B033 fix: change `return build_formats unless` to `return '' unless` on line 19 of file_collector.rb
- B031 fix: add `expect(location[:type]).to eq('tool')` to the existing 'returns location data matching all input attrs' it block
- B032 fix: new it block in '-f format' describe context — subprocess with `-f json`, parse output as JSON, assert tree+content keys present
