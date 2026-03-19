# Next Round Brief

**Created:** 2026-03-19
**Updated:** 2026-03-19 (after three-lens audit)

---

## Recommended Next Campaign: gpt_context Fixes + FR-2 + Jump Verification

### Goal

Fix the two small blockers in `gpt_context/file_collector.rb` (B015, B019), then implement FR-2 (GPT Context AI help system). In parallel, verify whether BUG-1 (Jump get/remove) is still live before planning a Jump campaign.

### Background

**Three-lens audit findings changed the priority order:**

1. FR-2 has two small pre-conditions in `file_collector.rb` that must be fixed first:
   - `puts @working_directory` at line 15 (B019 — 1 line delete)
   - `FileUtils.cd` without `ensure` (B015 — wrap in block form)
   Both are ~5 minutes of work. Do them as the first commit of the FR-2 campaign.

2. BUG-1 (Jump get/remove) is mislabeled in the original backlog. Static analysis shows `Jump::Config#find` and `Commands::Remove` have correct dual-key guards. The bug may already be fixed or may be environmental. **Verify live before planning any Jump campaign.**

3. New high-priority bugs found by the audit (B016, B017) should be assessed for inclusion in the next campaign or scheduled shortly after.

### Suggested Work Units (FR-2 Campaign)

1. **Fix B019** — Delete `puts @working_directory` from `file_collector.rb:15` (1-line fix)
2. **Fix B015** — Wrap `FileUtils.cd` in block form in `file_collector.rb` (3-line fix)
3. **Implement FR-2** — Read `docs/specs/fr-002-gpt-context-help-system.md`. Option A from the spec (enhanced OptionParser with banner, separators, `--version`) is the correct approach. No changes to lib/ needed — this is a `bin/gpt_context.rb` enhancement.
4. **Verify BUG-1** — Run `bin/jump.rb get <key>` live. If broken: find actual failure site. If fixed: write regression spec for `Jump::Config#find` round-trip and close.

### Pre-Campaign Blockers: None

Neither fix requires architectural changes. FR-2 is contained to `bin/gpt_context.rb`. The Jump verification is read-only unless the bug is confirmed.

### What Agents Need to Know

- Read `docs/planning/AGENTS.md` — test/lint patterns, commit format, quality gates
- FR-2 spec: `docs/specs/fr-002-gpt-context-help-system.md`
- gpt_context source: `lib/appydave/tools/gpt_context/` + `bin/gpt_context.rb`
- Jump source: `lib/appydave/tools/jump/` (Config, Search, Commands/*)
- Jump tests: `spec/appydave/tools/jump/` + `spec/support/jump_test_helpers.rb`
- BUG-1 call chain: `CLI#run_get` → `Search#get` → `Config#find` → `locations.find { |loc| loc.key == key }`

### Also Schedule Soon (from audit)

- B016 — ManifestGenerator vs SyncFromSsd range string mismatch (data integrity — schedule next)
- B017 — ssl_verify_peer: false in S3Operations (security — schedule next)
- B018 — Jump Commands layer specs (no specs for Remove/Add/Update)

### Mode Recommendation

**Extend** — stack, patterns, and quality gates are known from prior campaigns. Use Extend, not Plan.
