# Next Round Brief

**Created:** 2026-03-19
**Auto-detected by:** Ralphy (pre-extend prep)

---

## Suggested Next Campaign: Jump Tool Fixes + GPT Context Enhancements

### Goal

Fix the critical Jump CLI bug (BUG-1) and implement the GPT Context help system spec (FR-2) — two independent work units that can run in parallel.

### Background

**Jump bug (B006 — High Priority):** `jump get` and `jump remove` fail to find locations by key while `jump search` succeeds for the same entries. Core functionality is broken for key-based lookup. The jump tool recently had `--limit` and `--skip-unassigned` flags added to report commands, so the codebase is active.

**GPT Context help (B002 — High Priority):** A full spec already exists at `docs/specs/fr-002-gpt-context-help-system.md`. No planning needed — just implementation. This enables AI skill integration with GPT Context.

### Suggested Work Units

1. **Fix jump get/remove key lookup** — investigate `lib/appydave/tools/name_manager/` for lookup logic discrepancy between search (fuzzy/weighted) and get/remove (exact match). Add regression tests. (BUG-1)

2. **Implement GPT Context AI help system** — read `docs/specs/fr-002-gpt-context-help-system.md` first. Implement structured `--help` output for AI agents. (FR-2)

3. **GPT Context token counting** — smaller scope follow-on if time allows. (FR-1)

### What Agents Need to Know

- Read `docs/planning/AGENTS.md` — test/lint patterns, commit format, quality gates
- Jump tool tests use `spec/support/jump_test_helpers.rb`
- GPT Context lives in `lib/appydave/tools/gpt_context/`
- Spec for FR-2 is at `docs/specs/fr-002-gpt-context-help-system.md`

### Mode Recommendation

**Extend** — both work areas are distinct from DAM, but the Ruby stack, test patterns, and quality gates are all known from prior campaigns. Use Extend, not Plan.
