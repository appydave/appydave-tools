# VAT (Video Asset Tools) - Usage Guide

**VAT** is a unified CLI for managing video projects across local storage, S3 cloud collaboration, and SSD archival storage.

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
vat init

# List available brands
vat list

# List projects for a brand
vat list appydave

# Upload files to S3 for collaboration
vat s3-up appydave b65

# Download files from S3
vat s3-down appydave b65

# Check sync status
vat s3-status appydave b65
```

---

## Installation

### Install Gem

```bash
gem install appydave-tools
```

### Initialize Configuration

```bash
vat init
```

This creates `~/.vat-config` pointing to your video projects directory.

### AWS CLI Setup

VAT uses the AWS CLI for S3 operations. Install and configure:

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure AWS credentials (if not using .video-tools.env)
aws configure
```

---

## Configuration

### System Configuration (`~/.vat-config`)

Created by `vat init`:

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

#### `vat init`
Initialize VAT configuration.

```bash
vat init
```

#### `vat help [command]`
Show help information.

```bash
vat help                # Overview
vat help s3-up          # Command-specific help
vat help brands         # List available brands
vat help workflows      # Explain FliVideo vs Storyline
```

### Project Discovery

#### `vat list [--summary] [brand] [pattern]`
List brands and projects.

**Mode 1: Brands only (clean list)**
```bash
vat list
# Output: Brands: appydave, aitldr, joy, kiros, ss, voz
```

**Mode 2: Brands with project counts (summary)**
```bash
vat list --summary
# Output:
# appydave: 27 projects
# voz: 3 projects
# aitldr: 2 projects
```

**Mode 3: Specific brand's projects**
```bash
vat list appydave
# Output: Lists all AppyDave projects
```

**Mode 3b: Pattern matching**
```bash
vat list appydave 'b6*'
# Output: Lists b60, b61, b62...b69 projects
```

### S3 Sync Commands

#### `vat s3-up [brand] [project] [--dry-run]`
Upload files from local `s3-staging/` to S3.

```bash
# With explicit args
vat s3-up appydave b65

# Auto-detect from current directory
cd ~/dev/video-projects/v-appydave/b65-project
vat s3-up

# Dry-run (preview without uploading)
vat s3-up appydave b65 --dry-run
```

**What it does:**
- Uploads files from `project/s3-staging/` to S3
- Skips files already in sync (MD5 comparison)
- Shows progress and summary

#### `vat s3-down [brand] [project] [--dry-run]`
Download files from S3 to local `s3-staging/`.

```bash
# With explicit args
vat s3-down appydave b65

# Auto-detect
cd ~/dev/video-projects/v-appydave/b65-project
vat s3-down

# Dry-run
vat s3-down voz boy-baker --dry-run
```

**What it does:**
- Downloads files from S3 to `project/s3-staging/`
- Skips files already in sync
- Creates `s3-staging/` if it doesn't exist

#### `vat s3-status [brand] [project]`
Check sync status between local and S3.

```bash
vat s3-status appydave b65
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

#### `vat s3-cleanup [brand] [project] [--dry-run] [--force]`
Delete S3 staging files for a project.

```bash
# Preview what would be deleted
vat s3-cleanup appydave b65 --dry-run

# Delete with confirmation prompt
vat s3-cleanup appydave b65

# Delete without confirmation
vat s3-cleanup appydave b65 --force
```

**Warning:** This deletes files from S3. Use `--dry-run` first!

### Project Management

#### `vat manifest [brand]`
Generate project manifest for a brand.

```bash
vat manifest appydave
```

#### `vat archive [brand] [project] [--dry-run]`
Archive project to SSD backup.

```bash
vat archive appydave b63
vat archive appydave b63 --dry-run
```

#### `vat sync-ssd [brand]`
Sync light files from SSD for brand.

```bash
vat sync-ssd appydave
```

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
vat s3-up appydave b65
```

**Jan (downloads from S3):**
```bash
cd ~/dev/video-projects/v-appydave/b65-guy-monroe

# Check what's available
vat s3-status appydave b65

# Download files
vat s3-down appydave b65

# Edit files in s3-staging/
# ...

# Upload edited files back
vat s3-up appydave b65
```

### Example 2: Pattern Matching

```bash
# List all b60-series projects
vat list appydave 'b6*'

# List all completed projects
vat list appydave 'b[1-5]*'
```

### Example 3: Cleanup After Project Completion

```bash
# Archive to SSD
vat archive appydave b63

# Verify sync status
vat s3-status appydave b63

# Clean up S3 (saves storage costs)
vat s3-cleanup appydave b63 --dry-run  # Preview
vat s3-cleanup appydave b63 --force     # Execute
```

---

## Workflows

### FliVideo Workflow (AppyDave Brand)

**Pattern:** Sequential, chapter-based recording

**Project Naming:** `b65-guy-monroe-marketing-plan`

**Short Name Support:**
```bash
vat s3-up appydave b65  # Expands to full project name
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
vat s3-up voz boy-baker  # Use full project name
```

**Typical Flow:**
1. Write script
2. Record A-roll (main footage)
3. Upload raw footage to S3
4. Download edited version from S3
5. Publish and archive

---

## Brand Shortcuts

VAT supports brand shortcuts for faster typing:

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
vat list appydave
vat list v-appydave

# Both are equivalent
vat s3-up joy project-name
vat s3-up v-beauty-and-joy project-name
```

---

## Troubleshooting

### "VIDEO_PROJECTS_ROOT not configured"

**Solution:**
```bash
vat init
```

### "Brand directory not found"

**Check available brands:**
```bash
vat list
```

**Verify config:**
```bash
cat ~/.vat-config
```

### "No project found matching 'b65'"

**Possible causes:**
1. Project doesn't exist in brand directory
2. Wrong brand specified

**Debug:**
```bash
# List all projects
vat list appydave

# Use full project name
vat s3-up appydave b65-full-project-name
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
1. Provide explicit args: `vat s3-up appydave b65`
2. Ensure you're in project directory: `cd v-appydave/b65-project`

### Files Not Syncing (Always "Skipped")

**Cause:** Files haven't changed (MD5 hash matches)

**Solution:** If you need to force re-upload, delete from S3 first:
```bash
vat s3-cleanup appydave b65 --force
vat s3-up appydave b65
```

---

## Advanced Usage

### Auto-Detection from PWD

All S3 commands support auto-detection:

```bash
cd ~/dev/video-projects/v-appydave/b65-project

# These auto-detect brand and project
vat s3-up
vat s3-down
vat s3-status
```

### Dry-Run Mode

Preview actions without making changes:

```bash
vat s3-up appydave b65 --dry-run
vat s3-down voz boy-baker --dry-run
vat s3-cleanup aitldr movie-posters --dry-run
```

### Interactive Selection

When multiple projects match short name:

```bash
vat s3-up appydave b65
# Output:
# ⚠️  Multiple projects match 'b65':
#   1. b65-first-project
#   2. b65-second-project
# Select project (1-2):
```

---

## See Also

- **AWS Setup Guide:** [docs/usage/vat/aws-setup.md](./vat/aws-setup.md)
- **Architecture:** [docs/usage/vat/architecture.md](./vat/architecture.md)
- **Onboarding:** [docs/usage/vat/onboarding.md](./vat/onboarding.md)
- **Integration Brief:** [docs/vat-integration-plan.md](../vat-integration-plan.md)

---

**Last Updated:** 2025-11-08
