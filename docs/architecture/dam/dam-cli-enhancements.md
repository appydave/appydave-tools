# DAM CLI Enhancements

**Digital Asset Management - Command Line Tool Requirements**

This document specifies all CLI tool enhancements needed to support the DAM visualization dashboard, including new commands, naming consolidation, and architectural improvements.

---

## Overview

The DAM system requires CLI tool enhancements in three areas:

1. **Naming Consolidation** - Consistent naming across `exe/`, `bin/`, and `lib/`
2. **New Commands** - S3 scanning, project manifests, bulk operations
3. **Manifest Schema Changes** - Support for richer data structures

---

## 1. Naming Convention Consolidation

### Current State (Inconsistent)

**Problem:** Executables have inconsistent naming patterns:

| Current Name | Type | Issue |
|--------------|------|-------|
| `ad_config` | Configuration tool | Underscore, not dash |
| `dam` | Video asset management | Short, ambiguous (was `vat`) |
| `youtube_manager` | YouTube operations | Underscore, verbose |
| `gpt_context` | Context gathering | Underscore |
| `subtitle_processor` | Subtitle operations | Underscore |

**Three-Layer Confusion:**

```
exe/                    # Installed commands (what users run)
├── ad_config           # → `ad_config` command
├── dam                 # → `dam` command
└── (missing others)

bin/                    # Development scripts (internal)
├── configuration.rb    # → Implements ad_config
├── dam                 # → Implements dam
├── youtube_manager.rb  # → NOT in exe/ (missing!)
├── gpt_context.rb      # → NOT in exe/ (missing!)
└── ...

lib/appydave/tools/     # Library code
├── dam/                # → DAM module
├── configuration/      # → Configuration module
├── youtube_manager/    # → YouTube module
└── ...
```

**Issue:** Some tools missing from `exe/` (not installable via gem), naming inconsistency makes discoverability hard.

---

### Proposed Solution: Option B (Consistent Dash Naming)

**Naming Convention:**
- All commands prefixed with `ad-` (AppyDave namespace)
- Use dashes, not underscores
- Descriptive but concise

**New Command Structure:**

```
exe/                    # Installed commands
├── ad-dam              # Video asset management (rename from `dam`)
├── ad-config           # Configuration management (rename from `ad_config`)
├── ad-youtube          # YouTube operations (rename from `youtube_manager`)
├── ad-context          # GPT context gathering (rename from `gpt_context`)
├── ad-subtitles        # Subtitle processing (rename from `subtitle_processor`)
└── ad-prompts          # Prompt tools (rename from `prompt_tools`)

bin/                    # Development scripts (match exe/)
├── ad-dam              # DAM CLI implementation
├── ad-config           # Config CLI implementation
├── ad-youtube          # YouTube CLI implementation
├── ad-context          # Context CLI implementation
├── ad-subtitles        # Subtitles CLI implementation
└── ad-prompts          # Prompts CLI implementation

lib/appydave/tools/     # Library modules (no change)
├── dam/                # DAM module
├── configuration/      # Configuration module
├── youtube_manager/    # YouTube module (keep internal name)
├── gpt_context/        # GPT context module (keep internal name)
└── ...
```

**Migration Strategy:**

1. **Create new `exe/` wrappers** with `ad-` prefix
2. **Keep old names as symlinks** (backward compatibility)
3. **Deprecation warnings** when old names used
4. **Remove old names** in next major version (1.0.0)

**Example Deprecation Warning:**
```
$ ad_config -l
⚠️  WARNING: 'ad_config' is deprecated. Use 'ad-config' instead.
   This alias will be removed in v1.0.0

NAME               | EXISTS | PATH
...
```

---

### File Structure After Consolidation

```
exe/
├── ad-dam              # NEW: Primary DAM command
├── ad-config           # NEW: Renamed from ad_config
├── ad-youtube          # NEW: Replaces youtube_manager
├── ad-context          # NEW: Replaces gpt_context
├── ad-subtitles        # NEW: Replaces subtitle_processor
├── ad-prompts          # NEW: Replaces prompt_tools
│
├── dam                 # DEPRECATED: Symlink to ad-dam
├── ad_config           # DEPRECATED: Symlink to ad-config
└── (no other legacy commands in exe/ yet)

bin/
├── ad-dam              # Rename from dam
├── ad-config           # Rename from configuration.rb
├── ad-youtube          # Rename from youtube_manager.rb
├── ad-context          # Rename from gpt_context.rb
├── ad-subtitles        # Rename from subtitle_processor.rb
└── ad-prompts          # Rename from prompt_tools.rb

lib/appydave/tools/
├── dam/                # No change (internal module name)
├── configuration/      # No change
├── youtube_manager/    # No change
├── gpt_context/        # No change
└── subtitle_processor/ # No change
```

**Note:** `lib/` module names stay the same (internal implementation detail). Only user-facing `exe/` and `bin/` scripts are renamed.

---

## 2. New Commands

### 2.1 Brand-Level S3 Scan

**Command:** `ad-dam s3-scan <brand>`

**Purpose:** Query AWS S3 to discover actual files in staging, update manifest with real S3 data.

**Current Limitation:** Manifest only knows about local `s3-staging/` folder existence, not actual S3 contents.

**Behavior:**
```bash
# Scan single brand
ad-dam s3-scan appydave

# Scan all brands
ad-dam s3-scan all

# Dry run (show what would be scanned)
ad-dam s3-scan appydave --dry-run
```

**What It Does:**
1. Read brand configuration (AWS profile, S3 bucket, prefix)
2. Query AWS S3: `aws s3 ls s3://{bucket}/{prefix}/ --recursive`
3. For each project found in S3:
   - List files and sizes
   - Calculate total S3 storage per project
   - Detect if project exists locally
4. Update `{brand}/projects.json` manifest with S3 data

**Manifest Schema Change:**
```json
{
  "projects": [
    {
      "id": "b65-guy-monroe-marketing-plan",
      "storage": {
        "s3": {
          "exists": true,
          "last_scanned": "2025-11-18T12:00:00Z",
          "file_count": 2,
          "total_bytes": 125000000,
          "files": [
            {
              "key": "b65-guy-monroe-marketing-plan.mp4",
              "size": 125000000,
              "last_modified": "2025-11-17T15:30:00Z"
            },
            {
              "key": "b65-guy-monroe-marketing-plan.srt",
              "size": 50000,
              "last_modified": "2025-11-17T15:35:00Z"
            }
          ]
        }
      }
    }
  ]
}
```

**Usage in Dashboard:**
- Shows accurate "Jan uploaded files" status
- Displays S3 file count and size
- Warns if manifest is stale (last_scanned > 1 day ago)

---

### 2.2 Project-Level Manifest Generator

**Command:** `ad-dam project-manifest <brand> <project>`

**Purpose:** Generate detailed file tree for a single project.

**Output:** `{project}/.project-manifest.json`

**Behavior:**
```bash
# Generate manifest for specific project
ad-dam project-manifest appydave b64-bmad-claude-sdk

# Output location: /path/to/v-appydave/b64-bmad-claude-sdk/.project-manifest.json
```

**What It Does:**
1. Scan project directory recursively
2. Build tree structure with file counts and sizes per directory
3. Include subdirectories (e.g., `recordings/recordings-bmad-v6/`)
4. Write JSON to project root

**Manifest Schema:**
```json
{
  "project_id": "b64-bmad-claude-sdk",
  "brand": "appydave",
  "type": "flivideo",
  "generated_at": "2025-11-18T12:00:00Z",
  "tree": {
    "recordings": {
      "type": "directory",
      "file_count": 75,
      "total_bytes": 6800000000,
      "subdirectories": {
        "recordings-bmad-v6": {
          "type": "directory",
          "file_count": 26,
          "total_bytes": 1200000000
        }
      }
    },
    "assets": {
      "type": "directory",
      "file_count": 12,
      "total_bytes": 2000000,
      "subdirectories": {}
    },
    "s3-staging": {
      "type": "directory",
      "file_count": 2,
      "total_bytes": 125000000,
      "subdirectories": {}
    },
    "transcripts": {
      "type": "directory",
      "file_count": 3,
      "total_bytes": 500000,
      "subdirectories": {}
    }
  },
  "heavy_files": {
    "count": 75,
    "total_bytes": 6800000000,
    "extensions": [".mov", ".mp4"]
  },
  "light_files": {
    "count": 17,
    "total_bytes": 2500000,
    "extensions": [".srt", ".txt", ".png", ".jpg", ".md"]
  }
}
```

**Characteristics:**
- **Transient** - Not committed to git (add to `.gitignore`)
- **Optional** - Dashboard works without it
- **On-demand** - Only generated when needed
- **Future:** Button in Astro to trigger generation

**Gitignore Addition:**
```gitignore
# Project manifests (transient, regenerate on demand)
.project-manifest.json
```

---

### 2.3 Bulk Manifest Operations

**Command:** `ad-dam manifest all`

**Purpose:** Generate manifests for all brands in one command.

**Behavior:**
```bash
# Generate all brand manifests
ad-dam manifest all

# Equivalent to:
#   ad-dam manifest appydave
#   ad-dam manifest aitldr
#   ad-dam manifest voz
#   ad-dam manifest kiros
#   ad-dam manifest beauty-and-joy
#   ad-dam manifest supportsignal
```

**What It Does:**
1. Read `brands.json` configuration
2. Loop through all brands
3. Generate manifest for each
4. Show summary report

**Output:**
```
📊 Generating manifests for all brands...

✅ appydave (21 projects, 11.5 GB local, 400 GB SSD)
✅ aitldr (3 projects, 0.5 GB local, 0 GB SSD)
✅ voz (2 projects, 0.45 GB local, 0 GB SSD)
✅ kiros (0 projects)
✅ beauty-and-joy (0 projects)
✅ supportsignal (0 projects)

Summary:
  Total projects: 26
  Total local storage: 12.45 GB
  Total SSD storage: 400 GB
```

---

### 2.4 Combined Scan and Manifest

**Command:** `ad-dam refresh <brand>`

**Purpose:** Full refresh - regenerate manifest + S3 scan in one command.

**Behavior:**
```bash
# Full refresh for one brand
ad-dam refresh appydave

# Full refresh for all brands
ad-dam refresh all
```

**What It Does:**
1. Generate brand manifest (local + SSD scan)
2. Run S3 scan (query AWS for real S3 data)
3. Update manifest with combined data
4. Show summary

**Equivalent to:**
```bash
ad-dam manifest appydave && ad-dam s3-scan appydave
```

---

## 3. Existing Command Changes

### 3.1 Manifest Generator Enhancements

**File:** `lib/appydave/tools/dam/manifest_generator.rb`

**Changes Needed:**

1. **Add S3 scan integration**
   - After filesystem scan, optionally query S3
   - Merge S3 data into manifest
   - Add `last_scanned` timestamp

2. **Add project type detection for transcripts**
   - FliVideo: Check for `transcripts/` folder
   - Storyline: Check for `data/source/transcript.*`
   - Add `has_transcript` boolean to project entry

3. **Enhanced disk usage**
   - Add S3 storage totals
   - Separate heavy/light file breakdowns

**New Manifest Fields:**
```json
{
  "config": {
    "brand": "appydave",
    "local_base": "/path/to/v-appydave",
    "ssd_base": "/Volumes/T7/appydave",
    "s3_bucket": "appydave-video-projects",
    "s3_prefix": "staging/v-appydave/",
    "last_updated": "2025-11-18T12:00:00Z",
    "last_s3_scan": "2025-11-18T11:55:00Z",
    "disk_usage": {
      "local": { "total_gb": 11.55 },
      "ssd": { "total_gb": 400.24 },
      "s3": { "total_gb": 2.5 }
    }
  },
  "projects": [
    {
      "id": "b64-bmad-claude-sdk",
      "type": "flivideo",
      "has_transcript": true,
      "storage": {
        "local": { "exists": true, "..." },
        "s3": {
          "exists": true,
          "last_scanned": "2025-11-18T11:55:00Z",
          "file_count": 2,
          "total_bytes": 125000000
        },
        "ssd": { "exists": false }
      }
    }
  ]
}
```

---

### 3.2 Transcript Detection

**Add to ManifestGenerator:**

```ruby
def has_transcript?(project_path, project_type)
  case project_type
  when 'flivideo'
    # Check for transcripts/ folder
    transcripts_dir = File.join(project_path, 'transcripts')
    return true if Dir.exist?(transcripts_dir) && !Dir.empty?(transcripts_dir)

    # Legacy: check s3-staging/ for .srt files
    s3_staging = File.join(project_path, 's3-staging')
    return true if Dir.exist?(s3_staging) && Dir.glob(File.join(s3_staging, '*.srt')).any?

    false
  when 'storyline'
    # Check data/source/ for transcript files
    source_dir = File.join(project_path, 'data', 'source')
    return false unless Dir.exist?(source_dir)

    Dir.glob(File.join(source_dir, 'transcript.*')).any?
  else
    false
  end
end
```

---

## 4. Implementation Priority

### Phase 1: Naming Consolidation (Foundation)
**Priority:** High
**Blocks:** User confusion, gem discoverability

**Tasks:**
1. Create `exe/ad-dam`, `exe/ad-config`, etc. (new names)
2. Keep old names as symlinks (backward compatibility)
3. Add deprecation warnings
4. Update documentation

**Estimated Effort:** 1 day

---

### Phase 2: S3 Scan Command (Critical for Dashboard)
**Priority:** Critical
**Blocks:** Dashboard S3 sync detection

**Tasks:**
1. Implement `ad-dam s3-scan <brand>`
2. Implement `ad-dam s3-scan all`
3. Update manifest schema with S3 fields
4. Add `last_s3_scan` timestamp
5. Test with real S3 data

**Estimated Effort:** 2 days

---

### Phase 3: Bulk Operations (Convenience)
**Priority:** Medium
**Blocks:** Nothing, nice-to-have

**Tasks:**
1. Implement `ad-dam manifest all`
2. Implement `ad-dam refresh <brand>`
3. Implement `ad-dam refresh all`
4. Add progress reporting

**Estimated Effort:** 1 day

---

### Phase 4: Project-Level Manifests (Optional)
**Priority:** Low
**Blocks:** Detailed dashboard views

**Tasks:**
1. Implement `ad-dam project-manifest <brand> <project>`
2. Define tree structure schema
3. Add to `.gitignore`
4. Dashboard integration (read if exists)

**Estimated Effort:** 2 days

---

### Phase 5: Transcript Detection (Polish)
**Priority:** Low
**Blocks:** Dashboard transcript indicators

**Tasks:**
1. Add `has_transcript?` method to ManifestGenerator
2. Update manifest schema with `has_transcript` field
3. Handle both FliVideo and Storyline locations

**Estimated Effort:** 0.5 days

---

## 5. Testing Requirements

### Unit Tests

**New test files needed:**
- `spec/appydave/tools/dam/s3_scanner_spec.rb`
- `spec/appydave/tools/dam/project_manifest_generator_spec.rb`
- `spec/appydave/tools/dam/transcript_detector_spec.rb`

### Integration Tests

**Test scenarios:**
1. `ad-dam s3-scan` with mock AWS S3 (VCR cassette)
2. `ad-dam manifest all` across multiple brands
3. `ad-dam project-manifest` with complex directory tree
4. Transcript detection for FliVideo vs Storyline projects

### Manual Testing

**Windows/WSL (Jan's environment):**
- All renamed commands work (`ad-dam`, `ad-config`, etc.)
- S3 scan with Windows paths
- Manifest generation

**Mac (David's environment):**
- SSD detection with external drive
- S3 scan with multiple AWS profiles
- Bulk operations

---

## 6. Documentation Updates

**Files to update:**

1. **`docs/guides/tools/dam-usage.md`**
   - Add `s3-scan` examples
   - Add `project-manifest` examples
   - Add `manifest all`, `refresh` examples

2. **`docs/guides/tools/configuration.md`**
   - Update command name to `ad-config`
   - Add deprecation notice for `ad_config`

3. **`CLAUDE.md`** (root and appydave-tools)
   - Update all command examples
   - Add new commands to reference

4. **`README.md`**
   - Update quick start examples
   - Add new command summary

---

## 7. Migration Guide (for Users)

**For David:**
```bash
# Old way
dam list
ad_config -l
gpt_context -i '**/*.rb'

# New way (after v0.22.0)
ad-dam list
ad-config -l
ad-context -i '**/*.rb'

# Old commands still work (with warning) until v1.0.0
```

**For Jan (Windows/WSL):**
```bash
# Update gem
gem update appydave-tools

# Update bash aliases (if using git clone approach)
alias ad-dam="ruby ~/dev/ad/appydave-tools/bin/ad-dam"
alias ad-config="ruby ~/dev/ad/appydave-tools/bin/ad-config"
```

---

## 8. Breaking Changes (v1.0.0)

**When we remove old command names:**

- `dam` → removed (use `ad-dam`)
- `ad_config` → removed (use `ad-config`)
- `youtube_manager` → removed (use `ad-youtube`)
- `gpt_context` → removed (use `ad-context`)
- `subtitle_processor` → removed (use `ad-subtitles`)
- `prompt_tools` → removed (use `ad-prompts`)

**Migration path:**
1. v0.22.0 - Add new names, deprecation warnings
2. v0.23.0-0.99.0 - Both names work, warnings continue
3. v1.0.0 - Remove old names (major version bump)

---

**Last updated:** 2025-11-18
