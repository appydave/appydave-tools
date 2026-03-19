# Next Round Brief

**Created:** 2026-03-19
**Updated:** 2026-03-19 (after fr2-gpt-context-help assessment)

---

## Recommended Next Campaign: bugfix-and-security

### Goal

Fix two BLOCKER-level bugs (B016, B017) and one dead-code guard (B021) before building any new S3 or archive features.

### Background

Quality audit after fr2-gpt-context-help surfaced these as blockers:

1. **B017** — `ssl_verify_peer: false` hardcoded unconditionally in `S3Operations` and `ShareOperations`. Removes MITM protection on all S3 operations including credential transmission. Must fix before any S3 feature work.
2. **B016** — `ManifestGenerator.determine_range` returns `"b50-b99"` format; `SyncFromSsd.determine_range` returns `"60-69"` format. Incompatible SSD path construction means projects can be silently missed during archive/restore. Must fix before any archive feature work.
3. **B021** — `bin/gpt_context.rb` line 115 guard checks `options.format.nil?` as third AND condition. `format` defaults to `'content'` in Options — never nil. Dead condition; guard can only fire on include/exclude emptiness. 5-minute fix.

### Suggested Work Units

1. **Fix B017** — Remove `ssl_verify_peer: false` from `S3Operations` and `ShareOperations`. No env flag needed — AWS SDK handles SSL correctly by default.
2. **Fix B016** — Align range string format between `ManifestGenerator` and `SyncFromSsd`. Read actual SSD folder structure on disk first to determine which format matches reality; update the other to match.
3. **Fix B021** — Remove `&& options.format.nil?` from guard at `bin/gpt_context.rb:115`. Update or add spec to verify no-args behavior.

### Optional (bundle if small)

- **B018** — Jump Commands layer specs (Remove/Add/Update) — no code changes, just test coverage
- **B022** — Expand cli_spec.rb with functional tests for -i, -e, -f, -o flags

### Mode Recommendation

**Extend** — stack, patterns, and quality gates known. Inherit AGENTS.md.

### Pre-Campaign Blockers: None

All three fixes are standalone. B016 requires reading SSD disk structure before writing code (per AGENTS.md: read actual files before designing data shapes).
