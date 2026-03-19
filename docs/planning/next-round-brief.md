# Next Round Brief

**Created:** 2026-03-19
**Updated:** 2026-03-19 (after micro-cleanup assessment)

---

## Recommended Next Campaign: extract-vat-cli (B011)

### Goal

Extract business logic from `bin/dam` (1,600-line God class) into proper library classes. Prerequisite for parallelism (B007) and caching (B008).

### Background

Suite is at B grade (831 examples, ~80% catch rate). All test debt cleared. Ready for architectural work.

`bin/dam` flagged as Critical Concern #1 in architectural review (2026-03-19):
- 1,600 lines in a single CLI entry point
- 20+ `rubocop-disable` comments
- Methods like `scan_single_brand_s3`, `add_local_sync_status!`, `display_s3_scan_table`, `parse_s3_args`, `format_bytes` belong in library classes
- Cannot cleanly add parallelism (B007/B008) without extracting first

### Pre-Campaign Checklist (MANDATORY)

- [ ] Run `git status` — confirm working tree is CLEAN before starting (micro-cleanup surfaced dirty-working-tree risk)
- [ ] Run `RUBYOPT="-W0" bundle exec rspec` — confirm 831 examples, 0 failures
- [ ] Run `bundle exec rubocop bin/dam --format clang` — count current offense count
- [ ] Read `bin/dam` in full before writing AGENTS.md — 1,600 lines, surprises expected

### AGENTS.md Must Include

> **Pre-commit check (mandatory):** Before running `kfix`, run `git status` and confirm only the expected files are staged. If unexpected files appear, run `git diff` to investigate before committing. Never commit files you didn't intentionally change.

### Mode Recommendation

**4. Extend** — same stack, inherited AGENTS.md. Add the pre-commit git status check to every agent's instructions.

### Risk Notes

- Extract one class per agent — no overlapping files
- Each extracted class needs at least one smoke-test spec alongside it
- Do NOT attempt B020 (split S3Operations) in the same campaign
- `bin/dam` is the primary DAM CLI entry point — regressions affect real workflows
