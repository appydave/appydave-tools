# Assessment: final-test-gaps

**Campaign**: final-test-gaps
**Date**: 2026-03-19 → 2026-03-19
**Results**: 4 complete, 0 failed
**Version shipped**: v0.76.3
**Quality audit**: code-quality-audit + test-quality-audit run post-campaign

---

## Results Summary

| Work Unit | Examples Added | Notes |
|-----------|---------------|-------|
| fix-b023 | +10 | file_collector_spec: 5 json + 4 aider + 1 error path. Agent fixed json exclusion test (needed `exclude_patterns: ['excluded/**/*']` not `[]`) |
| fix-b028 | +0 new examples, +6 assertions | Body content assertions added to existing -i/-e `it` blocks in cli_spec |
| fix-b029 | +1 | add_spec: location data integrity (path/jump/tags/description) |
| fix-b030 | +2 | update_spec: non-updated fields on updated record + sibling record isolation |

**817 → 830 examples (+13). 85.61% → 85.92% coverage.**

---

## What Worked Well

- **B023 agent self-corrected the json exclusion test.** Plan specified `exclude_patterns: []` for the json exclusion test — agent recognised this would not actually test exclusion and changed to `exclude_patterns: ['excluded/**/*']`. Agents reading source before writing improved test quality.
- **B023 agent handled the nonexistent-dir edge case correctly.** Used a pattern that matches nothing in CWD (`['**/*.nonexistent_xyz_12345']`) to avoid false positives when `build_formats` falls through to current directory.
- **Parallel wave, zero merge conflicts.** 4 agents, all different files.
- **Regression catch rate measurably improved.** C (55%) → B (70-75%). All major gaps from the prior audit are closed.

---

## What Didn't Work

**Code quality MINOR — `file_collector.rb:19` silent collection from CWD:**
When `working_directory` doesn't exist, `build_formats` runs without `FileUtils.cd`, meaning `Dir.glob` runs in the current process directory. The spec confirms "returns empty string" only because the test uses a non-matching glob — not because the code guarantees it.

**Test gap — `type` field missing from add_spec data integrity test:**
`valid_attrs` includes `type: 'tool'` but the new B029 integrity test doesn't assert `location[:type]`. Field mapping bug for `type` would still pass silently.

**Test gap — no CLI-level test for `-f json` or `-f aider` format flags:**
These formats are unit-tested in file_collector_spec but not via subprocess in cli_spec. A regression in CLI flag parsing for these formats would pass.

---

## Key Learnings — Application

- **`build_formats` fallthrough is a silent failure mode.** When `Dir.exist?` is false, the code returns `build_formats` result — not `''`. The guard at line 19 should probably return `''` directly rather than calling `build_formats` without cd.
- **`exclude_patterns: []` tests exclusion vacuously.** An empty exclude list means no exclusion test is happening. Always use a real pattern when testing that something is excluded.
- **`build_aider` embeds unsanitised prompt and file paths.** Prompts with quotes or paths with spaces produce malformed aider command output. Low severity now, worth capturing.
- **Agent pre-read + source verification pattern is working.** Both b029 and b030 agents read the source files and confirmed field accessor names before writing assertions — zero failures from wrong field names.

---

## New Backlog Items from Quality Audit

- **B031** — Tests: add_spec.rb assert `type` field in data integrity test | Priority: low
- **B032** — Tests: cli_spec.rb add subprocess test for `-f json` flag | Priority: low
- **B033** — Fix: file_collector.rb line 19 — return `''` directly when working_directory doesn't exist (don't delegate to build_formats) | Priority: low

---

## Suggestions for Next Campaign

**Test debt is largely cleared.** The suite is at B grade (70-75% regression catch rate). The remaining gaps (B031/B032/B033) are low severity.

**Recommended next move: architectural work.**

- **B011** — Extract VatCLI business logic from `bin/dam` (1,600 lines). This is the prerequisite for any parallelism or performance work. 20+ rubocop-disable comments are the symptom.
- **B020** — Split `S3Operations` (1,030 lines). Required before B007 (parallel S3 checks) can be built cleanly.

These are larger than any prior campaign. Recommend scoping carefully — one of the two per campaign, not both. B011 first (it's the CLI entry point and larger structural problem).

Or, if David wants a quick win: B031/B032/B033 as a micro-campaign (3 test items, 1 production fix, one wave).
