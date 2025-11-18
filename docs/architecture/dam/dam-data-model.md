# DAM Data Model

**Digital Asset Management - Entity Schema and Data Sources**

This document defines the complete data model for the DAM (Digital Asset Management) system, including all entities, their relationships, data sources, and how state is inferred from the filesystem and configuration.

---

## Overview

The DAM system manages video projects across multiple brands, team members, and storage locations. The data model is **inferred from filesystem structure and configuration** rather than stored in a database, making it git-friendly and deployment-agnostic.

**Key Principle:** All state is calculated at runtime from:
- Filesystem structure (project folders, file presence)
- Configuration files (`brands.json`, `settings.json`, `channels.json`)
- Generated manifests (`projects.json` per brand)

---

## Entity Hierarchy

```
System (root)
├── Brands (6 brands: appydave, aitldr, voz, kiros, beauty-and-joy, supportsignal)
│   ├── Projects (varies by brand)
│   │   ├── Storage Locations (local, S3, SSD)
│   │   │   └── Files (recordings, assets, s3-staging, etc.)
│   │   └── Metadata (type, structure, disk usage)
│   └── Team Members (brand-specific access)
└── Users (cross-brand: david, jan, joy, vasilios, ronnie)
```

---

## Core Entities

### 1. Brand

**Definition:** A content brand or client with its own video projects, team, and storage configuration.

**Data Source:** `~/.config/appydave/brands.json`

**Schema:**
```json
{
  "name": "AppyDave",
  "shortcut": "ad",
  "type": "owned|client",
  "youtube_channels": ["appydave"],
  "team": ["david", "jan"],
  "git_remote": "git@github.com:appydave-video-projects/v-appydave.git",
  "locations": {
    "video_projects": "/Users/davidcruwys/dev/video-projects/v-appydave",
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
```

**Properties:**
| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `name` | string | Display name | `"AppyDave"` |
| `shortcut` | string | Short identifier | `"ad"` |
| `type` | enum | `"owned"` or `"client"` | `"owned"` |
| `youtube_channels` | array | YouTube channel codes | `["appydave"]` |
| `team` | array | User keys with access | `["david", "jan"]` |
| `git_remote` | string | Git repository URL | `"git@github.com:..."` |
| `locations.video_projects` | string | Local project root path | `"/Users/.../v-appydave"` |
| `locations.ssd_backup` | string | SSD backup base path | `"/Volumes/T7/..."` |
| `aws.profile` | string | AWS CLI profile name | `"david-appydave"` |
| `aws.s3_bucket` | string | S3 bucket name | `"appydave-video-projects"` |
| `aws.s3_prefix` | string | S3 key prefix | `"staging/v-appydave/"` |
| `settings.s3_cleanup_days` | number | S3 retention policy | `90` |

**Current Brands:**
- `appydave` (owned, David + Jan)
- `aitldr` (owned, David + Jan)
- `voz` (client, Vasilios)
- `beauty-and-joy` (owned, Joy + David)
- `kiros` (client, Ronnie)
- `supportsignal` (client, Ronnie)

---

### 2. User

**Definition:** A person with access to one or more brands.

**Data Source:** `~/.config/appydave/brands.json` (users section)

**Schema:**
```json
{
  "name": "David Cruwys",
  "email": "david@appydave.com",
  "role": "owner|team_member|client",
  "default_aws_profile": "david-appydave"
}
```

**Properties:**
| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `name` | string | Full name | `"David Cruwys"` |
| `email` | string | Email address | `"david@appydave.com"` |
| `role` | enum | User type | `"owner"`, `"team_member"`, `"client"` |
| `default_aws_profile` | string | Default AWS profile | `"david-appydave"` |

**Current Users:**
- `david` - Owner (all brands)
- `jan` - Team member (appydave, aitldr)
- `joy` - Team member (beauty-and-joy)
- `vasilios` - Client (voz)
- `ronnie` - Client (kiros, supportsignal)

---

### 3. Project

**Definition:** A video project belonging to a brand, with content spread across local, S3, and SSD storage.

**Data Source:**
- Primary: `{brand}/projects.json` (generated manifest)
- Filesystem: Project folders in `{brand}/`, `{brand}/archived/`, SSD ranges

**Schema:**
```json
{
  "id": "b64-bmad-claude-sdk",
  "type": "flivideo|storyline|general",
  "storage": {
    "local": {
      "exists": true,
      "structure": "flat|archived|null",
      "has_heavy_files": false,
      "has_light_files": true
    },
    "s3": {
      "exists": true
    },
    "ssd": {
      "exists": false,
      "path": null
    }
  }
}
```

**Properties:**
| Property | Type | Description | Inferred From |
|----------|------|-------------|---------------|
| `id` | string | Project folder name | Filesystem |
| `type` | enum | Project workflow type | Folder structure + naming |
| `storage.local.exists` | boolean | Exists in local filesystem | `Dir.exist?` |
| `storage.local.structure` | enum | Storage structure type | Path location |
| `storage.local.has_heavy_files` | boolean | Contains video files | `*.{mp4,mov,avi,mkv,webm}` |
| `storage.local.has_light_files` | boolean | Contains text/assets | `*.{srt,jpg,png,md,json}` |
| `storage.s3.exists` | boolean | Has `s3-staging` folder | `Dir.exist?(s3-staging)` |
| `storage.ssd.exists` | boolean | Found on SSD | SSD filesystem scan |
| `storage.ssd.path` | string | SSD relative path | Project ID (or range path) |

**Project Types:**
| Type | Detection Logic | Example |
|------|-----------------|---------|
| `flivideo` | Pattern: `[a-z]\d{2}-name` | `b64-bmad-claude-sdk` |
| `storyline` | Has `data/storyline.json` | `boy-baker` |
| `general` | Everything else | `-01-25` |

**Local Structure Types:**
| Structure | Location | Purpose |
|-----------|----------|---------|
| `flat` | `{brand}/{project-id}/` | Active projects |
| `archived` | `{brand}/archived/{range}/{project-id}/` | Restored/archived projects |
| `null` | Not on local | SSD-only or missing |

---

### 4. Storage Location

**Definition:** A physical or cloud location where project files reside.

**Three Storage Types:**

#### A. Local Storage
- **Path:** `{brand}/` or `{brand}/archived/{range}/`
- **Purpose:** Active development, recording, editing
- **Characteristics:**
  - Git repository (light files only)
  - Heavy files gitignored
  - Structured folders (recordings/, assets/, s3-staging/, etc.)

#### B. S3 Staging Storage
- **Path (virtual):** `s3://{bucket}/{prefix}/{project-id}/`
- **Detection:** Presence of `{project-local}/s3-staging/` folder
- **Purpose:** Short-term collaboration (90 days)
- **Characteristics:**
  - Transient (auto-cleanup after 90 days)
  - Enables David ↔ Jan file exchange
  - Shareable links for clients

#### C. SSD Backup Storage
- **Path:** `/Volumes/T7/{brand}/{range}/{project-id}/`
- **Purpose:** Long-term archive
- **Characteristics:**
  - Cold storage (external drive)
  - Organized in range folders (`b00-b49`, `b50-b99`)
  - Not always mounted/available

**SSD Availability Detection:**
```ruby
ssd_available = Dir.exist?(brand_info.locations.ssd_backup)
```

---

### 5. File Categories

**Definition:** Files within a project, categorized by type and gitignore status.

**Heavy Files** (gitignored):
- `*.mp4`, `*.mov`, `*.avi`, `*.mkv`, `*.webm`
- Detection: `Dir.glob(File.join(dir, '*.{mp4,mov,...}'))`

**Light Files** (git-tracked):
- `*.srt`, `*.vtt` (subtitles)
- `*.jpg`, `*.png` (thumbnails, assets)
- `*.md`, `*.txt` (documentation)
- `*.json`, `*.yml` (metadata)
- Detection: `Dir.glob(File.join(dir, '**/*.{srt,vtt,...}'))`

---

## Data Sources Hierarchy

### Configuration Files (Read Once, Cached)

```
~/.config/appydave/
├── brands.json          # Brand definitions, team, AWS config
├── settings.json        # Global paths (video-projects-root, etc.)
├── channels.json        # YouTube channel metadata (optional)
└── youtube-automation.json  # Automation workflows (out of scope)
```

### Generated Manifests (Regenerated on Demand)

#### Brand-Level Manifests

```
{video-projects-root}/
├── v-appydave/
│   └── projects.json    # Brand manifest (auto-generated)
├── v-aitldr/
│   └── projects.json
└── v-voz/
    └── projects.json
```

**Command:** `dam manifest <brand>` or `dam manifest all`

**What It Contains:**
- All projects for the brand
- Storage locations (local/S3/SSD)
- Disk usage totals
- Project types

**Regeneration Triggers:**
- Explicit: `dam manifest <brand>` command
- Explicit: `dam refresh <brand>` (manifest + S3 scan)
- Implicit: None (must be manually triggered)

#### Project-Level Manifests (Optional/Transient)

```
{video-projects-root}/v-appydave/
├── b64-bmad-claude-sdk/
│   ├── .project-manifest.json    # Project manifest (optional, transient)
│   ├── recordings/
│   ├── assets/
│   └── s3-staging/
├── b65-guy-monroe-marketing-plan/
│   ├── .project-manifest.json    # Project manifest (optional, transient)
│   └── ...
└── b70-ito.ai-doubled-productivity/
    ├── .project-manifest.json    # Project manifest (optional, transient)
    └── ...
```

**Command:** `dam project-manifest <brand> <project>`

**What It Contains:**
- Detailed file tree (directory structure)
- File counts per directory
- Subdirectory breakdown (e.g., `recordings/recordings-bmad-v6/`)
- Heavy/light file summaries

**Characteristics:**
- **Transient** - Not required, regenerate on demand
- **Git-ignored** - Too volatile to commit (add to `.gitignore`)
- **Optional** - Dashboard works without it (falls back to brand manifest booleans)
- **On-demand** - Only generate when needed for detailed project view

**Regeneration Triggers:**
- Explicit: `dam project-manifest <brand> <project>` command
- Explicit: Dashboard button (future - local dev only)
- Implicit: None

---

## State Inference Rules

### Project Existence

| Condition | Result |
|-----------|--------|
| `Dir.exist?("{brand}/{id}")` | `storage.local.exists = true, structure = "flat"` |
| `Dir.exist?("{brand}/archived/{range}/{id}")` | `storage.local.exists = true, structure = "archived"` |
| Neither exists | `storage.local.exists = false, structure = null` |

### S3 Staging Status

| Condition | Result |
|-----------|--------|
| `Dir.exist?("{project}/s3-staging")` | `storage.s3.exists = true` |
| Otherwise | `storage.s3.exists = false` |

**Note:** This detects the **local marker folder**, not actual S3 contents. The `s3-staging/` folder is used to stage files before S3 upload.

### SSD Backup Status

**Search Order:**
1. Flat: `{ssd_base}/{project-id}/`
2. Calculated range: `{ssd_base}/{range}/{project-id}/`
3. Exhaustive search: All range folders in `{ssd_base}/*/`

**Result:** `storage.ssd.exists = true` if found anywhere

### Sync State (Inferred)

| Local | S3 | SSD | Interpretation |
|-------|----|----|----------------|
| ✅ | ✅ | ❌ | **Active collaboration** - David & Jan working |
| ✅ | ❌ | ❌ | **Local only** - Not shared yet |
| ❌ | ✅ | ❌ | **Remote only** - Need to download |
| ✅ | ❌ | ✅ | **Archived** - Published, local for reference |
| ❌ | ❌ | ✅ | **Cold storage** - Historical archive |
| ✅ | ✅ | ✅ | **Fully backed up** - All locations |

---

## Disk Usage Calculation

**Calculated Fields in Manifest:**
```json
{
  "disk_usage": {
    "local": {
      "total_bytes": 12399975489,
      "total_mb": 11825.54,
      "total_gb": 11.55
    },
    "ssd": {
      "total_bytes": 429749225514,
      "total_mb": 409840.8,
      "total_gb": 400.24
    }
  }
}
```

**Calculation Method:**
- Walk entire directory tree
- Sum `File.size(file)` for all files
- Convert bytes → MB, GB
- Performed at manifest generation time (not real-time)

---

## Relationships

### Brand → Projects (1:N)
- One brand has many projects
- Projects identified by folder name
- Manifest lists all projects for brand

### Brand → Users (M:N)
- Brands have `team` array
- Users can belong to multiple brands
- Example: David is on all brands, Jan is on appydave + aitldr

### Project → Storage Locations (1:3)
- Each project can exist in:
  - Local (0 or 1)
  - S3 (0 or 1)
  - SSD (0 or 1)
- Valid combinations: Any subset of {local, s3, ssd}

### User → AWS Profile (N:1)
- Each user has `default_aws_profile`
- Multiple users can share same AWS profile (e.g., Jan uses david-appydave)
- AWS profiles defined in `~/.aws/credentials` (outside DAM scope)

---

## Data Flow

### Manifest Generation
```
1. Load brands.json (configuration)
2. Scan local filesystem ({brand}/, {brand}/archived/*/)
3. Scan SSD filesystem (if available)
4. Detect S3 staging (local folder presence)
5. Calculate disk usage (recursive file size sum)
6. Generate projects.json (per brand)
```

### S3 Sync Detection
```
1. Check for local s3-staging folder
2. List S3 bucket contents (AWS API call)
3. Compare MD5 hashes or timestamps
4. Determine sync status (in-sync, needs-upload, needs-download)
```

**Note:** MD5 comparison is used by S3 sync tools but not currently exposed in the manifest.

---

## Missing / Out of Scope

**What's NOT in the current data model:**

1. **S3 actual contents** - Manifest only tracks local `s3-staging/` folder existence
2. **File-level metadata** - No per-file tracking (size, MD5, timestamps)
3. **FliVideo chapter structure** - Not exposed at manifest level
4. **Storyline scripts** - Not parsed into manifest
5. **Transcripts** - Not indexed (though important for workflows)
6. **YouTube publish status** - No link between project and published video
7. **Project state machine** - No "recording", "editing", "published" status
8. **Team permissions** - No granular access control (inferred from brand team list)

---

## Future Enhancements

**Potential additions to data model:**

1. **S3 actual sync status** - Query AWS API for real S3 contents, not just local folder
2. **File manifest** - Per-project file listing with sizes, MD5s, timestamps
3. **Transcript index** - Parse and index all `.srt` files
4. **Chapter structure** - FliVideo recording organization
5. **Project metadata** - Title, description, recording date
6. **State tracking** - Workflow status (planned → recording → editing → published)

---

**Last updated**: 2025-11-18
