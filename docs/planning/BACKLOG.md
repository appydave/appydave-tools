# Project Backlog — AppyDave Tools

**Last updated**: 2026-03-20 (B007 complete)
**Total**: 41 | Pending: 2 | Done: 38 | Deferred: 0 | Rejected: 0

---

## Pending

### Medium Priority
- [ ] B008 — Performance: cache git/S3 status with 5-min TTL | Priority: low
- [ ] B040 — Fix: ProjectResolver.resolve raises RuntimeError not typed exception (found in B012) | Priority: low

---

## Done

- [x] B003 — NFR-1: Improve DAM test coverage | Completed: dam-enhancement-sprint (Jan 2025)
- [x] B004 — FR-3: Jump Location Tool | Completed: 2025-12-13
- [x] B005 — NFR-2: Jump Claude Code Skill | Completed: 2025-12-14
- [x] B013 — Arch: Extract GitHelper module (90 lines duplication) | Completed: dam-enhancement-sprint (Jan 2025)
- [x] B014 — Arch: Create BrandResolver to centralize brand transformation | Completed: dam-enhancement-sprint (Jan 2025)
- [x] B002 — FR-2: GPT Context AI-friendly help system | Completed: fr2-gpt-context-help (2026-03-19)
- [x] B016 — BUG-3: ManifestGenerator + SyncFromSsd incompatible SSD range strings | Completed: bugfix-and-security (2026-03-19)
- [x] B017 — Security: ssl_verify_peer disabled unconditionally in S3Operations + ShareOperations + S3Scanner | Completed: bugfix-and-security (2026-03-19)
- [x] B021 — Fix: gpt_context no-args guard had dead format.nil? condition | Completed: bugfix-and-security (2026-03-19)
- [x] B024 — Tests: configure_ssl_options unit tests (protects B017 fix) | Completed: test-coverage-gaps (2026-03-19)
- [x] B022 — Tests: functional cli_spec tests for -i -e -f -o flags | Completed: test-coverage-gaps (2026-03-19)
- [x] B026 — Tests: determine_range edge cases (b00, b9, a40) | Completed: test-coverage-gaps (2026-03-19)
- [x] B027 — Tests: gpt_context no-args spec verifies collection stops | Completed: test-coverage-gaps (2026-03-19)
- [x] B025 — Fix: stale comment sync_from_ssd.rb:173 | Completed: test-coverage-gaps (2026-03-19)
- [x] B018 — Tests: Jump Commands::Remove, Add, Update specs | Completed: test-coverage-gaps (2026-03-19)
- [x] B015 — BUG-2: FileCollector FileUtils.cd without ensure | Completed: already fixed in commit 13d5f87; closed without campaign 2026-03-19
- [x] B019 — Fix: remove debug puts @working_directory from file_collector.rb | Completed: already removed prior to test-coverage-gaps campaign; closed without campaign 2026-03-19
- [x] B006 — BUG-1: Jump CLI get/remove key lookup | Completed: verified fixed 2026-03-19, regression spec added
- [x] B023 — Tests: file_collector_spec json/aider/error path coverage | Completed: final-test-gaps (2026-03-19)
- [x] B028 — Tests: cli_spec file body content assertions in -i/-e tests | Completed: final-test-gaps (2026-03-19)
- [x] B029 — Tests: add_spec validate all returned location data fields | Completed: final-test-gaps (2026-03-19)
- [x] B030 — Tests: update_spec verify non-updated fields unchanged | Completed: final-test-gaps (2026-03-19)
- [x] B031 — Tests: add_spec `type` field assertion | Completed: already in commit 8eec40c; closed micro-cleanup (2026-03-19)
- [x] B032 — Tests: cli_spec `-f json` subprocess test | Completed: micro-cleanup (2026-03-19), v0.76.4
- [x] B033 — Fix: file_collector.rb return `''` when working_directory missing | Completed: already in commit 13d5f87; closed micro-cleanup (2026-03-19)
- [x] B011 — Arch: extract VatCLI business logic from bin/dam (1,600-line God class) | Completed: extract-vat-cli (2026-03-19)
- [x] B034 — Fix: replace exit 1 with typed exceptions in S3ScanCommand + S3ArgParser; add UsageError | Completed: library-boundary-cleanup (2026-03-19), v0.76.8
- [x] B035 — Fix: remove ENV['BRAND_PATH'] side effect from S3ArgParser; return brand_path: in result hash | Completed: library-boundary-cleanup (2026-03-19), v0.76.9
- [x] B036 — Tests: rebuild S3ScanCommand spec from D to B (10 behaviour examples) | Completed: library-boundary-cleanup (2026-03-19), v0.76.10
- [x] B037 — Tests: LocalSyncStatus :partial, local_file_count, Zone.Identifier exclusion, unknown format | Completed: library-boundary-cleanup (2026-03-19), v0.76.11
- [x] B038 — Cleanup: remove ENV['BRAND_PATH'] dead code from bin/dam (10 assignments) | Completed: env-dead-code-cleanup (2026-03-20), v0.76.13
- [x] B039 — Tests: strengthen s3_scan_command_spec field assertions + remove LocalSyncStatus stub | Completed: env-dead-code-cleanup (2026-03-20), v0.76.12
- [x] B012 — Arch: brand resolution integration tests (BrandResolver→Config→ProjectResolver chain) | Completed: batch-a-features (2026-03-20), v0.76.14
- [x] B001 — FR-1: GPT Context token counting (--tokens flag, warn to stderr, 100k/200k thresholds) | Completed: batch-a-features (2026-03-20), v0.77.0
- [x] B010 — UX: terminal-width-aware separator lines + truncate_path in project_listing | Completed: batch-a-features (2026-03-20), v0.77.0
- [x] B009 — UX: progress indicators for dam S3 operations (upload, download, status, archive, sync-ssd) | Completed: batch-a-features (2026-03-20), v0.77.1
- [x] B020 — Arch: split S3Operations into S3Base + S3Uploader + S3Downloader + S3StatusChecker + S3Archiver; S3Operations thin facade | Completed: s3-operations-split (2026-03-20), v0.77.6
- [x] B007 — Performance: parallel git/S3 status checks for dam list (Thread.new per project + per check) | Completed: 2026-03-20, v0.77.7

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

### B020 — Arch: Split S3Operations (1,030 lines)

**Context:** `S3Operations` handles upload, download, status, cleanup, archive to SSD, MD5 comparison, content type detection, file formatting, and time formatting — all in one class with direct `puts` throughout. No result objects returned from upload/download/cleanup (void methods with side effects).
**Suggested:** Split into at minimum `S3Uploader`, `S3Downloader`, `S3StatusChecker`, `S3Archiver` with I/O separated from computation. Required before B007 (parallelism) can be built.
**Source:** Architectural review 2026-03-19, Critical concern #2.
