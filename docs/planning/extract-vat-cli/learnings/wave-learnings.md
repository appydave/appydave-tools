# Wave Learnings — extract-vat-cli

**Campaign:** extract-vat-cli
**Date:** 2026-03-19
**Result:** 4/4 complete. 831 → 847 examples (+16). v0.76.3 → v0.76.7.

---

## Application Learnings

### 1. format_bytes had 4 callers, not 3
The orphaned-projects loop in `display_s3_scan_table` had its own `format_bytes` call. Plan said 3 callers; there were 4. Always grep for callers before writing the plan rather than counting from memory.

### 2. rubocop-disable directives become redundant when methods leave God class
WU3 and WU4 both needed a second `kfix` to remove `rubocop:disable Metrics/MethodLength` and `Metrics/CyclomaticComplexity` directives that were valid in the 1,600-line VatCLI context but flagged as redundant by CI rubocop 1.85.1 once the methods were in properly-scoped library classes.

**Rule for future extractions:** Do NOT carry over rubocop-disable comments. Run rubocop locally on the new file first — only add disables if rubocop actually flags an offense.

### 3. valid_brand? needed Config.brands mock, not just SettingsConfig mock
The shared context `'with vat filesystem and brands'` only mocks `SettingsConfig#video_projects_root`. Testing `valid_brand?` (which calls `Config.brands`) required an explicit `Config.configure` + `Config.brands` mock with a test `BrandsConfig` instance. Document this in AGENTS.md for future S3ArgParser specs.

### 4. youtube_automation_config require was missing (pre-existing)
WU2 agent discovered that a prior `chore(cleanup)` commit had incorrectly removed `require 'appydave/tools/youtube_automation_config'` from `lib/appydave/tools.rb`. The CI was failing on a `NameError` for `YoutubeAutomationConfig` unrelated to our work. Agent restored it as a side-fix. This was confirmed pre-existing in WU1's CI output.

---

## Loop Meta-Learnings

### Wave size = 1 was correct
All 4 work units touched `bin/dam`. Sequential was the only safe option. No conflicts, no merge issues.

### Agents produced clean rubocop output when not inheriting disables
WU1 (no rubocop disables to inherit) was cleanest. WU2 produced clean output first-pass. WU3 and WU4 needed a second pass due to inherited directives — preventable with the "don't carry over disables" rule above.

### 4 agents, all successful, no failures
Every work unit completed in a single run (plus occasional second kfix for rubocop cleanup). AGENTS.md quality was sufficient — agents didn't get confused about which methods to move or which callers to update.
