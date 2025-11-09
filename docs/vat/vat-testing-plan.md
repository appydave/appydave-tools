# VAT (Video Asset Tools) - Integration Testing Plan

**Date**: 2025-11-08
**Purpose**: Validate VAT integration into appydave-tools gem
**Tester**: David Cruwys
**Status**: Ready for User Acceptance Testing

**Reference**: Original UAT plan at `/Users/davidcruwys/dev/video-projects/video-asset-tools/docs/testing-plan.md`

---

## Integration Status Summary

### ✅ Completed & Migrated

**Core Infrastructure**:
- ✅ Module namespacing (`Appydave::Tools::Vat::*`)
- ✅ Configuration system (`settings.json`, `.video-tools.env`)
- ✅ 64 RSpec tests (100% passing)
- ✅ RuboCop compliant
- ✅ Documentation complete

**Commands - Phase 1 Complete** (CLI args + auto-detect):
- ✅ `vat help` - Help system
- ✅ `vat list` - Project discovery (3 modes + pattern matching)
- ✅ `vat s3-up` - Upload to S3

**Commands - Phase 2 Complete** (CLI args + auto-detect):
- ✅ `vat s3-down` - Download from S3
- ✅ `vat s3-status` - Check sync status
- ✅ `vat s3-cleanup` - Delete S3 files

**Commands - Not Yet Migrated**:
- ⏳ `vat manifest` - Generate project manifest
- ⏳ `vat archive` - Archive to SSD
- ⏳ `vat sync-ssd` - Sync from SSD

**Utilities - Not Migrated** (not VAT commands):
- ❌ `status-all.sh` - Git status for all repos (workflow script, not needed in gem)
- ❌ `sync-all.sh` - Git pull for all repos (workflow script, not needed in gem)
- ❌ `clone-all.sh` - Clone all repos (workflow script, not needed in gem)

---

## Prerequisites

### Setup Requirements

**For Development Testing** (before gem install):
```bash
# 1. Ensure you're in appydave-tools directory
cd ~/dev/ad/appydave-tools

# 2. Install dependencies
bundle install

# 3. Verify tests pass
bundle exec rspec spec/appydave/tools/vat/
# Expected: 64 examples, 0 failures

# 4. VAT commands available via bin/
ls bin/vat*
# Should show: vat, vat_init.rb, vat_help.rb, vat_list.rb, s3_sync_*.rb
```

**For Gem Testing** (after gem install):
```bash
# 1. Build gem
rake build

# 2. Install locally
gem install pkg/appydave-tools-*.gem

# 3. Verify vat command available
which vat
# Should show: /Users/davidcruwys/.rbenv/shims/vat (or similar)

# 4. Initialize configuration
ad_config -c
# Creates ~/.config/appydave/settings.json

# 5. Verify config
cat ~/.config/appydave/settings.json
# Should show: {"video-projects-root": "/Users/davidcruwys/dev/video-projects"}
```

**AWS & Environment**:
- [ ] `~/.config/appydave/brands.json` populated with brand configuration
- [ ] `~/.aws/credentials` contains AWS profiles for each brand (e.g., `[david-appydave]`)
- [ ] `~/.config/appydave/settings.json` exists with `video-projects-root`
- [ ] External SSD (T7) connected (optional - only for archive/sync-ssd tests)

**Verify setup**:
```bash
# Check AWS credentials configured
cat ~/.aws/credentials | grep -A2 "\[david-appydave\]"
# Should show: aws_access_key_id and aws_secret_access_key

# Check brands config
ad_config -p brands
# Should show: All 6 brands with AWS profiles

# Check vat works
vat help
# Should show: VAT (Video Asset Tools) help

# Check config
vat list
# Should show: Brands: appydave, voz, aitldr, ... (or error if not configured)
```

---

## Test Suite

### Phase 1: Unit Tests (Automated - RSpec)

**Status**: ✅ COMPLETE (64 tests passing)

#### Test 1.1: Config Module
```bash
bundle exec rspec spec/appydave/tools/vat/config_spec.rb
```
**Coverage**:
- ✅ projects_root configuration
- ✅ brand_path resolution
- ✅ expand_brand shortcuts (all 6 brands)
- ✅ available_brands discovery
- ✅ valid_brand? validation
- ✅ configured? checking

**Status**: ✅ 17 examples, 0 failures

---

#### Test 1.2: ProjectResolver Module
```bash
bundle exec rspec spec/appydave/tools/vat/project_resolver_spec.rb
```
**Coverage**:
- ✅ FliVideo short name expansion (b65 → full name)
- ✅ Storyline exact match (boy-baker)
- ✅ Pattern matching (b6* → b60-b69)
- ✅ detect_from_pwd auto-detection
- ✅ Multiple match interactive selection
- ✅ Error handling (no matches, invalid)

**Status**: ✅ 31 examples, 0 failures

---

#### Test 1.3: ConfigLoader Module
```bash
bundle exec rspec spec/appydave/tools/vat/config_loader_spec.rb
```
**Coverage**:
- ✅ .video-tools.env parsing
- ✅ Quote removal from values
- ✅ Comment and empty line handling
- ✅ Required key validation
- ✅ Error messages

**Status**: ✅ 16 examples, 0 failures

---

### Phase 2: Integration Tests (Manual - Development)

**Run from**: `~/dev/ad/appydave-tools` (development directory)

#### Test 2.1: Help System
```bash
# Test: Main help
bin/vat help

# Test: Command-specific help
bin/vat help list
bin/vat help s3-up
bin/vat help s3-down
bin/vat help brands
bin/vat help workflows
```
**Expected**:
- Full help overview
- Detailed command help
- Brand shortcuts listed
- Workflow explanations

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.3: List Brands (Mode 1)
```bash
# Test: List brands only
bin/vat list
```
**Expected**: `Brands: aitldr, appydave, joy, kiros, ss, voz` (shortcuts)

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.4: List Brands with Summary (Mode 2)
```bash
# Test: Brands with project counts
bin/vat list --summary
```
**Expected**:
```
aitldr: X projects
appydave: Y projects
joy: Z projects
...
```

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.5: List Brand Projects (Mode 3)
```bash
# Test: All projects for brand
bin/vat list appydave
```
**Expected**: List of all appydave projects (excludes `archived/`, `.git`, etc.)

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.6: Pattern Matching (Mode 3b)
```bash
# Test: Pattern matching
bin/vat list appydave 'b6*'
```
**Expected**: Only projects starting with `b6` (b60-b69)

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.7: S3 Upload with CLI Args
```bash
# Test: Upload with explicit args (dry-run)
bin/s3_sync_up.rb appydave b65 --dry-run
```
**Expected**: Shows files that would be uploaded, no actual upload

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.8: S3 Upload Auto-Detect
```bash
# Test: Upload from project directory
cd ~/dev/video-projects/v-appydave/b65-*
bin/s3_sync_up.rb --dry-run
```
**Expected**: Auto-detects brand and project, shows dry-run

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.9: S3 Download with CLI Args ⭐ NEW
```bash
# Test: Download with explicit args (dry-run)
bin/s3_sync_down.rb appydave b65 --dry-run
```
**Expected**: Shows files that would be downloaded, no actual download

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.10: S3 Download Auto-Detect ⭐ NEW
```bash
# Test: Download from project directory
cd ~/dev/video-projects/v-appydave/b65-*
bin/s3_sync_down.rb --dry-run
```
**Expected**: Auto-detects brand and project, shows dry-run

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.11: S3 Status with CLI Args ⭐ NEW
```bash
# Test: Check status with explicit args
bin/s3_sync_status.rb appydave b65
```
**Expected**: Shows sync status (in sync, local only, S3 only, out of sync)

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.12: S3 Status Auto-Detect ⭐ NEW
```bash
# Test: Check status from project directory
cd ~/dev/video-projects/v-appydave/b65-*
bin/s3_sync_status.rb
```
**Expected**: Auto-detects and shows sync status

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.13: S3 Cleanup with CLI Args ⭐ NEW
```bash
# Test: Cleanup with explicit args (dry-run)
bin/s3_sync_cleanup.rb appydave b65 --dry-run
```
**Expected**: Shows files that would be deleted, no actual deletion

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 2.14: S3 Cleanup Auto-Detect ⭐ NEW
```bash
# Test: Cleanup from project directory
cd ~/dev/video-projects/v-appydave/b65-*
bin/s3_sync_cleanup.rb --dry-run
```
**Expected**: Auto-detects and shows cleanup dry-run

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

### Phase 3: Gem Installation Tests (Manual - Installed Gem)

**Prerequisites**: `gem install pkg/appydave-tools-*.gem`

#### Test 3.1: Gem Commands Available
```bash
# Test: vat command in PATH
which vat

# Test: Help works
vat help
```
**Expected**:
- `which vat` shows gem bin path
- Help text displays

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 3.2: All List Commands Work
```bash
vat list
vat list --summary
vat list appydave
vat list appydave 'b6*'
```
**Expected**: All modes work correctly

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 3.3: S3 Commands Work (CLI Args)
```bash
vat s3-up appydave b65 --dry-run
vat s3-down appydave b65 --dry-run
vat s3-status appydave b65
vat s3-cleanup appydave b65 --dry-run
```
**Expected**: All commands work with explicit args

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 3.4: S3 Commands Work (Auto-Detect)
```bash
cd ~/dev/video-projects/v-appydave/b65-*

vat s3-up --dry-run
vat s3-down --dry-run
vat s3-status
vat s3-cleanup --dry-run
```
**Expected**: All commands auto-detect from PWD

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 3.5: Brand Shortcuts Work
```bash
# Test: All 6 brand shortcuts
vat list appydave  # v-appydave
vat list voz       # v-voz
vat list aitldr    # v-aitldr
vat list kiros     # v-kiros
vat list joy       # v-beauty-and-joy
vat list ss        # v-supportsignal
```
**Expected**: All shortcuts expand correctly

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 3.6: Short Name Expansion (FliVideo)
```bash
# Test: Short name expands to full name
vat list appydave b65
# Should resolve to: b65-guy-monroe-marketing-plan (or similar)
```
**Expected**: Expands `b65` to full project name

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

### Phase 4: Edge Cases & Error Handling

#### Test 4.1: Invalid Brand Name
```bash
vat list invalid-brand
```
**Expected**: Error message listing available brands

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 4.2: Invalid Project Name
```bash
vat list appydave invalid-project
```
**Expected**: Error "No project found matching 'invalid-project'"

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 4.3: Missing Configuration
```bash
# Test: Temporarily rename config
mv ~/.config/appydave/settings.json ~/.config/appydave/settings.json.bak
vat list
mv ~/.config/appydave/settings.json.bak ~/.config/appydave/settings.json
```
**Expected**: Error "VIDEO_PROJECTS_ROOT not configured! Run: ad_config -e"

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 4.4: No Arguments to vat
```bash
vat
```
**Expected**: Usage message and suggestion to run `vat help`

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 4.5: Unknown Command
```bash
vat unknown-command
```
**Expected**: Error "Unknown command: unknown-command"

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 4.6: S3 Commands Without Brand Path
```bash
cd /tmp
vat s3-up
```
**Expected**: Error "Could not detect brand and project from current directory"

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

### Phase 5: Performance Tests

#### Test 5.1: List Performance
```bash
time vat list --summary
```
**Expected**: Completes in < 2 seconds

**Status**: [ ] Pass [ ] Fail
**Time taken**: ___________________________________________

---

#### Test 5.2: Pattern Matching Performance
```bash
time vat list appydave 'b*'
```
**Expected**: Completes in < 1 second

**Status**: [ ] Pass [ ] Fail
**Time taken**: ___________________________________________

---

### Phase 6: Real-World Workflow Tests

#### Test 6.1: Complete Upload/Download Cycle
```bash
# 1. Upload project
vat s3-up appydave b65

# 2. Check status
vat s3-status appydave b65
# Expected: All files in sync

# 3. Download to different location (simulate collaborator)
vat s3-down appydave b65

# 4. Clean up
vat s3-cleanup appydave b65 --force
```
**Expected**: Full workflow works without errors

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

#### Test 6.2: Pattern-Based Discovery
```bash
# Discover all b60-series projects
vat list appydave 'b6*'

# Upload multiple projects (if needed)
for project in b60 b61 b65; do
  vat s3-up appydave $project --dry-run
done
```
**Expected**: Pattern matching helps with batch operations

**Status**: [ ] Pass [ ] Fail
**Notes**: ___________________________________________

---

## Not Yet Implemented (Future Work)

### Commands Migrated but Not Updated for CLI Args

These commands were copied from the original VAT but still need Phase 2 updates:

#### ⏳ Generate Manifest
```bash
# Current: bin/generate_manifest.rb
# Expected: vat manifest appydave
```
**Status**: Copied but needs CLI arg support
**Priority**: Low (utility command, not core workflow)

---

#### ⏳ Archive Project
```bash
# Current: bin/archive_project.rb
# Expected: vat archive appydave b63
```
**Status**: Copied but needs CLI arg support
**Priority**: Medium (used for completed projects)

---

#### ⏳ Sync from SSD
```bash
# Current: bin/sync_from_ssd.rb
# Expected: vat sync-ssd appydave
```
**Status**: Copied but needs CLI arg support
**Priority**: Medium (used for recovery)

---

### Workflow Scripts (Not Migrating to Gem)

These are repository management scripts, not VAT commands:

- ❌ `status-all.sh` - Git status for all v-* repos
- ❌ `sync-all.sh` - Git pull for all repos
- ❌ `clone-all.sh` - Clone all brand repos

**Rationale**: These are development workflow tools for managing the video-projects repository structure, not video asset operations. They belong in the video-projects folder, not the appydave-tools gem.

---

## Test Results Summary

### Phase 1: Unit Tests (Automated)
- **Config**: 17 / 17 ✅
- **ProjectResolver**: 31 / 31 ✅
- **ConfigLoader**: 16 / 16 ✅
- **TOTAL**: **64 / 64 ✅**

### Phase 2: Integration Tests (Manual - Development)
- Passed: _____ / 13
- Failed: _____ / 13

### Phase 3: Gem Installation Tests (Manual - Installed)
- Passed: _____ / 6
- Failed: _____ / 6

### Phase 4: Edge Cases
- Passed: _____ / 6
- Failed: _____ / 6

### Phase 5: Performance
- Passed: _____ / 2
- Failed: _____ / 2

### Phase 6: Real-World Workflows
- Passed: _____ / 2
- Failed: _____ / 2

### **GRAND TOTAL**
- **Unit Tests**: 64 / 64 ✅
- **Manual Tests**: _____ / 29
- **Overall**: _____ / 93

---

## Implementation Status Checklist

### ✅ Completed Features

**Core Infrastructure**:
- [x] Module namespacing (`Appydave::Tools::Vat`)
- [x] Configuration system (`settings.json` via `ad_config`)
- [x] Brand shortcuts (all 6 brands)
- [x] Project resolution (short names, patterns, exact match)
- [x] Auto-detection from PWD
- [x] 64 RSpec tests (100% passing)
- [x] RuboCop compliant
- [x] Guard integration
- [x] Documentation complete

**Commands (CLI Args + Auto-Detect)**:
- [x] `vat help` - Help system
- [x] `vat list` - All 4 modes working
- [x] `vat s3-up` - Upload to S3
- [x] `vat s3-down` - Download from S3 ⭐ Phase 2 complete
- [x] `vat s3-status` - Check sync status ⭐ Phase 2 complete
- [x] `vat s3-cleanup` - Delete S3 files ⭐ Phase 2 complete

### ⏳ Pending Implementation

**Commands (Copied but need CLI arg support)**:
- [ ] `vat manifest` - Generate project manifest
- [ ] `vat archive` - Archive to SSD
- [ ] `vat sync-ssd` - Sync from SSD

**Testing**:
- [ ] Manual integration tests (Phase 2)
- [ ] Gem installation tests (Phase 3)
- [ ] Edge case validation (Phase 4)
- [ ] Performance verification (Phase 5)
- [ ] Real-world workflow testing (Phase 6)

**Future Enhancements**:
- [x] AWS SDK integration (replace AWS CLI shell commands) ✅ Phase 3 complete
- [ ] Pattern-based brand discovery (remove hardcoded list)
- [ ] Windows compatibility testing (Jan)
- [ ] Batch operations (upload/download multiple projects)

---

## Issues Found

| Test ID | Issue Description | Severity | Status |
|---------|------------------|----------|---------|
| TBD | (To be filled during testing) | | |

---

## Sign-Off

**Phase 1 - Unit Tests**: ✅ COMPLETE
- [x] All 64 RSpec tests pass
- [x] RuboCop clean
- [x] Guard configured

**Phase 2 - Integration Tests**: [ ] PENDING
- [ ] All development bin/ tests pass
- [ ] CLI args work
- [ ] Auto-detect works
- [ ] Phase 2 commands (s3-down, s3-status, s3-cleanup) work

**Phase 3 - Gem Tests**: [ ] PENDING
- [ ] Gem builds successfully
- [ ] Gem installs locally
- [ ] All vat commands work after install

**Phase 4 - Edge Cases**: [ ] PENDING
- [ ] Error handling works
- [ ] Helpful error messages
- [ ] Graceful failures

**Phase 5 - Performance**: [ ] PENDING
- [ ] List commands fast (< 2s)
- [ ] Pattern matching fast (< 1s)

**Phase 6 - Real-World**: [ ] PENDING
- [ ] Upload/download cycle works
- [ ] Collaboration workflow validated

**Final Approval**: [ ] APPROVED [ ] REJECTED

**Tested by**: ___________________________________________
**Date**: ___________________________________________

---

## Recommended Test Order

**Start here** (automated tests):
1. ✅ Run all RSpec tests: `bundle exec rspec spec/appydave/tools/vat/`

**Then manual development tests** (safest first):
2. Phase 2.1-2.5: Help and list commands
3. Phase 2.6-2.7: S3 upload with dry-run
4. Phase 2.8-2.13: Phase 2 commands (download, status, cleanup) with dry-run
5. Phase 4: Edge cases and error handling

**Then gem installation tests**:
6. Build and install gem
7. Phase 3: Run all tests with installed gem

**Then real operations** (after dry-run validation):
8. Phase 6.1: Real S3 upload/download cycle
9. Phase 5: Performance tests

**Finally**:
10. Phase 6.2: Real-world workflow validation

---

## Notes for Tester

### Key Differences from Original VAT

1. **Commands now work from anywhere**: Original required `cd` to project directory or explicit paths
2. **Phase 2 commands complete**: s3-down, s3-status, s3-cleanup now accept CLI args
3. **Namespace changed**: `VatConfig` → `Appydave::Tools::Vat::Config`
4. **Gem-based**: Install via `gem install appydave-tools` instead of shell alias
5. **Better tested**: 64 RSpec tests vs. manual testing only
6. **Configuration migrated**: `~/.vat-config` → `~/.config/appydave/settings.json` (managed via `ad_config`)

### What to Watch For

- **Backward compatibility**: Existing workflows should still work
- **Error messages**: Should be helpful, not cryptic
- **Performance**: Should not be slower than original
- **Windows compatibility**: Test with Jan when ready

---

**Created**: 2025-11-08
**Version**: 1.0 (Integration Testing Plan)
**Purpose**: Validate VAT integration into appydave-tools gem
**Reference**: `/Users/davidcruwys/dev/video-projects/video-asset-tools/docs/testing-plan.md`
