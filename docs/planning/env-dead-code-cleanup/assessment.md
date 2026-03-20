# Assessment: env-dead-code-cleanup

**Campaign**: env-dead-code-cleanup
**Date**: 2026-03-20 → 2026-03-20
**Results**: 2 complete, 0 failed
**Final version**: v0.76.13 (from v0.76.11 baseline)
**Quality audits**: code-quality-audit ✅ | test-quality-audit ✅

---

## Results Summary

| Work Unit | Description | Result | Version |
|-----------|-------------|--------|---------|
| B038 | remove-env-dead-code | ✅ Complete | v0.76.12/13 |
| B039 | strengthen-s3-scan-spec | ✅ Complete | v0.76.12 |

**Test baseline:** 861 → 860 examples (net -1: one redundant smoke test removed), 0 failures, 86.44% line coverage

---

## What Worked Well

1. **Both work units ran in parallel with zero conflicts.** `bin/dam` and `spec/...` are non-overlapping. Wave 1 parallel pattern continues to be reliable for this type of work.

2. **ENV removal was surgically clean.** All 10 assignments were isolated lines with no downstream reads — each method is 1 line shorter and more readable. Code audit confirmed 0 orphaned variables.

3. **Test grade lifted from B to B+.** Field-value assertions now catch wrong values, not just non-empty. LocalSyncStatus runs for real (via fixture filesystem) and is verified with a method spy. Stronger than before without over-specifying.

4. **Code audit: zero concerns.** 0 rubocop offenses, 0 remaining dead code, library boundaries respected everywhere.

---

## What Didn't Work

1. **B038 agent used `git add .` again** — the fourth campaign in a row with this issue. It staged `s3_scan_command_spec.rb` which had a pre-existing `RSpec/RepeatedExample` offense on CI. Required a second fix commit. The AGENTS.md warning is prominent but agents keep ignoring it.

   **Root cause:** The `kfix` alias may itself be running `git add .` internally, or agents are running `git add .` before `kfix`. Need to investigate whether `kfix` pre-stages, and if so, update AGENTS.md to reflect that.

---

## Key Learnings — Application

1. **`ENV['BRAND_PATH']` is fully gone.** `grep -rn "BRAND_PATH" bin/ lib/ spec/` → 0 results. Any future S3 operations get `brand_path` through proper parameter passing.

2. **`not_to raise_error` is a weak assertion.** It only verifies no exception — it says nothing about correctness. Replace with field-value or method-spy assertions whenever possible.

3. **LocalSyncStatus integration test pattern:** Use `allow(Config).to receive(:project_path).and_return(appydave_path)` + `FileUtils.mkdir_p(staging_dir)` to let LocalSyncStatus run for real without deep mocking.

---

## Key Learnings — Ralph Loop

1. **`git add .` persists across agents despite AGENTS.md warnings.** The warning is not working. Options for next campaign:
   - Investigate whether `kfix` itself stages all files (check its shell implementation)
   - Add explicit `git add <specific-file>` to commit instructions in AGENTS.md rather than relying on agents to remember not to use `git add .`

2. **Small 2-WU parallel campaigns are very efficient.** Planning took ~5 minutes (brief already written), build ran in one wave, audits confirmed clean. This is the right pattern for closing audit findings.

---

## Code Quality Audit Findings

**Grade: APPROVED / Production-ready**
- 0 BRAND_PATH references anywhere in codebase
- All removal sites clean — no orphaned variables
- 0 rubocop offenses in bin/dam
- 860/860 tests pass, 86.44% coverage

---

## Test Quality Audit Findings

**Grade: B+ (improvement from B)**
- Field-value assertions are not tautological — catch mutations to file_count, total_bytes, last_modified
- LocalSyncStatus spy verifies correct arguments passed (not just that it doesn't raise)
- Removed test was genuinely redundant — no coverage loss
- Appropriate layer separation: S3ScanCommand spec tests orchestration; LocalSyncStatus spec tests computation

---

## Suggestions for Next Campaign

1. **Investigate `kfix` staging behaviour** — check whether the alias runs `git add .` or `git add -A` before committing. If so, update AGENTS.md to use `git add <file> && kfix` pattern explicitly.

2. **Next major work:** B020 (split S3Operations, 1,030 lines) — now the cleanest next step. Library boundaries are solid, dead code is gone, test suite is at B+.

3. **B007 (parallelism)** follows B020 — do not attempt before S3Operations is split.
