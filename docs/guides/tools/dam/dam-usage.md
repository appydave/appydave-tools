# DAM (Digital Asset Management) - Usage Guide

**DAM** is a unified CLI for managing video projects across local storage, S3 cloud collaboration, and SSD archival storage.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
- [Archive Range Pattern](#archive-range-pattern)
- [Examples](#examples)
- [Workflows](#workflows)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Install appydave-tools gem
gem install appydave-tools

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

### AWS CLI Setup

DAM uses named AWS profiles for S3 operations. Install and configure:

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure a named profile (matching brands.json aws.profile)
aws configure --profile david-appydave
```

---

## Configuration

DAM is configured via two JSON files in `~/.config/appydave/`:

### System Settings (`~/.config/appydave/settings.json`)

```json
{
  "video-projects-root": "/Users/yourname/dev/video-projects",
  "ecamm-recording-folder": "/Users/yourname/ecamm",
  "download-folder": "/Users/yourname/Downloads",
  "download-image-folder": "/Users/yourname/Downloads/images",
  "current_user": "david",
  "aliases-output-path": "~/.oh-my-zsh/custom/aliases-jump.zsh"
}
```

The `video-projects-root` key is required — it points to the root containing all brand folders (`v-appydave/`, `v-voz/`, etc.).

### Brands Config (`~/.config/appydave/brands.json`)

Defines each brand's AWS settings, storage paths, team members, and workflow type:

```json
{
  "brands": {
    "appydave": {
      "name": "AppyDave",
      "shortcut": "ad",
      "type": "owned",
      "youtube_channels": ["appydave"],
      "team": ["david", "jan"],
      "git_remote": "git@github.com:appydave-video-projects/v-appydave.git",
      "locations": {
        "video_projects": "/Users/yourname/dev/video-projects/v-appydave",
        "ssd_backup": "/Volumes/T7/youtube-PUBLISHED/appydave"
      },
      "aws": {
        "profile": "david-appydave",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-appydave/"
      },
      "settings": {
        "s3_cleanup_days": 90
      }
    }
  },
  "users": {
    "david": {
      "name": "David Cruwys",
      "email": "david@appydave.com",
      "role": "owner",
      "default_aws_profile": "david-appydave"
    }
  }
}
```

To create or edit these files:

```bash
ad_config -c   # Create missing config files (safe — won't overwrite)
ad_config -e   # Open configs in VS Code
ad_config -l   # List all config locations
```

---

## Commands

### Project Discovery

#### `dam list [brand] [pattern]`
List brands and projects.

```bash
dam list                    # List all configured brands
dam list appydave           # List all projects for a brand
dam list appydave 'b6*'     # Pattern matching (b60–b69)
dam list appydave 'b[1-5]*' # All b10–b59 projects
```

### Status & Monitoring

#### `dam status [brand] [project]`
Show unified status for a project or brand (local, S3, SSD, git).

```bash
dam status appydave           # Brand-level summary
dam status appydave b65       # Project-level detail
dam status                    # Auto-detect from current directory
```

**Output (project level):**
```
📊 Status: v-appydave/b65-guy-monroe-marketing-plan

Storage:
  📁 Local: ✓ exists (flat structure)
     Heavy files: no
     Light files: yes

  ☁️  S3 Staging: ✓ exists
     Local staging files: 3

  💾 SSD Backup: ✓ exists
     Path: b65-guy-monroe-marketing-plan

Git:
  🌿 Branch: main
  📡 Remote: git@github.com:appydave-video-projects/v-appydave.git
  ↕️  Status: Clean working directory
  🔄 Sync: Up to date
```

#### `dam ssd-status [brand] [--all]`
Check whether the SSD is mounted and available for each brand.

```bash
dam ssd-status appydave    # Check one brand's SSD
dam ssd-status --all       # Check all brands
```

### S3 Sync Commands

#### `dam s3-up [brand] [project] [--dry-run]`
Upload files from local `s3-staging/` to S3.

```bash
dam s3-up appydave b65           # Upload
dam s3-up appydave b65 --dry-run # Preview without uploading
dam s3-up                        # Auto-detect from current directory
```

Skips files already in sync (MD5 comparison). Shows progress and summary.

#### `dam s3-down [brand] [project] [--dry-run]`
Download files from S3 to local `s3-staging/`.

```bash
dam s3-down appydave b65
dam s3-down voz boy-baker --dry-run
dam s3-down                       # Auto-detect
```

Creates `s3-staging/` if it doesn't exist. Skips files already in sync.

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
dam s3-cleanup-remote appydave b65 --dry-run   # Preview
dam s3-cleanup-remote appydave b65 --force     # Execute
```

#### `dam s3-cleanup-local [brand] [project] [--dry-run] [--force]`
Delete local `s3-staging/` files for a project.

```bash
dam s3-cleanup-local appydave b65 --dry-run
dam s3-cleanup-local appydave b65 --force
```

#### `dam s3-discover [brand] [project] [--shareable]`
List files currently in S3 for a project.

```bash
dam s3-discover appydave b65              # List S3 files
dam s3-discover appydave b65 --shareable  # Generate pre-signed URLs
```

#### `dam s3-share [brand] [project] [file] [--expires 7d] [--download]`
Generate a time-limited pre-signed URL for sharing a specific S3 file.

```bash
dam s3-share appydave b65 intro.mp4
dam s3-share appydave b65 intro.mp4 --expires 3d --download
```

### Archive & SSD Commands

#### `dam archive [brand] [project] [--dry-run] [--force]`
Archive completed project to SSD backup location.

```bash
dam archive appydave b63 --dry-run    # Preview
dam archive appydave b63              # Copy to SSD, keep local
dam archive appydave b63 --force      # Copy to SSD, delete local (frees disk)
```

Verifies SSD is mounted before archiving. Shows size before copying.

#### `dam sync-ssd [brand] [--dry-run]`
Restore light files (subtitles, images, docs) from SSD to local for archived projects.

**Important:** Does NOT sync heavy video files (MP4, MOV, etc.).

```bash
dam sync-ssd appydave             # Sync all AppyDave projects from SSD
dam sync-ssd appydave --dry-run   # Preview
dam sync-ssd voz
```

**What it syncs:**
- Includes: `.srt`, `.vtt`, `.txt`, `.md`, `.jpg`, `.jpeg`, `.png`, `.webp`, `.json`, `.yml`
- Excludes: `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`

**Requirements:**
- `projects.json` manifest must exist (`dam manifest <brand>` first)
- SSD must be mounted

Restored files are placed in `archived/{range}/{project}/` — see [Archive Range Pattern](#archive-range-pattern).

#### `dam manifest [brand] [--all] [--verbose]`
Generate `projects.json` for a brand — tracks all projects across local + SSD storage.

```bash
dam manifest appydave          # Generate for one brand
dam manifest --all             # Generate for all brands
dam manifest appydave --verbose # Show validation warnings
```

**Output example:**
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

### Git Repository Commands

#### `dam repo-status [brand] [--all]`
```bash
dam repo-status appydave
dam repo-status --all
```

#### `dam repo-sync [brand] [--all]`
Pull git updates. Skips brands with uncommitted changes.

```bash
dam repo-sync appydave
dam repo-sync --all
```

#### `dam repo-push [brand] [project]`
Push changes. Optional project validation against manifest.

```bash
dam repo-push appydave
dam repo-push appydave b65
```

### Help

```bash
dam help                # Overview
dam help s3-up          # Command-specific help
dam help brands         # List available brands
dam help workflows      # FliVideo vs Storyline explanation
```

---

## Archive Range Pattern

When projects are archived to SSD or restored locally via `sync-ssd`, they are organized into **50-number range folders** with letter prefixes.

**Rule:** `(number / 50) * 50` → range start; range end = start + 49

| Project ID | Range Folder |
|------------|-------------|
| `b00`–`b49` | `b00-b49` |
| `b50`–`b99` | `b50-b99` |
| `a00`–`a49` | `a00-a49` |
| `a50`–`a99` | `a50-a99` |
| Non-matching | `000-099` (legacy fallback) |

**SSD structure:**
```
/Volumes/T7/youtube-PUBLISHED/appydave/
├── b00-b49/
│   └── b40-some-project/
└── b50-b99/
    └── b65-guy-monroe-marketing-plan/
```

**Local restored structure (after `sync-ssd`):**
```
~/dev/video-projects/v-appydave/
├── b70-active-project/            ← flat = still active
└── archived/
    ├── b00-b49/
    │   └── b40-some-project/      ← light files only
    └── b50-b99/
        └── b65-guy-monroe.../     ← light files only (no .mp4/.mov)
```

The manifest distinguishes between `flat` (active) and `archived` (restored) local structure.

---

## Examples

### Example 1: Collaboration Workflow (David → Jan)

**David (uploads to S3):**
```bash
cd ~/dev/video-projects/v-appydave/b65-guy-monroe
mkdir -p s3-staging
cp ~/Downloads/intro-footage.mp4 s3-staging/

dam s3-up appydave b65
```

**Jan (downloads from S3):**
```bash
dam s3-status appydave b65   # Check what's available
dam s3-down appydave b65     # Download files
# ... edit files in s3-staging/ ...
dam s3-up appydave b65       # Upload edited files back
```

### Example 2: Cleanup After Project Completion

```bash
dam archive appydave b63 --dry-run      # Preview
dam archive appydave b63                # Copy to SSD

dam s3-cleanup-remote appydave b63 --dry-run   # Preview S3 cleanup
dam s3-cleanup-remote appydave b63 --force     # Delete from S3
```

### Example 3: Restore Light Files from Cold Storage

```bash
dam manifest appydave               # Refresh manifest first
dam ssd-status appydave             # Confirm SSD is mounted
dam sync-ssd appydave --dry-run     # Preview what will be restored
dam sync-ssd appydave               # Restore subtitles, images, docs
```

---

## Workflows

### FliVideo Workflow (AppyDave, AITLDR)

**Pattern:** Sequential, chapter-based recording

**Project Naming:** `b65-guy-monroe-marketing-plan`

**Short Name Support:**
```bash
dam s3-up appydave b65   # Expands to full project name
```

**Typical Flow:**
1. Record chapters sequentially
2. Upload raw footage to S3 for collaboration
3. Download edited chapters from S3
4. Publish final video
5. Archive to SSD (`dam archive appydave b65 --force`)

### Storyline Workflow (VOZ, Kiros)

**Pattern:** Script-first, narrative-driven content

**Project Naming:** `boy-baker`, `the-point`

**Full Name Required:**
```bash
dam s3-up voz boy-baker   # Full project name required
```

---

## Brand Shortcuts

| Shortcut | Full Name | Type |
|----------|-----------|------|
| `appydave` (or `ad`) | `v-appydave` | owned |
| `voz` | `v-voz` | client |
| `aitldr` | `v-aitldr` | owned |
| `kiros` | `v-kiros` | client |
| `joy` | `v-beauty-and-joy` | owned |
| `ss` | `v-supportsignal` | client |

---

## Command Safety Reference

| Command | Dry-Run | Force Required | Action |
|---------|---------|----------------|--------|
| `s3-up` | ✅ | No | Upload to S3 |
| `s3-down` | ✅ | No | Download from S3 |
| `s3-cleanup-remote` | ✅ | Yes | Delete from S3 |
| `s3-cleanup-local` | ✅ | No | Delete local staging |
| `archive` | ✅ | Optional (deletes local) | Copy to SSD |
| `sync-ssd` | ✅ | No | Restore light files from SSD |
| `list` | — | — | Read-only |
| `manifest` | — | — | Generates JSON |
| `s3-status` | — | — | Read-only |

---

## Troubleshooting

### "video-projects-root not configured"

```bash
ad_config -e   # Edit settings.json and add video-projects-root
```

### "Brand directory not found"

```bash
dam list                   # See configured brands
ad_config -p brands        # Print brands.json
```

### "No project found matching 'b65'"

```bash
dam list appydave          # See all projects for brand
dam list appydave 'b6*'    # Check b60–b69 range
```

### "AWS credentials not found"

```bash
aws configure --profile david-appydave   # Set up named profile
```

Profile name must match `aws.profile` in `brands.json`.

### "SSD not mounted"

```bash
dam ssd-status --all       # Check all brands
# Connect the external SSD, then retry
```

### "projects.json not found" (sync-ssd fails)

```bash
dam manifest appydave      # Generate manifest first
```

### Files Not Syncing (Always "Skipped")

Files with matching MD5 are skipped. To force re-upload:

```bash
dam s3-cleanup-remote appydave b65 --force
dam s3-up appydave b65
```

### "Could not detect brand and project from current directory"

Either provide explicit args or ensure you're inside the project directory:

```bash
dam s3-up appydave b65
# or
cd ~/dev/video-projects/v-appydave/b65-project && dam s3-up
```

---

**Last Updated:** 2026-04-08

**See Also:**
- [DAM Data Model](../../architecture/dam/dam-data-model.md)
- [DAM Vision](../../architecture/dam/dam-vision.md)
- [Configuration Guide](../configuration-setup.md)
