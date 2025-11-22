# Behavioral Regression Audit

## Objective

Verify that code at commit `4228b51` (current HEAD) behaves identically to commit `9e49668` (baseline) except for intentional UX improvements.

## Context

This is a Ruby gem project (`appydave-tools`) providing CLI tools for video asset management. Between commits `9e49668` and `4228b51`, **75 commits of AI-driven UX improvements** were made without human verification between commits.

**The Problem:**
- Baseline `9e49668`: Code definitely worked (all DAM functions operational)
- Current `4228b51`: Code state unknown after 75 AI-generated commits
- Changes focused on: Help text, error messages, table formatting, validation, new flags
- Risk: Did AI inadvertently break core functionality while "improving" UX?

**What We Need to Prove:**
1. Old functionality preserved (everything that worked still works)
2. New UX additions are safe (only cosmetic/minor functional improvements)
3. No silent bugs introduced (no logic errors from AI refactoring)

## Commit Range

- **Baseline (known working):** `9e49668`
- **Current (unknown state):** `4228b51`
- **Commits between:** 75 commits
- **Analysis method:** Two-snapshot comparison (NOT 75 individual commit reviews)

## What Changed (Expected)

**Acceptable changes:**
- Help text wording improvements
- Table column names and formatting
- Error message phrasing
- Validation message improvements
- New command-line flags (e.g., `--detailed`)
- Debug output enhancements

**Unacceptable changes:**
- Different projects listed by `dam list`
- Different file counts or sizes reported
- Changed brand resolution logic (shortcuts, case-sensitivity)
- Changed S3 sync behavior
- Changed git status detection
- Breaking changes to command syntax

## Known High-Risk Areas

**From code quality report (2025-01-21):**
- **Brand resolution:** v- prefix handling, case-insensitive matching, shortcuts (ad, voz, joy, ss)
- **Regexp.last_match bug:** Fixed in commit 9e49668 (capture groups reset by `.sub()` calls)
- **Configuration loading:** 7x config load calls issue (commit 94d3ea0)
- **Git operations:** Duplicated helper methods across files
- **S3 operations:** Sync status detection, upload/download logic

## Prerequisites

Before starting this audit:
- [ ] Working directory: `/Users/davidcruwys/dev/ad/appydave-tools`
- [ ] Current branch: `main` at commit `4228b51`
- [ ] Baseline commit exists: Run `git show 9e49668` to verify
- [ ] DAM command available: `which dam` or use `bin/dam`
- [ ] Test environment has real project data (v-appydave, v-voz, etc.)

## 5-Phase Audit Process

### Phase 1: Change Inventory (Understand What Changed)

**Goal:** Identify all changed files and classify changes as UX vs Logic vs Refactor

**Commands to run:**
```bash
# Get list of all changed files with status
git diff 9e49668..4228b51 --name-status > /tmp/changed-files.txt

# Get statistics on changes
git diff 9e49668..4228b51 --stat

# Get detailed diff for lib/ directory
git diff 9e49668..4228b51 lib/ > /tmp/lib-changes.diff

# Get detailed diff for bin/ directory
git diff 9e49668..4228b51 bin/ > /tmp/bin-changes.diff

# Get detailed diff for spec/ directory
git diff 9e49668..4228b51 spec/ > /tmp/spec-changes.diff
```

**Analysis tasks:**
1. List all changed files (group by directory: lib/, bin/, spec/, docs/)
2. For each file, classify the change:
   - **UX-only:** Help text, error messages, table formatting, column names
   - **Logic change:** Conditionals, calculations, flow control, regex patterns
   - **Refactor:** Method extraction/renaming, file reorganization (same logic, different structure)
   - **New feature:** Entirely new functionality (e.g., --detailed flag)
   - **Bug fix:** Fixing broken behavior
   - **Test change:** Spec updates

**Output for Phase 1:**
```markdown
### Phase 1: Change Inventory

**Files changed:** X files across Y directories

#### Changed Files by Category

**UX-only changes (N files):**
- `file1.rb` - Updated help text and error messages
- `file2.rb` - Table formatting improvements

**Logic changes (N files):**
- `file3.rb` - Modified brand resolution conditional (LINE X-Y)
- `file4.rb` - Changed regex pattern (LINE Z)

**Refactored (N files):**
- `file5.rb` - Extracted method, same logic

**New features (N files):**
- `file6.rb` - Added --detailed flag support

**Test changes (N files):**
- `file7_spec.rb` - Updated specs for new behavior
```

---

### Phase 2: Critical Path Analysis (What Must Work?)

**Goal:** Identify core DAM operations that absolutely cannot break

**Critical operations to verify:**
1. **Brand listing:**
   - `dam list` (all brands)
   - `dam list --detailed` (extended view)
   - Invalid brand error handling

2. **Project listing:**
   - `dam list <brand>` (specific brand)
   - `dam list <brand> <pattern>` (pattern matching like 'b6*')
   - `dam list <brand> --detailed` (extended project view)

3. **S3 operations:**
   - `dam s3-status <brand> <project>` (sync status check)
   - `dam s3-up <brand> <project>` (upload preparation)
   - `dam s3-down <brand> <project>` (download preparation)
   - `dam s3-cleanup <brand> <project>` (cleanup)

4. **Git operations:**
   - `dam status <brand>` (git repository status)
   - Git status column in brand list
   - Git status column in project list

5. **Brand/project resolution:**
   - Shortcuts (ad → appydave, voz → voz, joy → beauty-and-joy, ss → supportsignal)
   - Case-insensitive matching (appydave, APPYDAVE, AppyDave all work)
   - Fuzzy matching with "Did you mean?" suggestions
   - Auto-detection from PWD

6. **Archive operations:**
   - `dam archive <brand> <project>` (archive to SSD)
   - `dam sync-ssd <brand>` (sync from SSD)

**Output for Phase 2:**
```markdown
### Phase 2: Critical Path Analysis

**Core operations identified:** X operations across Y command categories

**File dependencies per operation:**
- `dam list` → Uses: `lib/file1.rb`, `lib/file2.rb`, etc.
- `dam s3-status` → Uses: `lib/file3.rb`, `lib/file4.rb`, etc.
```

---

### Phase 3: Behavioral Comparison Testing

**Goal:** Run identical commands on both versions and compare outputs

**⚠️ IMPORTANT:** This phase requires checking out different commits. Save any uncommitted work first.

**Method:**

```bash
# Step 1: Create output directory
mkdir -p /tmp/behavioral-audit

# Step 2: Checkout baseline and capture outputs
git checkout 9e49668

# Run core commands and save outputs
dam list > /tmp/behavioral-audit/baseline-dam-list.txt 2>&1
dam list appydave > /tmp/behavioral-audit/baseline-appydave-list.txt 2>&1
dam list voz > /tmp/behavioral-audit/baseline-voz-list.txt 2>&1
dam s3-status appydave b65 > /tmp/behavioral-audit/baseline-s3-status.txt 2>&1 || true
dam status appydave > /tmp/behavioral-audit/baseline-git-status.txt 2>&1 || true

# Test error handling
dam list invalidbrand > /tmp/behavioral-audit/baseline-error-invalid.txt 2>&1 || true
dam list appydav > /tmp/behavioral-audit/baseline-fuzzy-match.txt 2>&1 || true

# Test shortcuts
dam list ad > /tmp/behavioral-audit/baseline-shortcut-ad.txt 2>&1
dam list joy > /tmp/behavioral-audit/baseline-shortcut-joy.txt 2>&1

# Step 3: Checkout current and capture outputs
git checkout 4228b51

dam list > /tmp/behavioral-audit/current-dam-list.txt 2>&1
dam list appydave > /tmp/behavioral-audit/current-appydave-list.txt 2>&1
dam list voz > /tmp/behavioral-audit/current-voz-list.txt 2>&1
dam s3-status appydave b65 > /tmp/behavioral-audit/current-s3-status.txt 2>&1 || true
dam status appydave > /tmp/behavioral-audit/current-git-status.txt 2>&1 || true

dam list invalidbrand > /tmp/behavioral-audit/current-error-invalid.txt 2>&1 || true
dam list appydav > /tmp/behavioral-audit/current-fuzzy-match.txt 2>&1 || true

dam list ad > /tmp/behavioral-audit/current-shortcut-ad.txt 2>&1
dam list joy > /tmp/behavioral-audit/current-shortcut-joy.txt 2>&1

# Step 4: Compare outputs
cd /tmp/behavioral-audit
for file in baseline-*.txt; do
  current_file="${file/baseline-/current-}"
  echo "=== Comparing $file vs $current_file ==="
  diff "$file" "$current_file" || echo "DIFFERENCES FOUND"
done
```

**Analysis tasks:**
1. For each command pair, identify differences
2. Classify differences as:
   - **Formatting only:** Column widths, table borders, spacing (ACCEPTABLE)
   - **Wording only:** Help text, error messages (ACCEPTABLE)
   - **Data difference:** Different projects listed, different counts, different statuses (UNACCEPTABLE)
   - **Functional difference:** Command failed in one version but not the other (UNACCEPTABLE)

**Output for Phase 3:**
```markdown
### Phase 3: Behavioral Comparison Testing

**Commands tested:** X commands on both versions

**Results:**

| Command | Baseline Output | Current Output | Difference Type | Acceptable? |
|---------|----------------|----------------|-----------------|-------------|
| `dam list` | 6 brands listed | 6 brands listed | Table formatting | ✅ Yes |
| `dam list appydave` | 21 projects | 21 projects | Column names changed | ✅ Yes |
| `dam s3-status appydave b65` | Status shown | Status shown | Same data | ✅ Yes |
| `dam list invalidbrand` | Error shown | Error shown | Error message wording | ✅ Yes |

**Critical differences found:** N

**Details of critical differences:**
[List any UNACCEPTABLE differences here]
```

---

### Phase 4: Logic Diff Analysis

**Goal:** Find places where code logic changed (not just formatting/structure)

**Method:**

Use grep and diff to find semantic changes in critical areas:

```bash
# Checkout current version
git checkout 4228b51

# Search for brand resolution logic changes
git diff 9e49668..4228b51 -- lib/ | grep -A5 -B5 "brand.*==" > /tmp/brand-resolution-changes.txt
git diff 9e49668..4228b51 -- lib/ | grep -A5 -B5 "v-prefix\|v-appydave" > /tmp/v-prefix-changes.txt

# Search for regex pattern changes
git diff 9e49668..4228b51 -- lib/ | grep -A5 -B5 "Regexp\|\.match\|\.scan" > /tmp/regex-changes.txt

# Search for conditional logic changes
git diff 9e49668..4228b51 -- lib/ | grep -A3 -B3 "^[+-].*if \|^[+-].*elsif \|^[+-].*case " > /tmp/conditional-changes.txt

# Search for file path construction changes
git diff 9e49668..4228b51 -- lib/ | grep -A3 -B3 "File.join\|File.expand_path\|\.sub\|\.gsub" > /tmp/path-changes.txt

# Search for configuration loading changes
git diff 9e49668..4228b51 -- lib/ | grep -A5 -B5 "config\|settings\|load" > /tmp/config-changes.txt
```

**Red flags to look for:**
- Changed regex capture groups (could break parsing)
- Changed file path construction (could break file access)
- Changed brand resolution conditionals (could break shortcuts)
- Changed configuration loading order (could break initialization)
- Changed error handling (raise → return, or vice versa)

**Analysis tasks:**
1. Review each type of change
2. Identify which files had logic changes vs refactoring
3. For logic changes, assess risk level (High/Medium/Low)

**Output for Phase 4:**
```markdown
### Phase 4: Logic Diff Analysis

**Logic changes detected:** X changes in Y files

#### High-Risk Logic Changes

**File:** `lib/appydave/tools/dam/brand_resolver.rb`
- **Line:** 45-52
- **Change:** Modified brand shortcut resolution conditional
- **Risk:** High - Could break 'ad', 'voz', 'joy', 'ss' shortcuts
- **Verification needed:** Test all shortcuts on both versions

#### Medium-Risk Logic Changes

**File:** `lib/appydave/tools/dam/project_detector.rb`
- **Line:** 78-85
- **Change:** Changed regex pattern for project detection
- **Risk:** Medium - Could affect pattern matching
- **Verification needed:** Test 'b6*' pattern expansion

#### Low-Risk Logic Changes

**File:** `lib/appydave/tools/dam/table_formatter.rb`
- **Line:** 120-135
- **Change:** Refactored column width calculation
- **Risk:** Low - Formatting only, same logic
```

---

### Phase 5: High-Risk Spot Check

**Goal:** Manually review critical files where logic changed

**Files to review (from Phase 4 high/medium risk):**
1. Brand resolution files
2. Project detection files
3. S3 operation files
4. Git status files
5. Configuration loading files

**For each file:**

```bash
# View the file at baseline
git show 9e49668:lib/path/to/file.rb > /tmp/baseline-file.rb

# View the file at current
git show 4228b51:lib/path/to/file.rb > /tmp/current-file.rb

# Side-by-side diff
diff -y /tmp/baseline-file.rb /tmp/current-file.rb | less
```

**Analysis questions:**
1. Are inputs and outputs the same?
2. Are edge cases handled identically?
3. Are error conditions handled identically?
4. Did refactoring preserve the original logic?
5. Are there new bugs introduced?

**Specific checks for known issues:**

**Brand Resolution:**
- [ ] Shortcuts still map correctly (ad → appydave, voz → voz, etc.)
- [ ] Case-insensitive matching preserved
- [ ] v- prefix handling unchanged
- [ ] Fuzzy matching working

**Regexp.last_match (known bug area):**
- [ ] Capture groups extracted BEFORE any `.sub()` or `.gsub()` calls
- [ ] No regex results lost due to subsequent string operations

**Configuration Loading:**
- [ ] Config loaded once per command (not 7x)
- [ ] Config paths resolved correctly
- [ ] No hard-coded paths introduced

**S3 Operations:**
- [ ] MD5 comparison logic unchanged
- [ ] Upload/download decision logic unchanged
- [ ] 3-state model (upload/download/synced) working

**Git Operations:**
- [ ] Status detection unchanged
- [ ] Branch detection unchanged
- [ ] Modified files detection unchanged

**Output for Phase 5:**
```markdown
### Phase 5: High-Risk Spot Check

**Files manually reviewed:** X files

#### File: `lib/appydave/tools/dam/brand_resolver.rb`

**Changes found:**
- Line 45: Added downcase normalization
- Line 52: Refactored shortcut hash lookup

**Verification:**
- ✅ Shortcuts still work (tested ad, voz, joy, ss)
- ✅ Case-insensitive matching preserved
- ✅ v- prefix handling unchanged
- ⚠️ New fuzzy matching added (acceptable - UX improvement)

**Verdict:** SAFE - Logic preserved, UX enhanced

#### File: `lib/appydave/tools/dam/project_detector.rb`

**Changes found:**
- Line 78: Changed regex pattern from `/pattern1/` to `/pattern2/`

**Verification:**
- ❌ Regexp.last_match captured AFTER .sub() call (BUG!)
- ❌ Pattern matching broken for 'b6*' expansion

**Verdict:** UNSAFE - Regression introduced, needs fix

[Continue for each high-risk file...]
```

---

## Report Format

Create the audit report at: `docs/code-quality/behavioral-audit-2025-01-22.md`

Use this template:

```markdown
# Behavioral Regression Audit Report

**Date:** 2025-01-22
**Baseline Commit:** `9e49668` (known working)
**Current Commit:** `4228b51` (HEAD)
**Commits Analyzed:** 75 commits (two-snapshot comparison)
**Auditor:** Claude Code (AI Assistant)

---

## Executive Summary

**Overall Verdict:** [SAFE / NEEDS FIXES / UNSAFE]

**Summary:**
- Files changed: X files
- Logic changes: Y files
- Critical issues found: Z issues
- UX improvements validated: N improvements

**Recommendation:** [Proceed to UAT / Fix regressions first / Rollback required]

---

## Phase 1: Change Inventory

[Insert Phase 1 output here]

---

## Phase 2: Critical Path Analysis

[Insert Phase 2 output here]

---

## Phase 3: Behavioral Comparison Testing

[Insert Phase 3 output here]

---

## Phase 4: Logic Diff Analysis

[Insert Phase 4 output here]

---

## Phase 5: High-Risk Spot Check

[Insert Phase 5 output here]

---

## Critical Issues Found 🔴

### Issue 1: [Title]
- **File:** `lib/path/to/file.rb`
- **Lines:** X-Y
- **Problem:** [Description]
- **Impact:** [What breaks]
- **Evidence:** [Behavioral test result or code snippet]
- **Fix Required:** [What needs to change]
- **Priority:** Critical

### Issue 2: [Title]
[Same format...]

---

## Moderate Issues Found 🟡

[Similar format for medium-priority issues]

---

## Acceptable Changes Validated ✅

### UX Improvements Confirmed Safe:
- Help text improvements in X files
- Table formatting enhancements
- Error message improvements
- New --detailed flag functionality

### Refactorings Confirmed Safe:
- Method extractions in Y files
- Code organization improvements
- No logic changes detected

---

## Test Results Summary

**Behavioral tests run:** X commands tested

| Test Category | Tests Run | Passed | Failed |
|---------------|-----------|--------|--------|
| Brand listing | 5 | 5 | 0 |
| Project listing | 8 | 7 | 1 |
| S3 operations | 4 | 4 | 0 |
| Git operations | 3 | 3 | 0 |
| Error handling | 4 | 4 | 0 |
| **Total** | **24** | **23** | **1** |

---

## Action Items

### High Priority (Must Fix Before UAT)
1. [ ] Fix [Issue 1] in `file.rb:X`
2. [ ] Fix [Issue 2] in `file.rb:Y`

### Medium Priority (Should Fix)
1. [ ] Address [Issue 3]
2. [ ] Review [Issue 4]

### Low Priority (Future Improvement)
1. [ ] Consider [Observation 1]

---

## Next Steps

**If SAFE verdict:**
1. ✅ Proceed to UAT testing (docs/code-quality/uat-plan-2025-01-22.md)
2. Run comprehensive 20-test UAT suite
3. Validate all functionality before release

**If NEEDS FIXES verdict:**
1. ⚠️ Address critical issues first
2. Re-run behavioral comparison tests
3. Verify fixes, then proceed to UAT

**If UNSAFE verdict:**
1. 🔴 Do NOT proceed to UAT
2. Consider rollback to `9e49668`
3. Fix critical regressions
4. Re-run full audit

---

## Appendix: Test Artifacts

**Location:** `/tmp/behavioral-audit/`

**Files:**
- `baseline-*.txt` - Output from commands at commit `9e49668`
- `current-*.txt` - Output from commands at commit `4228b51`
- `*-changes.txt` - Logic diff extracts
- `baseline-file.rb` / `current-file.rb` - File comparisons

---

**Audit completed:** [Timestamp]
**Report generated by:** Claude Code v4.5
```

---

## Success Criteria

### SAFE Verdict Requirements:
- ✅ All critical operations produce identical results (ignoring formatting)
- ✅ No logic regressions detected
- ✅ All shortcuts and edge cases work identically
- ✅ All high-risk areas verified safe
- ✅ UX improvements validated as non-breaking

### NEEDS FIXES Verdict:
- ⚠️ Minor logic issues found but fixable
- ⚠️ Behavioral differences found but understood
- ⚠️ Some tests failed but fixes are straightforward

### UNSAFE Verdict:
- 🔴 Critical functionality broken
- 🔴 Data corruption or loss possible
- 🔴 Multiple regressions across core features
- 🔴 Fixes would require major refactoring

---

## Tips for Effective Audit

1. **Start with automated tests (Phase 3)** - Quick win, catches obvious breaks
2. **Use git diff strategically** - Focus on lib/ first, then bin/, then spec/
3. **Trust but verify** - UX changes are expected, but check they didn't hide logic changes
4. **Look for patterns** - If one brand resolution broke, check all brand resolution code
5. **Document evidence** - Include actual command outputs and code snippets in report
6. **Be thorough but pragmatic** - Not every whitespace change needs analysis
7. **Focus on user impact** - Does the DAM CLI still work for its intended purpose?

---

## How to Start (For Fresh Claude Code Session)

**Opening prompt:**
```
Read the behavioral regression audit instruction document at:
/Users/davidcruwys/dev/ad/appydave-tools/docs/ai-instructions/behavioral-regression-audit.md

Execute the 5-phase audit process to verify that commit 4228b51 behaves
identically to commit 9e49668 except for intentional UX improvements.

Start with Phase 1: Change Inventory.

Wait for my "1" or "continue" confirmation before proceeding to each next phase.
```

**Interactive execution:**
- Complete Phase 1, show results, wait for confirmation
- Complete Phase 2, show results, wait for confirmation
- Complete Phase 3, show results, wait for confirmation
- Complete Phase 4, show results, wait for confirmation
- Complete Phase 5, show results, wait for confirmation
- Generate final report

**User can:**
- Type "1" to proceed to next phase
- Provide feedback or corrections
- Request deeper analysis of specific areas
- Stop at any phase if critical issues found

---

**Last updated:** 2025-01-22
