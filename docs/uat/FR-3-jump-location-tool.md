# UAT: FR-3 - Jump Location Tool

**Spec:** `docs/specs/fr-003-jump-location-tool.md`
**Date:** 2025-12-14
**Tester:** David
**Status:** In Progress (10/28 complete)

## Prerequisites

Before starting, ensure:

1. [x] Dependencies installed: `bundle install`
2. [x] Backup any existing `~/.config/appydave/locations.json` (if it exists)
3. [x] Note: Tests will create/modify `locations.json` - use cleanup section after testing

## How to Use This Plan

1. Run each command in your terminal
2. Compare output to "Expected" description
3. Mark the checkbox: `[x]` for pass, `[ ]` for fail
4. Add notes if behavior differs from expected
5. Complete the Summary section when done

---

## Test 1: Help and Info

### Test 1.1: Main help

**What to verify:** Help displays all available commands

**Command:**
```bash
ruby bin/jump.rb --help
```

**Expected:**
- Shows usage information
- Lists all commands: search, get, list, add, update, remove, validate, report, generate, info
- Shows global options (--format, --help)

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 1.2: Command-specific help

**What to verify:** Each command has detailed help

**Command:**
```bash
ruby bin/jump.rb search --help
```

**Expected:**
- Shows search-specific usage
- Documents search terms argument
- Shows format option

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 1.3: Info command

**What to verify:** Info shows config location and stats

**Command:**
```bash
ruby bin/jump.rb info
```

**Expected:**
- Shows config file path
- Shows location count
- Shows last validated timestamp (if available)

**Result:** [x] Pass / [ ] Fail
**Notes:** Bug found and fixed - was showing "No locations found" instead of config info. Fix applied to TableFormatter.

---

## Test 2: CRUD Operations

### Test 2.1: Add a location (minimal)

**What to verify:** Can add location with only required fields

**Command:**
```bash
ruby bin/jump.rb add --key test-minimal --path ~/dev --format json
```

**Expected:**
- Returns JSON with `success: true`
- Location includes key and path
- `jump` field auto-generated as `jtest-minimal`

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.2: Add a location (all fields)

**What to verify:** Can add location with all metadata fields

**Command:**
```bash
ruby bin/jump.rb add --key test-full --path ~/dev/test --brand appydave --type tool --tags ruby,cli,test --description "Full test location" --format json
```

**Expected:**
- Returns JSON with `success: true`
- Location object includes all provided fields
- `jump` field auto-generated as `jtest-full`

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.3: Add duplicate key (error)

**What to verify:** Cannot add location with duplicate key

**Command:**
```bash
ruby bin/jump.rb add --key test-minimal --path ~/other --format json
```

**Expected:**
- Returns JSON with `success: false`
- Error message indicates duplicate key
- Exit code is non-zero

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.4: Get by exact key

**What to verify:** Can retrieve location by key

**Command:**
```bash
ruby bin/jump.rb get test-full --format json
```

**Expected:**
- Returns JSON with `success: true`
- Contains single result with all fields from test 2.2
- Includes score field

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.5: Get non-existent key

**What to verify:** Error with suggestions for unknown key

**Command:**
```bash
ruby bin/jump.rb get nonexistent-key --format json
```

**Expected:**
- Returns JSON with `success: false`
- Error code is `NOT_FOUND`
- May include `suggestion` field with similar keys

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.6: Update location

**What to verify:** Can modify existing location fields

**Command:**
```bash
ruby bin/jump.rb update test-minimal --description "Updated description" --tags updated,modified --format json
```

**Expected:**
- Returns JSON with `success: true`
- Location now has new description and tags
- Other fields unchanged

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.7: List all locations

**What to verify:** List shows all added locations

**Command:**
```bash
ruby bin/jump.rb list --format table
```

**Expected:**
- Table includes `test-minimal` and `test-full` rows
- Shows key, jump alias, type, brand, description columns
- Colored/formatted output

**Result:** [x] Pass / [ ] Fail
**Notes:**

---

### Test 2.8: Remove location

**What to verify:** Can remove location with --force

**Command:**
```bash
ruby bin/jump.rb remove test-minimal --force --format json
```

**Expected:**
- Returns JSON with `success: true`
- Location no longer appears in `jump list`

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 3: Search Functionality

### Test 3.1: Search by keyword

**What to verify:** Fuzzy search finds matches

**Command:**
```bash
ruby bin/jump.rb search test --format json
```

**Expected:**
- Returns matches containing "test"
- Results include `test-full` (added earlier)
- Each result has a `score` field

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 3.2: Search by multiple terms

**What to verify:** Multiple terms narrow results

**Command:**
```bash
ruby bin/jump.rb search ruby tool --format json
```

**Expected:**
- Returns matches containing both "ruby" AND "tool"
- Higher scores for better matches
- Results sorted by score (highest first)

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 3.3: Search with no matches

**What to verify:** Empty search returns no results gracefully

**Command:**
```bash
ruby bin/jump.rb search zzzznonexistent --format json
```

**Expected:**
- Returns JSON with `success: true`
- `count: 0`
- Empty `results` array

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 3.4: Search with table output

**What to verify:** Table format is human-readable

**Command:**
```bash
ruby bin/jump.rb search test --format table
```

**Expected:**
- Pretty formatted table
- Columns properly aligned
- May include colors (terminal-dependent)

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 3.5: Search with paths output

**What to verify:** Paths format returns one path per line

**Command:**
```bash
ruby bin/jump.rb search test --format paths
```

**Expected:**
- One path per line (no table formatting)
- Paths are expanded (no `~`)
- Suitable for piping to other commands

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 4: Validation

### Test 4.1: Validate existing paths

**What to verify:** Validation reports path status

**Command:**
```bash
ruby bin/jump.rb validate --format json
```

**Expected:**
- Returns validation results for all locations
- Each location shows `valid: true` or `valid: false`
- Reports which paths don't exist

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 4.2: Validate specific key

**What to verify:** Can validate single location

**Command:**
```bash
ruby bin/jump.rb validate test-full --format json
```

**Expected:**
- Returns validation for only `test-full`
- Shows whether `~/dev/test` path exists

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 5: Reports

### Test 5.1: Report brands

**What to verify:** Shows brands with location counts

**Command:**
```bash
ruby bin/jump.rb report brands --format table
```

**Expected:**
- Lists brands (e.g., "appydave")
- Shows count of locations per brand
- Table formatted output

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 5.2: Report types

**What to verify:** Shows types with location counts

**Command:**
```bash
ruby bin/jump.rb report types --format table
```

**Expected:**
- Lists types (e.g., "tool")
- Shows count of locations per type

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 5.3: Report tags

**What to verify:** Shows all tags with counts

**Command:**
```bash
ruby bin/jump.rb report tags --format json
```

**Expected:**
- Lists all unique tags
- Shows count of locations per tag
- JSON format with structured data

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 5.4: Report by-brand

**What to verify:** Groups locations by brand

**Command:**
```bash
ruby bin/jump.rb report by-brand --format table
```

**Expected:**
- Locations grouped under brand headers
- Shows all locations for each brand

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 5.5: Report by-brand filtered

**What to verify:** Can filter to specific brand

**Command:**
```bash
ruby bin/jump.rb report by-brand appydave --format json
```

**Expected:**
- Only shows locations for "appydave" brand
- JSON format with filtered results

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 5.6: Report summary

**What to verify:** Overview of all data

**Command:**
```bash
ruby bin/jump.rb report summary --format table
```

**Expected:**
- Total location count
- Counts by brand, type, etc.
- Overview statistics

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 6: Generation

### Test 6.1: Generate aliases (stdout)

**What to verify:** Generates shell alias format

**Command:**
```bash
ruby bin/jump.rb generate aliases
```

**Expected:**
- Outputs shell alias lines
- Format: `alias jtest-full="cd /expanded/path"`
- One alias per line

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 6.2: Generate aliases (file output)

**What to verify:** Can write to file

**Command:**
```bash
ruby bin/jump.rb generate aliases --output /tmp/test-aliases.zsh && cat /tmp/test-aliases.zsh
```

**Expected:**
- Creates file at specified path
- File contains alias definitions
- No output to stdout (besides cat output)

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 6.3: Generate help

**What to verify:** Generates help content for fzf

**Command:**
```bash
ruby bin/jump.rb generate help
```

**Expected:**
- Outputs help-formatted content
- Each location on one line
- Format suitable for fzf search

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 7: Output Formats

### Test 7.1: JSON format structure

**What to verify:** JSON follows spec structure

**Command:**
```bash
ruby bin/jump.rb list --format json | head -20
```

**Expected:**
- Valid JSON
- Has `success`, `count`, `results` fields
- Each result has `key`, `path`, `jump` fields

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 7.2: Table format readability

**What to verify:** Table is well-formatted

**Command:**
```bash
ruby bin/jump.rb list --format table
```

**Expected:**
- Columns aligned
- Headers visible
- Data rows properly formatted

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 8: Error Handling

### Test 8.1: Invalid key format

**What to verify:** Rejects invalid key characters

**Command:**
```bash
ruby bin/jump.rb add --key "INVALID KEY!" --path ~/dev --format json
```

**Expected:**
- Returns JSON with `success: false`
- Error message explains key format requirements
- Exit code is non-zero (2 for invalid input)

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 8.2: Missing required argument

**What to verify:** Clear error for missing --path

**Command:**
```bash
ruby bin/jump.rb add --key test-missing-path --format json
```

**Expected:**
- Returns error (JSON or text)
- Indicates path is required

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 8.3: Invalid path format

**What to verify:** Rejects paths without / or ~

**Command:**
```bash
ruby bin/jump.rb add --key test-bad-path --path "relative/path" --format json
```

**Expected:**
- Returns JSON with `success: false`
- Error explains path must start with ~ or /

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Test 9: Exit Codes

### Test 9.1: Success exit code

**What to verify:** Success returns 0

**Command:**
```bash
ruby bin/jump.rb list --format json; echo "Exit code: $?"
```

**Expected:**
- Exit code: 0

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 9.2: Not found exit code

**What to verify:** Not found returns 1

**Command:**
```bash
ruby bin/jump.rb get nonexistent123 --format json; echo "Exit code: $?"
```

**Expected:**
- Exit code: 1

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

### Test 9.3: Invalid input exit code

**What to verify:** Invalid input returns 2

**Command:**
```bash
ruby bin/jump.rb add --key "BAD!" --path ~/dev --format json; echo "Exit code: $?"
```

**Expected:**
- Exit code: 2

**Result:** [ ] Pass / [ ] Fail
**Notes:**

---

## Cleanup

After testing, remove test data:

```bash
# Remove test locations
ruby bin/jump.rb remove test-full --force 2>/dev/null
ruby bin/jump.rb remove test-minimal --force 2>/dev/null

# Remove generated test file
rm -f /tmp/test-aliases.zsh

# Verify cleanup
ruby bin/jump.rb list --format table
```

---

## Summary

**Date completed:**
**Passed:** __/28
**Failed:** __/28

### Issues Found

[Describe any failures or unexpected behavior]

### UX Observations

[Note any friction, confusing output, or suggestions - even for passing tests]

### Exit Codes Verified

| Code | Meaning | Tested |
|------|---------|--------|
| 0 | Success | [ ] |
| 1 | Not found | [ ] |
| 2 | Invalid input | [ ] |
| 3 | Config error | [ ] (not directly tested) |
| 4 | Path not found | [ ] (covered by validate) |

## Verdict

[ ] Ready to ship
[ ] Needs rework - see issues above
