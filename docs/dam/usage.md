# DAM (Digital Asset Management) - Usage Guide

**DAM** is a unified CLI for managing video projects across local storage, S3 cloud collaboration, and SSD archival storage.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
- [Examples](#examples)
- [Workflows](#workflows)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Install appydave-tools gem
gem install appydave-tools

# Initialize configuration
dam init

# List available brands
dam list

# List projects for a brand
dam list appydave

# Upload files to S3 for collaboration
dam s3-up appydave b65

# Download files from S3
dam s3-down appydave b65

# Check sync status
dam s3-status appydave b65
```

---

## Installation

### Install Gem

```bash
gem install appydave-tools
```

### Initialize Configuration

```bash
dam init
```

This creates `~/.dam-config` pointing to your video projects directory.

### AWS CLI Setup

DAM uses the AWS CLI for S3 operations. Install and configure:

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure AWS credentials (if not using .video-tools.env)
aws configure
```

---

## Configuration

### System Configuration (`~/.dam-config`)

Created by `dam init`:

```bash
VIDEO_PROJECTS_ROOT=/Users/yourname/dev/video-projects
```

### Brand Configuration (`.video-tools.env`)

Each brand directory contains a `.video-tools.env` file:

```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=ap-southeast-1
S3_BUCKET=your-bucket-name
S3_STAGING_PREFIX=staging/v-appydave/

# SSD Backup Path
SSD_BASE=/Volumes/T7/youtube-PUBLISHED/appydave
```

**Example template**: See `v-shared/video-asset-tools/.env.example` in your video-projects folder.

---

## Commands

### Initialization & Help

#### `dam init`
Initialize DAM configuration.

```bash
dam init
```

#### `dam help [command]`
Show help information.

```bash
dam help                # Overview
dam help s3-up          # Command-specific help
dam help brands         # List available brands
dam help workflows      # Explain FliVideo vs Storyline
```

### Project Discovery

#### `dam list [--summary] [brand] [pattern]`
List brands and projects.

**Mode 1: Brands only (clean list)**
```bash
dam list
# Output: Brands: appydave, aitldr, joy, kiros, ss, voz
```

**Mode 2: Brands with project counts (summary)**
```bash
dam list --summary
# Output:
# appydave: 27 projects
# voz: 3 projects
# aitldr: 2 projects
```

**Mode 3: Specific brand's projects**
```bash
dam list appydave
# Output: Lists all AppyDave projects
```

**Mode 3b: Pattern matching**
```bash
dam list appydave 'b6*'
# Output: Lists b60, b61, b62...b69 projects
```

### S3 Sync Commands

#### `dam s3-up [brand] [project] [--dry-run]`
Upload files from local `s3-staging/` to S3.

```bash
# With explicit args
dam s3-up appydave b65

# Auto-detect from current directory
cd ~/dev/video-projects/v-appydave/b65-project
dam s3-up

# Dry-run (preview without uploading)
dam s3-up appydave b65 --dry-run
```

**What it does:**
- Uploads files from `project/s3-staging/` to S3
- Skips files already in sync (MD5 comparison)
- Shows progress and summary

#### `dam s3-down [brand] [project] [--dry-run]`
Download files from S3 to local `s3-staging/`.

```bash
# With explicit args
dam s3-down appydave b65

# Auto-detect
cd ~/dev/video-projects/v-appydave/b65-project
dam s3-down

# Dry-run
dam s3-down voz boy-baker --dry-run
```

**What it does:**
- Downloads files from S3 to `project/s3-staging/`
- Skips files already in sync
- Creates `s3-staging/` if it doesn't exist

#### `dam s3-status [brand] [project]`
Check sync status between local and S3.

```bash
dam s3-status appydave b65
```

**Output:**
```
📊 S3 Staging Status: v-appydave/b65-project

Local s3-staging/:
  ✓ intro.mp4  (150.3 MB)
  ↑ outro.mp4  (75.2 MB)

S3 (s3://bucket/staging/v-appydave/b65-project/):
  ✓ intro.mp4  (150.3 MB)
  ↓ chapter-1.mp4  (200.1 MB)

Status:
  ✓ In sync: 1
  ↑ Local only (need upload): 1
  ↓ S3 only (need download): 1
  ⚠️  Out of sync (file changed): 0
```

#### `dam s3-cleanup-remote [brand] [project] [--dry-run] [--force]`
Delete S3 staging files for a project.

```bash
# Preview what would be deleted
dam s3-cleanup-remote appydave b65 --dry-run

# Delete with confirmation prompt
dam s3-cleanup-remote appydave b65

# Delete without confirmation
dam s3-cleanup-remote appydave b65 --force
```

**Warning:** This deletes files from S3. Use `--dry-run` first!

**Note:** The old `dam s3-cleanup` command still works but shows a deprecation warning.

#### `dam s3-cleanup-local [brand] [project] [--dry-run] [--force]`
Delete local s3-staging files for a project.

```bash
# Preview what would be deleted
dam s3-cleanup-local appydave b65 --dry-run

# Delete with confirmation prompt
dam s3-cleanup-local appydave b65

# Delete without confirmation
dam s3-cleanup-local appydave b65 --force
```

**Warning:** This deletes local files in the s3-staging directory. Use `--dry-run` first!

### Project Management

#### `dam manifest [brand] [--all]`
Generate project manifest for a brand (tracks projects across local + SSD storage).

```bash
# Generate manifest for specific brand
dam manifest appydave

# Generate manifests for all configured brands
dam manifest --all
```

**What it does:**
- Scans local and SSD storage locations
- Tracks project distribution (local only, SSD only, or both)
- Calculates disk usage statistics
- Validates project ID formats
- Outputs `projects.json` in brand directory

**Example output:**
```
📊 Generating manifest for appydave...

✅ Generated /path/to/v-appydave/projects.json
   Found 27 unique projects

Distribution:
  Local only: 15
  SSD only: 8
  Both locations: 4

Disk Usage:
  Local: 45.3 GB
  SSD: 120.7 GB

🔍 Running validations...
✅ All validations passed!
```

#### `dam archive [brand] [project] [--dry-run] [--force]`
Archive completed project to SSD backup location.

```bash
# Preview archive operation
dam archive appydave b63 --dry-run

# Copy to SSD (leaves local copy intact)
dam archive appydave b63

# Copy to SSD and delete local copy
dam archive appydave b63 --force
```

**What it does:**
- Copies entire project directory to SSD backup location
- Verifies SSD is mounted before archiving
- Shows project size before copying
- Optional: Delete local copy after successful archive (--force)

**Configuration:** Uses `ssd_backup` location from `brands.json` config.

#### `dam sync-ssd [brand] [--dry-run]`
Restore light files (subtitles, images, docs) from SSD to local for archived projects.

**Important:** Does NOT sync heavy video files (MP4, MOV, etc.)

```bash
# Sync all AppyDave projects from SSD
dam sync-ssd appydave

# Preview what would be synced
dam sync-ssd appydave --dry-run

# Sync VOZ projects
dam sync-ssd voz
```

**What it does:**
- Reads `projects.json` manifest to find projects on SSD
- Syncs ALL eligible projects for the brand (not one at a time)
- Only copies light files: `.srt`, `.vtt`, `.jpg`, `.png`, `.md`, `.txt`, `.json`, `.yml`
- Excludes heavy files: `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`
- Creates `archived/{range}/{project}/` directory structure
- Skips files already synced (size comparison)

**Requirements:**
- Must have `projects.json` manifest (run: `dam manifest <brand>` first)
- SSD must be mounted
- Projects must exist on SSD

**Use Cases:**
- Restore subtitles and images without huge video files
- Access project documentation from archived projects
- Prepare project for re-editing (get metadata, then manually copy videos if needed)

---

## Examples

### Example 1: Collaboration Workflow (David → Jan)

**David (uploads to S3):**
```bash
cd ~/dev/video-projects/v-appydave/b65-guy-monroe
# Place files in s3-staging/
mkdir -p s3-staging
cp ~/Downloads/intro-footage.mp4 s3-staging/

# Upload to S3
dam s3-up appydave b65
```

**Jan (downloads from S3):**
```bash
cd ~/dev/video-projects/v-appydave/b65-guy-monroe

# Check what's available
dam s3-status appydave b65

# Download files
dam s3-down appydave b65

# Edit files in s3-staging/
# ...

# Upload edited files back
dam s3-up appydave b65
```

### Example 2: Pattern Matching

```bash
# List all b60-series projects
dam list appydave 'b6*'

# List all completed projects
dam list appydave 'b[1-5]*'
```

### Example 3: Cleanup After Project Completion

```bash
# Archive to SSD
dam archive appydave b63

# Verify sync status
dam s3-status appydave b63

# Clean up S3 (saves storage costs)
dam s3-cleanup-remote appydave b63 --dry-run  # Preview
dam s3-cleanup-remote appydave b63 --force     # Execute
```

---

## Workflows

### FliVideo Workflow (AppyDave Brand)

**Pattern:** Sequential, chapter-based recording

**Project Naming:** `b65-guy-monroe-marketing-plan`

**Short Name Support:**
```bash
dam s3-up appydave b65  # Expands to full project name
```

**Typical Flow:**
1. Record chapters sequentially
2. Upload raw footage to S3 for collaboration
3. Download edited chapters from S3
4. Publish final video
5. Archive to SSD

### Storyline Workflow (VOZ, AITLDR Brands)

**Pattern:** Script-first, narrative-driven content

**Project Naming:** `boy-baker`, `the-point`

**Full Name Required:**
```bash
dam s3-up voz boy-baker  # Use full project name
```

**Typical Flow:**
1. Write script
2. Record A-roll (main footage)
3. Upload raw footage to S3
4. Download edited version from S3
5. Publish and archive

---

## Brand Shortcuts

DAM supports brand shortcuts for faster typing:

| Shortcut | Full Name | Purpose |
|----------|-----------|---------|
| `appydave` | `v-appydave` | AppyDave brand videos |
| `voz` | `v-voz` | VOZ client projects |
| `aitldr` | `v-aitldr` | AITLDR brand videos |
| `kiros` | `v-kiros` | Kiros client projects |
| `joy` | `v-beauty-and-joy` | Beauty & Joy brand |
| `ss` | `v-supportsignal` | SupportSignal client |

**Usage:**
```bash
# Both are equivalent
dam list appydave
dam list v-appydave

# Both are equivalent
dam s3-up joy project-name
dam s3-up v-beauty-and-joy project-name
```

---

## Troubleshooting

### "VIDEO_PROJECTS_ROOT not configured"

**Solution:**
```bash
dam init
```

### "Brand directory not found"

**Check available brands:**
```bash
dam list
```

**Verify config:**
```bash
cat ~/.dam-config
```

### "No project found matching 'b65'"

**Possible causes:**
1. Project doesn't exist in brand directory
2. Wrong brand specified

**Debug:**
```bash
# List all projects
dam list appydave

# Use full project name
dam s3-up appydave b65-full-project-name
```

### "AWS credentials not found"

**Solution 1:** Add to `.video-tools.env` in brand directory
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=ap-southeast-1
```

**Solution 2:** Configure AWS CLI
```bash
aws configure
```

### "Could not detect brand and project from current directory"

**Solution:** Either:
1. Provide explicit args: `dam s3-up appydave b65`
2. Ensure you're in project directory: `cd v-appydave/b65-project`

### Files Not Syncing (Always "Skipped")

**Cause:** Files haven't changed (MD5 hash matches)

**Solution:** If you need to force re-upload, delete from S3 first:
```bash
dam s3-cleanup appydave b65 --force
dam s3-up appydave b65
```

---

## Advanced Usage

### Auto-Detection from PWD

All S3 commands support auto-detection:

```bash
cd ~/dev/video-projects/v-appydave/b65-project

# These auto-detect brand and project
dam s3-up
dam s3-down
dam s3-status
```

### Dry-Run Mode

Preview actions without making changes:

```bash
dam s3-up appydave b65 --dry-run
dam s3-down voz boy-baker --dry-run
dam s3-cleanup-remote aitldr movie-posters --dry-run
dam s3-cleanup-local appydave b65 --dry-run
```

### Interactive Selection

When multiple projects match short name:

```bash
dam s3-up appydave b65
# Output:
# ⚠️  Multiple projects match 'b65':
#   1. b65-first-project
#   2. b65-second-project
# Select project (1-2):
```

---

## See Also

- **AWS Setup Guide:** [docs/usage/dam/aws-setup.md](./dam/aws-setup.md)
- **Architecture:** [docs/usage/dam/architecture.md](./dam/architecture.md)
- **Onboarding:** [docs/usage/dam/onboarding.md](./dam/onboarding.md)
- **Integration Brief:** [docs/dam-integration-plan.md](../dam-integration-plan.md)

---

**Last Updated:** 2025-11-08
