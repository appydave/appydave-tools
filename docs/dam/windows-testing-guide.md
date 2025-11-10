# DAM Windows Testing Guide

**Purpose:** Windows-specific testing scenarios for appydave-tools DAM (Digital Asset Management)

**Date:** 2025-11-10

**Reference:** Companion to [vat-testing-plan.md](./vat-testing-plan.md)

---

## Overview

This guide covers Windows-specific testing for DAM commands. All core functionality should work identically on Windows, but paths, environment variables, and some shell behaviors differ.

**Key Windows Differences:**
- Drive letters instead of mount points (`C:\` instead of `/Volumes/`)
- Backslash path separators (`\`) vs forward slash (`/`)
- `%USERPROFILE%` instead of `~`
- PowerShell/Command Prompt instead of bash
- Different AWS CLI installation

---

## Prerequisites

### Windows Setup Requirements

**Software installed:**
- ✅ Ruby 3.3+ or 3.4+ (via RubyInstaller)
- ✅ Git for Windows (optional but recommended)
- ✅ AppyDave Tools gem (`gem install appydave-tools`)
- ✅ AWS CLI (for S3 operations)

**Configuration:**
- ✅ `%USERPROFILE%\.config\appydave\settings.json` exists
- ✅ `video-projects-root` configured (Windows path format)
- ✅ AWS credentials configured (via `aws configure` or `.env`)

**Verify setup:**
```powershell
# Check Ruby
ruby --version
# Expected: ruby 3.3.x or 3.4.x

# Check gem installed
gem list appydave-tools

# Check DAM command available
dam help

# Check AWS CLI (optional)
aws --version
```

---

## Windows Path Testing

### Test 1.1: Settings Path Format (JSON)

**Purpose:** Verify Windows paths work in configuration

**Test paths (all should work):**

```json
{
  "video-projects-root": "C:/Users/YourName/Videos/video-projects"
}
```
✅ **Forward slashes** (recommended - cross-platform)

```json
{
  "video-projects-root": "C:\\Users\\YourName\\Videos\\video-projects"
}
```
✅ **Double backslashes** (valid JSON escape)

```json
{
  "video-projects-root": "C:\Users\YourName\Videos\video-projects"
}
```
❌ **Single backslash** (breaks JSON parsing)

**Test commands:**
```powershell
# Test 1: Read config with forward slashes
dam list

# Test 2: Read config with double backslashes
dam list

# Expected: Both work identically
```

**Pass criteria:**
- ✅ Both forward slash and double backslash formats work
- ✅ Single backslash shows clear error message

---

### Test 1.2: SSD Drive Letters

**Purpose:** Verify external SSD detection on Windows

**Windows SSD paths:**
- Mac: `/Volumes/T7/youtube-PUBLISHED/appydave`
- Windows: `E:\youtube-PUBLISHED\appydave` (drive letter varies)

**Test scenario:**

1. **Connect external SSD** (assign drive letter, e.g., E:)

2. **Configure brand with Windows path:**
```json
"locations": {
  "video_projects": "C:/Users/YourName/Videos/v-appydave",
  "ssd_backup": "E:/youtube-PUBLISHED/appydave"
}
```

3. **Test archive command:**
```powershell
dam archive appydave b65 --dry-run
```

4. **Test with SSD disconnected:**
```powershell
# Disconnect SSD
dam archive appydave b65 --dry-run
# Expected: Error "SSD not mounted at E:\"
```

**Pass criteria:**
- ✅ Detects SSD when connected
- ✅ Shows helpful error when disconnected
- ✅ Both `E:\` and `E:/` paths work

---

## Terminal Testing

### Test 2.1: PowerShell Commands

**Purpose:** Verify all DAM commands work in PowerShell

**Test in PowerShell:**
```powershell
# Navigation
cd $env:USERPROFILE\Videos\video-projects\v-appydave\b65-project

# List commands
dam list
dam list appydave
dam list appydave 'b6*'

# S3 commands (with explicit args)
dam s3-up appydave b65 --dry-run
dam s3-down appydave b65 --dry-run
dam s3-status appydave b65

# S3 commands (auto-detect from PWD)
dam s3-up --dry-run
dam s3-down --dry-run
dam s3-status
```

**Pass criteria:**
- ✅ All commands execute without errors
- ✅ Auto-detection works from PowerShell PWD
- ✅ Pattern matching works with quotes

---

### Test 2.2: Command Prompt (cmd.exe)

**Purpose:** Verify basic compatibility with legacy Command Prompt

**Test in cmd.exe:**
```cmd
REM Navigation
cd %USERPROFILE%\Videos\video-projects\v-appydave\b65-project

REM List commands
dam list
dam list appydave

REM S3 commands
dam s3-status appydave b65
```

**Pass criteria:**
- ✅ Basic commands work
- ✅ Auto-detection works
- ⚠️ Pattern matching may require different quoting

---

### Test 2.3: Git Bash

**Purpose:** Verify Unix-like terminal compatibility

**Test in Git Bash:**
```bash
# Navigation (Unix-style paths work in Git Bash)
cd ~/Videos/video-projects/v-appydave/b65-project

# All commands should work like Mac/Linux
dam list
dam list appydave 'b6*'
dam s3-up --dry-run
```

**Pass criteria:**
- ✅ All commands work identically to Mac/Linux
- ✅ Unix-style paths work (`~`, `/c/Users/...`)
- ✅ Pattern matching works with single quotes

---

## DAM Command Testing (Windows-Specific)

### Test 3.1: List Command with Windows Paths

```powershell
# Test 1: List all brands
dam list
# Expected: Brands: appydave, aitldr, joy, kiros, ss, voz

# Test 2: List with summary
dam list --summary
# Expected: Brand counts

# Test 3: List specific brand
dam list appydave
# Expected: All projects in C:/Users/.../v-appydave/

# Test 4: Pattern matching
dam list appydave 'b6*'
# Expected: Projects b60-b69
```

**Pass criteria:**
- ✅ All list modes work
- ✅ Windows paths displayed correctly (not garbled)
- ✅ No Unix-specific path errors

---

### Test 3.2: S3 Upload (Dry Run)

**Purpose:** Test S3 operations with Windows paths

**Prerequisites:**
- AWS CLI configured (`aws configure`)
- Test project exists: `C:\Users\YourName\Videos\v-appydave\b65-project\`
- `s3-staging\` directory with test files

**Test commands:**
```powershell
# Test 1: Explicit args
dam s3-up appydave b65 --dry-run

# Test 2: Auto-detect from project directory
cd C:\Users\YourName\Videos\v-appydave\b65-project
dam s3-up --dry-run
```

**Expected output:**
```
📤 Uploading: v-appydave/b65-project
Local staging: C:\Users\YourName\Videos\v-appydave\b65-project\s3-staging
S3 bucket: s3://your-bucket/staging/v-appydave/b65-project/

[DRY RUN] Would upload:
  ✓ intro.mp4 (150.3 MB)
  ✓ chapter-1.mp4 (75.2 MB)

Would upload: 2 files (225.5 MB)
```

**Pass criteria:**
- ✅ Paths display correctly (not garbled)
- ✅ File detection works
- ✅ MD5 comparison works
- ✅ Dry-run shows correct operations

---

### Test 3.3: S3 Status

```powershell
dam s3-status appydave b65
```

**Expected output:**
```
📊 S3 Staging Status: v-appydave/b65-project

Local s3-staging/ (C:\Users\...\s3-staging):
  ✓ intro.mp4 (150.3 MB) [synced]
  ↑ chapter-1.mp4 (75.2 MB) [local only]

S3 (s3://bucket/staging/v-appydave/b65-project/):
  ✓ intro.mp4 (150.3 MB) [synced]

Summary:
  ✓ In sync: 1
  ↑ Local only: 1
  ↓ S3 only: 0
  ⚠️  Modified: 0
```

**Pass criteria:**
- ✅ Windows paths display correctly
- ✅ All 4 sync states detected
- ✅ File sizes calculated correctly

---

### Test 3.4: Archive Command

**Purpose:** Test SSD archival with Windows drive letters

**Prerequisites:**
- External SSD connected (e.g., E:)
- SSD path configured in `brands.json`

**Test commands:**
```powershell
# Test 1: Dry-run
dam archive appydave b65 --dry-run

# Test 2: Archive without deleting local
dam archive appydave b65

# Test 3: Archive and delete local (requires --force)
dam archive appydave b65 --force
```

**Expected output (dry-run):**
```
📦 Archive: v-appydave/b65-project
Source: C:\Users\YourName\Videos\v-appydave\b65-project
Destination: E:\youtube-PUBLISHED\appydave\b65-project
Size: 2.4 GB

[DRY RUN] Would copy project to SSD
⚠️  Use --force to delete local copy after archiving
```

**Pass criteria:**
- ✅ Detects SSD at E:\
- ✅ Copies entire project directory
- ✅ Preserves directory structure
- ✅ Shows clear error if SSD not mounted

---

### Test 3.5: Manifest Generation

```powershell
# Test 1: Single brand
dam manifest appydave

# Test 2: All brands
dam manifest --all
```

**Expected output:**
```
📊 Generating manifest for appydave...

Scanning locations:
  Local: C:\Users\YourName\Videos\v-appydave (27 projects)
  SSD: E:\youtube-PUBLISHED\appydave (15 projects)

✅ Generated C:\Users\YourName\Videos\v-appydave\projects.json
   Found 35 unique projects

Distribution:
  Local only: 12
  SSD only: 8
  Both locations: 15

Disk Usage:
  Local: 45.3 GB
  SSD: 120.7 GB

🔍 Running validations...
✅ All validations passed!
```

**Pass criteria:**
- ✅ Scans both local and SSD locations
- ✅ Generates valid `projects.json`
- ✅ Windows paths in JSON use forward slashes or escaped backslashes
- ✅ Validation passes

---

### Test 3.6: Sync from SSD

**Purpose:** Restore light files from SSD archive

**Prerequisites:**
- Manifest generated (`dam manifest appydave`)
- Projects exist on SSD (E:\youtube-PUBLISHED\appydave\)

**Test commands:**
```powershell
# Test 1: Dry-run
dam sync-ssd appydave --dry-run

# Test 2: Actual sync
dam sync-ssd appydave
```

**Expected behavior:**
- ✅ Reads `projects.json` manifest
- ✅ Syncs ALL eligible projects from SSD
- ✅ Only copies light files (.srt, .jpg, .png, .md, .json, etc.)
- ✅ Excludes heavy files (.mp4, .mov, etc.)
- ✅ Excludes build directories (node_modules, .next, dist, etc.)
- ✅ Creates `archived/{range}/{project}/` structure
- ✅ Skips already synced files

**Expected output:**
```
📦 Syncing light files from SSD: v-appydave

Reading manifest: C:\Users\...\v-appydave\projects.json
Found 15 projects on SSD

Syncing from: E:\youtube-PUBLISHED\appydave\
Syncing to: C:\Users\...\v-appydave\archived\

Projects to sync:
  b40-b49: 5 projects
  b50-b59: 8 projects
  b60-b69: 2 projects

Syncing b40-first-project...
  ✓ subtitle.srt (15 KB)
  ✓ thumbnail.jpg (250 KB)
  ⊘ intro.mp4 (skipped - heavy file)

[... continues for all projects ...]

Summary:
  ✓ Synced: 45 files (12.5 MB)
  ⊘ Skipped: 120 files (15.3 GB heavy files)
  → Created: 15 archived project directories
```

**Pass criteria:**
- ✅ Windows paths work correctly (E:\ SSD, C:\ local)
- ✅ Light files copied successfully
- ✅ Heavy files excluded
- ✅ Build directories excluded (node_modules, .next, dist, etc.)
- ✅ Dry-run shows preview without copying
- ✅ Archived directory structure created correctly

---

## Error Handling Tests

### Test 4.1: Missing Configuration

```powershell
# Temporarily rename config
ren "%USERPROFILE%\.config\appydave\settings.json" "settings.json.bak"

# Try to run DAM
dam list
```

**Expected error:**
```
❌ VIDEO_PROJECTS_ROOT not configured!
Run: ad_config -e
```

**Restore config:**
```powershell
ren "%USERPROFILE%\.config\appydave\settings.json.bak" "settings.json"
```

**Pass criteria:**
- ✅ Clear error message
- ✅ Helpful suggestion for resolution

---

### Test 4.2: Invalid Windows Path Format

**Edit settings.json with single backslash:**
```json
{
  "video-projects-root": "C:\Users\Name\Videos"
}
```

**Run command:**
```powershell
dam list
```

**Expected error:**
```
❌ Error parsing settings.json: unexpected token at 'C:\Users...'

Hint: Use forward slashes (/) or double backslashes (\\) in JSON paths
Example: "C:/Users/Name/Videos" or "C:\\Users\\Name\\Videos"
```

**Pass criteria:**
- ✅ Detects JSON parse error
- ✅ Shows helpful Windows path guidance

---

### Test 4.3: SSD Not Mounted

```powershell
# Disconnect external SSD
# Try to archive
dam archive appydave b65 --dry-run
```

**Expected error:**
```
❌ SSD not mounted at E:\youtube-PUBLISHED\appydave

Please connect your external SSD and try again.
Configured SSD location: E:\youtube-PUBLISHED\appydave
```

**Pass criteria:**
- ✅ Detects missing SSD
- ✅ Shows clear drive letter
- ✅ Helpful error message

---

### Test 4.4: AWS CLI Not Configured

```powershell
# Temporarily rename AWS credentials
ren "%USERPROFILE%\.aws\credentials" "credentials.bak"

# Try S3 command
dam s3-status appydave b65
```

**Expected error:**
```
❌ AWS credentials not configured

Configure AWS CLI:
  aws configure

Or add to .env file:
  AWS_ACCESS_KEY_ID=...
  AWS_SECRET_ACCESS_KEY=...
```

**Restore credentials:**
```powershell
ren "%USERPROFILE%\.aws\credentials.bak" "credentials"
```

---

## Performance Tests

### Test 5.1: Large Project List Performance

```powershell
# Time the list command
Measure-Command { dam list --summary }
```

**Expected:** Complete in < 2 seconds

---

### Test 5.2: Pattern Matching Performance

```powershell
Measure-Command { dam list appydave 'b*' }
```

**Expected:** Complete in < 1 second

---

## Platform-Specific Code Review

### Known Windows Compatibility

**Ruby file operations (cross-platform):**
- ✅ `File.join()` - Handles Windows paths correctly
- ✅ `Dir.glob()` - Works with Windows wildcards
- ✅ `File.exist?()` - Works with drive letters

**AWS SDK (cross-platform):**
- ✅ `Aws::S3::Client` - Platform agnostic

**Path handling:**
- ✅ `Pathname` class - Windows-aware
- ✅ Forward slashes in Ruby - Work on Windows
- ✅ `File::SEPARATOR` - Platform-specific separator

**Potential issues (requires testing):**
- ⚠️ Shell commands (`system()`, backticks) - May need adjustment
- ⚠️ File permissions - Windows doesn't use Unix chmod
- ⚠️ Symlinks - Windows requires admin privileges

---

## Test Results Checklist

### Phase 1: Windows Setup ✓
- [ ] Ruby installed via RubyInstaller
- [ ] Gem installed successfully
- [ ] Configuration files created
- [ ] Paths formatted correctly (forward slashes or escaped backslashes)

### Phase 2: Path Testing
- [ ] Forward slash paths work
- [ ] Double backslash paths work
- [ ] Single backslash shows error
- [ ] SSD drive letter detection works

### Phase 3: Terminal Testing
- [ ] PowerShell commands work
- [ ] Command Prompt basic commands work
- [ ] Git Bash Unix-style commands work

### Phase 4: DAM Commands
- [ ] List commands work
- [ ] S3 upload (dry-run) works
- [ ] S3 download (dry-run) works
- [ ] S3 status shows all 4 states
- [ ] S3 cleanup commands work
- [ ] Archive command works
- [ ] Manifest generation works
- [ ] Sync from SSD works

### Phase 5: Error Handling
- [ ] Missing config shows helpful error
- [ ] Invalid path format shows Windows guidance
- [ ] Missing SSD shows drive letter error
- [ ] Missing AWS credentials shows setup help

### Phase 6: Performance
- [ ] List commands fast (< 2s)
- [ ] Pattern matching fast (< 1s)

---

## Known Windows Limitations

### 1. File Path Length (MAX_PATH = 260 characters)

**Issue:** Windows has a 260-character path limit by default

**Workaround:**
- Enable long paths in Windows 10/11: `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled`
- Or use shorter project names

### 2. Case Sensitivity

**Issue:** Windows file system is case-insensitive (Mac/Linux are case-sensitive)

**Impact:** `B65` and `b65` are the same on Windows

**Recommendation:** Always use lowercase for consistency

### 3. Reserved Filenames

**Issue:** Windows reserves names like `CON`, `PRN`, `AUX`, `NUL`, `COM1`

**Impact:** Can't create files/folders with these names

### 4. Drive Letters

**Issue:** External drives use letters (E:, F:), not mount points (/Volumes/)

**Impact:** SSD paths differ between Mac and Windows

**Solution:** Configure per-developer in `brands.json`

---

## Reporting Windows Issues

When reporting Windows-specific issues, include:

1. **Windows version:** Windows 10 or 11
2. **Ruby version:** `ruby --version`
3. **Terminal:** PowerShell, Command Prompt, or Git Bash
4. **Full error message**
5. **Configuration:** Sanitized `settings.json` (remove personal info)

**Example issue template:**
```markdown
## Windows Issue: [Brief description]

**Environment:**
- OS: Windows 11 Pro
- Ruby: 3.4.2 (via RubyInstaller)
- Terminal: PowerShell 7.4
- Gem version: appydave-tools 0.18.1

**Command:**
dam s3-up appydave b65

**Error:**
[paste full error output]

**Configuration:**
video-projects-root: C:/Users/Jan/Videos/video-projects

**Expected behavior:**
[what should happen]
```

---

## Next Steps

After Windows testing is complete:

1. **Update main testing plan** with Windows results
2. **Document any Windows-specific workarounds** needed
3. **Create CI/CD Windows tests** (GitHub Actions)
4. **Update README** with Windows badge/status

---

**Last Updated:** 2025-11-10
**Tested On:** Windows 10, Windows 11
**Ruby Versions:** 3.3.x, 3.4.x
**Related Docs:**
- [Windows Setup Guide](../WINDOWS-SETUP.md)
- [DAM Testing Plan](./vat-testing-plan.md)
- [DAM Usage Guide](./usage.md)
