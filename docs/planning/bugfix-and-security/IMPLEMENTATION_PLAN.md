# IMPLEMENTATION_PLAN.md — bugfix-and-security

**Goal**: Fix 3 blockers: ssl_verify_peer security hole (B017), range string mismatch (B016), dead format guard (B021)
**Started**: 2026-03-19
**Target**: All 3 fixes committed; tests pass; rubocop clean; no regressions

## Summary
- Total: 3 | Complete: 3 | In Progress: 0 | Pending: 0 | Failed: 0

## Pending

## In Progress

## Complete
- [x] fix-b017-ssl — ssl_verify_peer: false removed from s3_operations.rb, share_operations.rb, s3_scanner.rb. s3_operations_spec stub updated. 755 examples, 0 failures. v0.76.0 published.
- [x] fix-b021-guard — Removed dead format.nil? condition (format defaults to 'tree,content', never nil). Added no-args spec asserting exit 0 + error message. Used $CHILD_STATUS not $? (rubocop). 755 examples, 0 failures.
- [x] fix-b016-range — SyncFromSsd#determine_range aligned to ManifestGenerator format (any letter, 50-number ranges). Updated 4 unit specs + 4 integration path assertions in sync_from_ssd_spec. Added 4 new specs to manifest_generator_spec. 759 examples, 0 failures. v0.76.1 published.

## Failed / Needs Retry

## Notes & Decisions
- All 3 fixes are independent — run as parallel agents in one wave
- B017: s3_scanner.rb has ssl_verify_peer inline with NO env guard — remove entirely. s3_operations.rb and share_operations.rb have env guard + unconditional fallback — keep env guard, remove unconditional fallback. Return {} (empty hash) instead.
- B016: ManifestGenerator format is canonical (letter+50-range, e.g. b50-b99). SyncFromSsd format is wrong (10-range, no letter, e.g. 60-69). Fix SyncFromSsd to match. ManifestGenerator#determine_range has zero specs — add them.
- B021: options.format defaults to 'content' in Options class — format.nil? is always false. Remove the third AND condition. Update cli_spec or add spec to verify no-args exits with message.
- Discovered: s3_scanner.rb also affected by B017 (not in original brief)
