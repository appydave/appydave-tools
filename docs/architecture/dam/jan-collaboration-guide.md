# DAM Collaboration Guide - Working with David on Video Projects

This guide explains how to collaborate on video projects B70 and B64 using DAM (Digital Asset Management).

## Overview

DAM uses a **hybrid storage approach** for video collaboration:

- **Git Repository**: Small files (metadata, manifests, scripts, thumbnails)
- **S3 Staging**: Large files (video recordings, exports, audio) - 90-day collaboration window

## Prerequisites

### 1. Install AppyDave Tools

```bash
gem install appydave-tools
```

### 2. Configure AWS Credentials

You need a `.video-tools.env` file in the `v-appydave` directory:

```bash
# Create configuration file
cd ~/dev/video-projects/v-appydave
nano .video-tools.env
```

Add the following (David will provide actual values):

```bash
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_REGION=ap-southeast-2
S3_BUCKET=appydave-video-staging

# SSD Backup Path (optional for you)
SSD_BACKUP_PATH=/Volumes/T7/video-projects
```

**Important**: Never commit this file to Git (it's already in `.gitignore`)

### 3. Verify Setup

```bash
# Navigate to video projects
cd ~/dev/video-projects/v-appydave

# Test DAM
dam list appydave

# Check if you can see B70 and B64
dam list appydave 'b6*'
dam list appydave 'b7*'
```

## Workflow: Getting Files from David

When David tells you B70 or B64 is ready for you to work on:

### Step 1: Pull Git Updates (Metadata)

```bash
# This gets manifests, scripts, thumbnails, small files
dam repo-sync appydave
```

**What this does**: Pulls latest changes from the Git repository

### Step 2: Discover What's Available in S3

```bash
# See what files David uploaded
dam s3-discover appydave b70
dam s3-discover appydave b64
```

**What this does**: Lists all files available in S3 staging area

### Step 3: Download Large Files (Dry-Run First)

```bash
# Preview what will be downloaded (doesn't actually download)
dam s3-down appydave b70 --dry-run

# If it looks correct, download for real
dam s3-down appydave b70
```

Repeat for B64:

```bash
dam s3-down appydave b64 --dry-run
dam s3-down appydave b64
```

**What this does**:
- Downloads large video files from S3 to your local `s3-staging/` folder
- Uses MD5 checksums - only downloads changed files
- Skips files you already have

### Step 4: Verify Everything Downloaded

```bash
# Check unified status (local + S3 + Git)
dam status appydave b70
dam status appydave b64

# Or just check S3 sync status
dam s3-status appydave b70
dam s3-status appydave b64
```

**What this shows**:
- Files in sync between local and S3
- Files missing locally
- Files that differ

### Step 5: Start Working

Your files are now in:
```
~/dev/video-projects/v-appydave/b70-ito.ai-doubled-productivity/s3-staging/
~/dev/video-projects/v-appydave/b64-bmad-claude-sdk/s3-staging/
```

## Workflow: Sending Edited Files Back to David

After you've finished editing B70 or B64:

### Step 1: Upload Large Files to S3 (Dry-Run First)

```bash
# Preview what will be uploaded
dam s3-up appydave b70 --dry-run

# If it looks correct, upload for real
dam s3-up appydave b70
```

Repeat for B64 if needed:

```bash
dam s3-up appydave b64 --dry-run
dam s3-up appydave b64
```

**What this does**: Uploads your edited video files to S3 for David to download

### Step 2: Commit Git Changes (Metadata)

```bash
# Check what changed
dam repo-status appydave

# Commit and push changes
dam repo-push appydave b70
```

**You'll be prompted for a commit message**. Examples:
- "B70 - completed rough cut"
- "B64 - finished color grading"
- "B70 - exported final version"

**What this does**:
- Commits any manifest changes, thumbnails, or small files
- Pushes to Git repository for David

### Step 3: Verify Upload

```bash
# Check that S3 upload succeeded
dam s3-status appydave b70
dam s3-status appydave b64
```

### Step 4: Notify David

Let David know the project is ready for review.

## Command Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `dam repo-sync appydave` | Pull Git updates | Start of work session |
| `dam s3-discover appydave b70` | See files in S3 | Check what David uploaded |
| `dam s3-down appydave b70` | Download from S3 | Get large video files |
| `dam s3-down appydave b70 --dry-run` | Preview download | Check before downloading |
| `dam s3-up appydave b70` | Upload to S3 | Send edited files to David |
| `dam s3-up appydave b70 --dry-run` | Preview upload | Check before uploading |
| `dam s3-status appydave b70` | Check S3 sync | Verify transfers worked |
| `dam repo-status appydave` | Check Git status | See what changed locally |
| `dam repo-push appydave b70` | Commit & push Git | After making changes |
| `dam status appydave b70` | Unified status | See everything (local/S3/Git) |
| `dam list appydave` | List all projects | See available projects |

## Typical Session Flow

### Starting Work (Getting Files)
```bash
# 1. Pull metadata
dam repo-sync appydave

# 2. Download video files
dam s3-down appydave b70 --dry-run
dam s3-down appydave b70

# 3. Verify
dam status appydave b70

# 4. Start editing files in s3-staging/
```

### Finishing Work (Sending Files Back)
```bash
# 1. Upload edited files
dam s3-up appydave b70 --dry-run
dam s3-up appydave b70

# 2. Commit metadata changes
dam repo-push appydave b70
# Enter commit message when prompted

# 3. Verify
dam s3-status appydave b70

# 4. Notify David
```

## What Goes Where?

### Git Repository (Small Files)
✅ Tracked in Git:
- Manifests (file lists, checksums)
- Scripts and storylines
- Thumbnails and small images
- Project metadata
- Configuration files

❌ NOT in Git:
- Large video files (.mp4, .mov)
- Raw recordings
- High-resolution exports
- Files in `s3-staging/` directories

### S3 Staging (Large Files - 90 Days)
✅ In S3:
- Video recordings (.mp4, .mov, .avi)
- Audio files
- Large exports
- High-resolution images
- Anything over ~10MB

## Understanding File Locations

When you download B70, files go to:
```
~/dev/video-projects/v-appydave/b70-ito.ai-doubled-productivity/
├── README.md                  (Git - metadata)
├── manifest.json              (Git - file inventory)
├── s3-staging/                (NOT in Git)
│   ├── raw-recording.mp4      (Large file from S3)
│   ├── edited-version.mp4     (Your edited file)
│   └── audio-track.wav        (Audio file)
└── assets/                    (Git - small images)
    └── thumbnail.jpg
```

## Troubleshooting

### "Could not find project"
- Run `dam list appydave` to see available projects
- Make sure you're using the correct short name (e.g., `b70`, not `b70-ito.ai-doubled-productivity`)

### "AWS credentials not configured"
- Check that `.video-tools.env` exists in `v-appydave` directory
- Verify credentials are correct (ask David)
- Don't commit this file to Git

### "Files already in sync"
- This is good! It means no new changes to download/upload
- Use `dam s3-status appydave b70` to verify

### Downloads are slow
- Large video files take time (2-10GB projects)
- First download transfers everything
- Subsequent syncs only transfer changed files (much faster)

### "Permission denied" on S3
- Contact David - your AWS credentials may need updating
- Check that AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are correct

## File Size Expectations

Typical project sizes:
- **B70**: ~5-8GB (video recordings, exports)
- **B64**: ~3-6GB (video recordings, exports)

First download/upload will transfer full size. Subsequent syncs only transfer changes.

## Questions?

Contact David if you run into issues or need clarification on any steps.

---

**Last Updated**: 2025-11-18
