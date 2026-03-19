# Project Backlog — AppyDave Tools

**Last updated**: 2026-03-19
**Total**: 14 | Pending: 9 | Done: 5 | Deferred: 0 | Rejected: 0

---

## Pending

- [ ] B001 — FR-1: GPT Context token counting | Priority: medium
- [ ] B002 — FR-2: GPT Context AI-friendly help system | Priority: high
- [ ] B006 — BUG-1: Jump CLI get/remove key lookup bug | Priority: high
- [ ] B007 — Performance: parallel git/S3 status checks for dam list | Priority: low
- [ ] B008 — Performance: cache git/S3 status with 5-min TTL | Priority: low
- [ ] B009 — UX: progress indicators for dam operations > 5s | Priority: low
- [ ] B010 — UX: auto-adjust dam table column widths to terminal width | Priority: low
- [ ] B011 — Arch: extract CLI argument parsing from bin/dam (200+ line methods) | Priority: low
- [ ] B012 — Arch: add integration tests for brand resolution end-to-end | Priority: low

---

## Done

- [x] B003 — NFR-1: Improve DAM test coverage | Completed: dam-enhancement-sprint (Jan 2025)
- [x] B004 — FR-3: Jump Location Tool | Completed: 2025-12-13
- [x] B005 — NFR-2: Jump Claude Code Skill | Completed: 2025-12-14
- [x] B013 — Arch: Extract GitHelper module (90 lines duplication) | Completed: dam-enhancement-sprint (Jan 2025)
- [x] B014 — Arch: Create BrandResolver to centralize brand transformation | Completed: dam-enhancement-sprint (Jan 2025)

---

## Item Details

### B001 — FR-1: GPT Context Token Counting

**User Story**: As a developer using GPT Context, I want to see estimated token counts so I can ensure my context fits within LLM limits.

**Acceptance Criteria:**
- [ ] Display estimated token count in output
- [ ] Support common tokenizers (cl100k for GPT-4, claude for Claude)
- [ ] Show warning when exceeding common thresholds (100k, 200k)
- [ ] Optional via `--tokens` flag

**Notes:** Consider tiktoken gem for OpenAI tokenization. May need to estimate for Claude (no official Ruby tokenizer).

---

### B002 — FR-2: GPT Context AI-Friendly Help System

**Spec:** `docs/specs/fr-002-gpt-context-help-system.md`

**User Story**: As an AI agent using GPT Context via skills, I want structured, comprehensive help output so I can understand all options and use the tool correctly.

**Notes:** Full spec exists. High priority — enables AI skill integration.

---

### B006 — BUG-1: Jump CLI get/remove Key Lookup Bug

**Priority:** High — Core functionality broken

**Steps to Reproduce:**
```bash
bin/jump.rb search awb-team   # ✅ finds entry
bin/jump.rb get awb-team      # ❌ "Location not found"
bin/jump.rb remove test-minimal --force  # ❌ "No locations found."
```

**Root Cause Hypothesis:** `get`/`remove` use exact key matching; `search` uses fuzzy/weighted scoring across metadata. The key field being matched may differ.

**Acceptance Criteria:**
- [ ] `get <key>` finds entry when `search <key>` finds it
- [ ] `remove <key>` finds entry when `search <key>` finds it
- [ ] Regression tests for key lookup consistency
- [ ] Root cause documented in commit message

---

### B007 — Performance: Parallel git/S3 Status Checks

**Context:** `dam list appydave` with 13 projects takes ~26s (sequential git+S3 check per project).
**Suggested:** Parallel status checks using Ruby threads or concurrent-ruby.
**Source:** UAT report 2025-01-22 post-release recommendations.

---

### B008 — Performance: Cache git/S3 Status

**Context:** Same sequential bottleneck as B007. Complementary approach.
**Suggested:** Cache git/S3 status per project with 5-minute TTL.
**Source:** UAT report 2025-01-22 post-release recommendations.

---

### B009 — UX: Progress Indicators

**Context:** Operations taking > 5s show no feedback.
**Suggested:** Spinner or "checking project 3/13..." output for long-running dam commands.
**Source:** UAT report 2025-01-22 post-release recommendations.

---

### B010 — UX: Auto-Adjust Table Column Widths

**Context:** Column widths are hardcoded (e.g., KEY column = 15 chars). Terminal resizing or very long names cause misalignment.
**Suggested:** Detect terminal width and/or measure data to set column widths dynamically.
**Source:** UAT report 2025-01-22 post-release recommendations.

---

### B011 — Arch: Extract CLI Argument Parsing from bin/dam

**Context:** `bin/dam` has multiple 200+ line methods (help commands, argument parsers). Hard to test.
**Suggested:** Extract parsers to dedicated classes following CLI patterns guide.
**Source:** Code quality report 2025-01-21, Low Priority section.

---

### B012 — Arch: Integration Tests for Brand Resolution

**Context:** BrandResolver, Config, ProjectResolver interact across layers. Unit tests cover each individually but no end-to-end test catches cross-layer bugs.
**Suggested:** Integration specs that test brand → project resolution across the full call chain.
**Source:** Code quality report 2025-01-21, Low Priority section.
