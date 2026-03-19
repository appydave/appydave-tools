# Project Backlog — AppyDave Tools

**Last updated**: 2026-03-19 (updated after three-lens audit)
**Total**: 20 | Pending: 14 | Done: 6 | Deferred: 0 | Rejected: 0

---

## Pending

### High Priority
- [ ] B015 — BUG-2: FileCollector uses FileUtils.cd without ensure (process dir not restored on exception) | Priority: high
- [ ] B016 — BUG-3: ManifestGenerator + SyncFromSsd produce incompatible SSD range strings (data integrity) | Priority: high
- [ ] B002 — FR-2: GPT Context AI-friendly help system | Priority: high
- [x] B006 — BUG-1: Jump CLI get/remove key lookup | Completed: verified fixed 2026-03-19, regression spec added
- [ ] B017 — Security: ssl_verify_peer disabled unconditionally in S3Operations + ShareOperations | Priority: high

### Medium Priority
- [ ] B018 — Tests: add specs for Jump Commands::Remove, Commands::Add, Commands::Update | Priority: medium
- [ ] B019 — Fix: remove debug puts @working_directory from gpt_context/file_collector.rb | Priority: medium
- [ ] B001 — FR-1: GPT Context token counting | Priority: medium
- [ ] B012 — Arch: add integration tests for brand resolution end-to-end | Priority: medium

### Low Priority
- [ ] B007 — Performance: parallel git/S3 status checks for dam list | Priority: low
- [ ] B008 — Performance: cache git/S3 status with 5-min TTL | Priority: low
- [ ] B009 — UX: progress indicators for dam operations > 5s | Priority: low
- [ ] B010 — UX: auto-adjust dam table column widths to terminal width | Priority: low
- [ ] B011 — Arch: extract VatCLI business logic from bin/dam (1,600-line God class) | Priority: low
- [ ] B020 — Arch: split S3Operations (1,030 lines, mixed I/O + logic) | Priority: low

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

**Priority:** High — but verify live first

**⚠️ Three-lens audit (2026-03-19) found:** Static analysis of `Jump::Config#find`, `Config#remove`, and `Search#get` shows correct dual-key guards. Bug may be environmental (stale config file format) or already fixed in a prior commit. **Run `bin/jump.rb get <key>` live before writing any code.**

**Steps to Reproduce:**
```bash
bin/jump.rb search awb-team   # ✅ finds entry
bin/jump.rb get awb-team      # ❌ "Location not found"  ← confirm this still fails
bin/jump.rb remove test-minimal --force  # ❌ "No locations found."
```

**If bug confirmed:** Failure site is in `Jump::Config#find` (`loc.key == key`) or the memoization of `@locations` — NOT in `name_manager/`. The `Commands::Remove#run` → `config.find(key)` → `locations.find { |loc| loc.key == key }` path is the call chain to trace.

**Acceptance Criteria:**
- [ ] Confirm bug still exists live (if not, write regression spec and close)
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

### B011 — Arch: Extract VatCLI Business Logic from bin/dam

**Context:** `bin/dam` is 1,600 lines. Methods `scan_single_brand_s3`, `add_local_sync_status!`, `display_s3_scan_table`, `parse_s3_args`, `format_bytes` are business/display logic that belongs in library classes. 20+ rubocop-disable comments are symptoms.
**Suggested:** Extract to library classes before adding DAM parallelism (B007/B008) — those features cannot be built cleanly in VatCLI.
**Source:** Architectural review 2026-03-19, Critical concern #1.

---

### B012 — Arch: Integration Tests for Brand Resolution

**Context:** BrandResolver, Config, ProjectResolver interact across layers. Unit tests cover each individually but no end-to-end test catches cross-layer bugs.
**Suggested:** Integration specs that test brand → project resolution across the full call chain.
**Source:** Code quality report 2025-01-21 + architectural review 2026-03-19.

---

### B015 — BUG-2: FileCollector FileUtils.cd Without ensure

**Context:** `lib/appydave/tools/gpt_context/file_collector.rb` line 20 calls `FileUtils.cd(@working_directory)`. If an exception fires inside `build`, the process working directory is never restored to `Dir.home`. Affects any subsequent operation in the same process.
**Fix:** Wrap in block form: `FileUtils.cd(@working_directory) { ... }` — Ruby handles restore automatically. Or add `ensure FileUtils.cd(Dir.home)`.
**Blocker for:** FR-2 — fix this before adding more code paths to `file_collector.rb`.
**Source:** Code quality audit 2026-03-19, MAJOR issue #2.

---

### B016 — BUG-3: ManifestGenerator vs SyncFromSsd Incompatible Range Strings

**Context:** `ManifestGenerator.determine_range('b65')` returns `"b50-b99"`. `SyncFromSsd.determine_range('b65')` returns `"60-69"`. Both are used to construct SSD archive folder paths. Projects archived via SSD sync won't be found by the manifest generator, and vice versa. A `find_ssd_project_path` fallback scan may paper over this in practice.
**Fix:** Standardise both methods on one format. Decide which format matches actual SSD folder structure on disk, then update the other method to match.
**Source:** Code quality audit 2026-03-19, MAJOR issue #1.

---

### B017 — Security: ssl_verify_peer Disabled in S3Operations + ShareOperations

**Context:** `lib/appydave/tools/dam/s3_operations.rb` lines 110-113 and `share_operations.rb` lines 97-100 set `ssl_verify_peer: false` unconditionally. Comment claims "safe for AWS S3" — this is incorrect. Disabling peer verification removes MITM protection on all S3 operations including AWS credential transmission.
**Fix:** Remove the `ssl_verify_peer: false` override entirely. AWS SDK handles SSL correctly by default. If there was a historical reason (corporate proxy, dev cert issue), document it and scope to `ENV['AWS_SKIP_SSL'] == 'true'` only.
**Source:** Code quality audit 2026-03-19, MAJOR issue #3.

---

### B018 — Tests: Jump Commands Layer Has No Dedicated Specs

**Context:** `Commands::Remove`, `Commands::Add`, `Commands::Update` have zero unit specs. The CLI spec only tests auto-regenerate side effects. `--force` guard, error codes, suggestion-on-not-found logic, and key nil-handling in these commands are entirely untested.
**Fix:** Add `spec/appydave/tools/jump/commands/remove_spec.rb`, `add_spec.rb`, `update_spec.rb`. Use `JumpTestLocations` factory + `with jump filesystem` context.
**Source:** Test quality audit 2026-03-19, RISK-1.

---

### B019 — Fix: Remove Debug puts From file_collector.rb

**Context:** `lib/appydave/tools/gpt_context/file_collector.rb` line 15: `puts @working_directory`. Prints working directory on every `gpt_context` invocation. Pollutes captured output. Must be removed before FR-2 adds help system output.
**Fix:** Delete line 15.
**Source:** Code quality audit 2026-03-19, MINOR issue #4.

---

### B020 — Arch: Split S3Operations (1,030 lines)

**Context:** `S3Operations` handles upload, download, status, cleanup, archive to SSD, MD5 comparison, content type detection, file formatting, and time formatting — all in one class with direct `puts` throughout. No result objects returned from upload/download/cleanup (void methods with side effects).
**Suggested:** Split into at minimum `S3Uploader`, `S3Downloader`, `S3StatusChecker`, `S3Archiver` with I/O separated from computation. Required before B007 (parallelism) can be built.
**Source:** Architectural review 2026-03-19, Critical concern #2.
