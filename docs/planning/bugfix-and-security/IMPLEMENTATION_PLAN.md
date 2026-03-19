# IMPLEMENTATION_PLAN.md — bugfix-and-security

**Goal**: Fix 3 blockers: ssl_verify_peer security hole (B017), range string mismatch (B016), dead format guard (B021)
**Started**: 2026-03-19
**Target**: All 3 fixes committed; tests pass; rubocop clean; no regressions

## Summary
- Total: 3 | Complete: 0 | In Progress: 3 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [~] fix-b017-ssl — Remove unconditional ssl_verify_peer: false from s3_operations.rb, share_operations.rb, s3_scanner.rb
- [~] fix-b016-range — Align SyncFromSsd#determine_range to ManifestGenerator format; update sync_from_ssd_spec.rb; add manifest_generator_spec.rb coverage
- [~] fix-b021-guard — Remove options.format.nil? from gpt_context.rb:115 guard; add/update spec for no-args behaviour

## Complete

## Failed / Needs Retry

## Notes & Decisions
- All 3 fixes are independent — run as parallel agents in one wave
- B017: s3_scanner.rb has ssl_verify_peer inline with NO env guard — remove entirely. s3_operations.rb and share_operations.rb have env guard + unconditional fallback — keep env guard, remove unconditional fallback. Return {} (empty hash) instead.
- B016: ManifestGenerator format is canonical (letter+50-range, e.g. b50-b99). SyncFromSsd format is wrong (10-range, no letter, e.g. 60-69). Fix SyncFromSsd to match. ManifestGenerator#determine_range has zero specs — add them.
- B021: options.format defaults to 'content' in Options class — format.nil? is always false. Remove the third AND condition. Update cli_spec or add spec to verify no-args exits with message.
- Discovered: s3_scanner.rb also affected by B017 (not in original brief)
