# IMPLEMENTATION_PLAN.md — micro-cleanup

**Goal**: Close 3 small items from the final-test-gaps quality audit: type field assertion (B031), -f json CLI test (B032), file_collector.rb silent-collection fix (B033)
**Started**: 2026-03-19
**Target**: All 3 complete; 830+ examples passing; rubocop clean; no regressions

## Summary
- Total: 3 | Complete: 0 | In Progress: 3 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [~] fix-b031 — add_spec: add `type` field assertion to location data integrity test
- [~] fix-b032 — cli_spec: add subprocess test for `-f json` flag
- [~] fix-b033 — file_collector.rb: return `''` directly when working_directory doesn't exist (line 19)

## Complete

## Failed / Needs Retry

## Notes & Decisions
- All 3 work units are independent — parallel wave
- B033 is a production code change (1 line) — needs a spec update to confirm the behaviour
- B031 and B032 are test-only
- B033 fix: change `return build_formats unless` to `return '' unless` on line 19 of file_collector.rb
- B031 fix: add `expect(location[:type]).to eq('tool')` to the existing 'returns location data matching all input attrs' it block
- B032 fix: new it block in '-f format' describe context — subprocess with `-f json`, parse output as JSON, assert tree+content keys present
