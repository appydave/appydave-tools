# PRD: Git Integration & Unified Status

**Status:** Draft
**Author:** David Cruwys
**Created:** 2025-11-10
**Last Updated:** 2025-11-10

---

## Overview

DAM (Digital Asset Management) currently manages video projects across three storage layers: local disk, S3 cloud collaboration, and SSD archival. However, video projects also exist as git repositories for version control of light files (subtitles, images, markdown, metadata). Currently, git operations are handled by separate shell scripts (`status-all.sh`, `sync-all.sh`, `clone-all.sh`) outside the DAM system.

This PRD proposes integrating git repository management into DAM, creating a unified interface for managing both storage layers (heavy video files + light versioned files) from a single command-line tool.

### Current State

**Dual Management Systems:**
- **DAM layer** - Manages heavy files (video) via S3/SSD sync commands
- **Git layer** - Manages light files (SRT, images, docs) via separate shell scripts

**Problem:** Two separate workflows, no unified view of project state across both layers

**Example current workflow:**
```bash
# Check video file sync
dam s3-status appydave b65

# Separately check git status
cd /video-projects/v-appydave/b65-project
git status

# Separately sync git repo
cd /video-projects/v-appydave
git pull
```

### Proposed State

**Unified DAM Interface:**
```bash
# Single command shows everything: local, S3, SSD, and git status
dam status appydave b65

# Git operations integrated into DAM
dam repo-status appydave     # Check all projects
dam repo-sync appydave        # Pull updates for all projects
dam repo-push appydave b65    # Push specific project
```

---

## Goals

### Primary Goals

1. **Unified Status View** - Single command shows project state across all layers (local, S3, SSD, git)
2. **Git Integration** - Manage git operations through DAM commands (status, sync, push)
3. **Self-Healing Config** - Automatically infer and populate git remote URLs when missing
4. **S3 Tracking** - Add S3 staging to manifest for complete storage visibility

### Secondary Goals

5. **Dynamic Brand Discovery** - Eliminate hardcoded brand lists, use brands.json
6. **Inferred Behavior** - Status command shows relevant info based on what exists
7. **Consistent Interface** - Git commands follow same patterns as S3 commands

### Non-Goals

- **File-level git operations** - Not implementing `dam git commit/add/etc` (use git directly)
- **Complex git workflows** - Not handling branches, rebasing, merging (use git directly)
- **GitHub API integration** - Not creating issues, PRs, releases

---

## User Stories

### Story 1: Check Project Status (Primary Use Case)

**As a content creator,**
**I want to see complete project status in one command,**
**So I don't have to check multiple tools to understand project state.**

**Current workflow:**
```bash
# Check S3 sync status
dam s3-status appydave b65

# Check SSD archive status
cd /video-projects/v-appydave && ls b65* && cd /Volumes/T7/youtube-PUBLISHED/appydave && ls b65*

# Check git status
cd /video-projects/v-appydave/b65-project
git status
```

**Proposed workflow:**
```bash
dam status appydave b65
```

**Output:**
```
📊 Status: v-appydave/b65-guy-monroe-marketing-plan

Storage:
  📁 Local: ✓ exists (flat structure)
     Heavy files: no
     Light files: yes (5 SRT, 12 images, 3 docs)

  ☁️  S3 Staging: ✓ exists
     Files in sync: 3
     Need upload: 2 (15.3 MB)
     Need download: 0

  💾 SSD Backup: ✓ exists
     Last archived: 2025-11-08

Git:
  🌿 Branch: main
  📡 Remote: git@github.com:klueless-io/v-appydave.git
  ↕️  Status: 2 files modified, 1 untracked
  🔄 Sync: Behind by 0 commits
```

**Acceptance Criteria:**
- Shows local/S3/SSD/git status in single view
- Displays only relevant sections (skips S3 if no s3-staging folder)
- Color-coded indicators (✓/✗/⚠️)
- Human-readable file counts and sizes

---

### Story 2: Sync All Brand Repos (Team Collaboration)

**As a team member,**
**I want to pull updates for all brand repositories at once,**
**So I can start work with latest changes across all projects.**

**Current workflow:**
```bash
cd /video-projects
./v-shared/sync-all.sh  # Hardcoded REPOS array
```

**Proposed workflow:**
```bash
dam repo-sync appydave
```

**Output:**
```
🔄 Syncing git repositories for appydave...

📦 v-appydave
   ✓ Already up to date

Summary:
  Repos checked: 1
  Updated: 0
  Already current: 1
  Errors: 0
```

**Acceptance Criteria:**
- Uses brands.json (no hardcoded lists)
- Runs `git pull` on brand directory
- Shows summary of changes
- Handles errors gracefully (uncommitted changes, merge conflicts)

---

### Story 3: Self-Healing Git Remote (Bootstrap Scenario)

**As a new team member,**
**I want git remote URLs auto-populated,**
**So I don't have to manually configure repos.**

**Scenario:**
```bash
# brands.json initially has: "git_remote": null
dam repo-status appydave

# DAM automatically:
# 1. Detects git_remote is null
# 2. Runs: cd /video-projects/v-appydave && git remote get-url origin
# 3. Finds: git@github.com:klueless-io/v-appydave.git
# 4. Updates brands.json: "git_remote": "git@github.com:klueless-io/v-appydave.git"
# 5. Continues with status command
```

**Acceptance Criteria:**
- Infers remote URL from existing git repo
- Auto-saves to brands.json (with backup)
- Gracefully handles non-git folders (leaves null)
- Only runs once (subsequent calls use cached value)

---

### Story 4: Push Specific Project Changes

**As a content creator,**
**I want to push changes for a specific project,**
**So I don't accidentally push unrelated work.**

**Current workflow:**
```bash
cd /video-projects/v-appydave/b65-project
git add .
git commit -m "Add subtitles for chapter 3"
git push
```

**Proposed workflow:**
```bash
# Add and commit done with git (not DAM)
cd /video-projects/v-appydave/b65-project
git add *.srt && git commit -m "Add subtitles for chapter 3"

# Push via DAM (validates project exists in manifest)
dam repo-push appydave b65
```

**Acceptance Criteria:**
- Resolves project short name (b65 → b65-guy-monroe-marketing-plan)
- Validates project in manifest
- Runs `git push` from project directory
- Shows push result (commits pushed, branch tracking)

---

## Requirements

### Functional Requirements

#### FR1: Git Remote Configuration

**FR1.1** - Add `git_remote` field to brands.json schema
- Type: string or null
- Optional field (can be null for non-git brands)
- Example: `"git_remote": "git@github.com:klueless-io/v-appydave.git"`

**FR1.2** - Self-healing git remote inference
- If `git_remote` is null, attempt to infer from git command
- Command: `git -C <brand_path> remote get-url origin`
- Auto-save inferred value to brands.json (with backup)
- Gracefully handle non-git folders (leave null, no error)

**FR1.3** - Update brands.json documentation
- Add `git_remote` to example configs
- Document self-healing behavior
- Explain null vs URL states

#### FR2: S3 Staging Tracking in Manifest

**FR2.1** - Add S3 storage to manifest schema
```json
{
  "id": "b65-guy-monroe-marketing-plan",
  "storage": {
    "local": { "exists": true, "structure": "flat", ... },
    "ssd": { "exists": false, "path": null },
    "s3": { "exists": true }
  }
}
```

**FR2.2** - Detect S3 staging presence in manifest_generator
- Check if `s3-staging/` directory exists
- Update `s3: { exists: true/false }` in manifest

**FR2.3** - Update manifest when S3 commands run
- `dam s3-up` → sets `s3.exists = true` after upload
- `dam s3-down` → sets `s3.exists = true` after download
- `dam s3-cleanup-remote` → sets `s3.exists = false` after cleanup

#### FR3: Unified Status Command

**FR3.1** - Create `dam status [brand] [project]` command
- Shows local, S3, SSD, and git status in unified view
- Auto-detects brand/project from PWD if not provided
- Inferred display (only shows relevant sections)

**FR3.2** - Storage status section
- Local: exists, structure type, file counts (heavy/light)
- S3: exists, sync status, files needing upload/download
- SSD: exists, last archived date

**FR3.3** - Git status section (live query, not stored)
- Branch name
- Remote URL
- Modified/untracked file counts
- Commits ahead/behind remote
- Skip section if not a git repo

**FR3.4** - Inferred behavior
- If no S3 staging folder → skip S3 section
- If not a git repo → skip git section
- If no SSD path configured → skip SSD section

#### FR4: Git Repository Commands

**FR4.1** - `dam repo-status [brand]` - Check git status for brand repos
- Shows git status for brand directory
- Option: `--all` to show status for all brands
- Uses git_remote from brands.json (triggers self-healing if null)

**FR4.2** - `dam repo-sync [brand]` - Pull updates for brand repos
- Runs `git pull` on brand directory
- Option: `--all` to sync all brands
- Handles errors (uncommitted changes, merge conflicts)
- Summary: repos checked, updated, errors

**FR4.3** - `dam repo-push [brand] [project]` - Push project changes
- Resolves project short name (b65 → full name)
- Validates project exists in manifest
- Runs `git push` from brand directory
- Shows commits pushed and branch tracking

**FR4.4** - Dynamic brand discovery
- Use brands.json to get list of brands (no hardcoded arrays)
- Automatically supports new brands added to config

### Non-Functional Requirements

**NFR1: Performance**
- Status command completes in < 2 seconds for single project
- repo-sync for all brands completes in < 10 seconds

**NFR2: Error Handling**
- Graceful failures (git not installed, repo not found, network errors)
- Clear error messages with remediation steps
- No data loss on config updates (backup system)

**NFR3: Backward Compatibility**
- Existing commands continue to work unchanged
- brands.json without git_remote field still works (self-healing)
- Manifest without s3 field still works (regenerate manifest)

**NFR4: Documentation**
- Update usage.md with new commands
- Update test plan with Phase 4 tests
- Add examples to PRD and usage guide

---

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        DAM CLI                               │
│  (dam status, dam repo-status, dam repo-sync, dam repo-push) │
└─────────────────────────────────────────────────────────────┘
                            │
                            ├── Uses brands.json (git_remote)
                            ├── Uses manifest (local/S3/SSD state)
                            └── Queries git (live status, not stored)

┌─────────────┬─────────────┬─────────────┬─────────────┐
│   Local     │     S3      │    SSD      │     Git     │
│  Storage    │  Staging    │   Archive   │   Repos     │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Data Model Changes

#### brands.json (add git_remote field)

**Before:**
```json
{
  "brands": [
    {
      "key": "appydave",
      "shortcut": "ad",
      "name": "AppyDave",
      "youtube_handle": "@appydave",
      "locations": {
        "video_projects": "/Users/davidcruwys/dev/video-projects/v-appydave",
        "ssd_backup": "/Volumes/T7/youtube-PUBLISHED/appydave"
      }
    }
  ]
}
```

**After:**
```json
{
  "brands": [
    {
      "key": "appydave",
      "shortcut": "ad",
      "name": "AppyDave",
      "youtube_handle": "@appydave",
      "git_remote": "git@github.com:klueless-io/v-appydave.git",
      "locations": {
        "video_projects": "/Users/davidcruwys/dev/video-projects/v-appydave",
        "ssd_backup": "/Volumes/T7/youtube-PUBLISHED/appydave"
      }
    },
    {
      "key": "voz",
      "shortcut": "voz",
      "name": "VOZ",
      "youtube_handle": "@voz",
      "git_remote": null,
      "locations": {
        "video_projects": "/Users/davidcruwys/dev/video-projects/v-voz",
        "ssd_backup": "NOT-SET"
      }
    }
  ]
}
```

**Notes:**
- `git_remote` is optional (can be null)
- Self-healing: If null, DAM attempts to infer and populate
- Non-git brands: Leave as null (valid state)

#### projects.json (add S3 staging field)

**Before:**
```json
{
  "id": "b65-guy-monroe-marketing-plan",
  "storage": {
    "local": {
      "exists": true,
      "structure": "flat",
      "has_heavy_files": false,
      "has_light_files": true
    },
    "ssd": {
      "exists": false,
      "path": null
    }
  }
}
```

**After:**
```json
{
  "id": "b65-guy-monroe-marketing-plan",
  "storage": {
    "local": {
      "exists": true,
      "structure": "flat",
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

**Notes:**
- `s3.exists` is boolean (true/false)
- Updated by manifest_generator (checks for s3-staging/ directory)
- Updated by S3 commands (s3-up, s3-down, s3-cleanup-remote)

### Self-Healing Git Remote Logic

**Flow:**
```ruby
def get_git_remote(brand_info)
  # 1. Check brands.json
  return brand_info.git_remote if brand_info.git_remote.present?

  # 2. Attempt inference
  brand_path = Config.brand_path(brand_info.key)
  remote_url = infer_git_remote(brand_path)

  # 3. Auto-save if inferred
  if remote_url
    update_brand_git_remote(brand_info.key, remote_url)
    return remote_url
  end

  # 4. Non-git folder (leave null)
  nil
end

def infer_git_remote(brand_path)
  result = `git -C #{brand_path} remote get-url origin 2>/dev/null`.strip
  result.empty? ? nil : result
rescue
  nil
end

def update_brand_git_remote(brand_key, remote_url)
  brands_config = Appydave::Tools::Configuration::Config.brands
  brand = brands_config.brands.find { |b| b.key == brand_key }
  brand.git_remote = remote_url
  brands_config.save # Uses backup system
end
```

### Git Status Query (Live, Not Stored)

**Why live query?**
- Git status changes frequently (commits, pulls, edits)
- Storing in manifest causes staleness issues
- Query is fast (< 100ms for typical repo)

**Implementation:**
```ruby
def git_status(brand_path)
  return nil unless git_repo?(brand_path)

  {
    branch: current_branch(brand_path),
    remote: remote_url(brand_path),
    modified_files: modified_count(brand_path),
    untracked_files: untracked_count(brand_path),
    ahead: commits_ahead(brand_path),
    behind: commits_behind(brand_path)
  }
end

def current_branch(path)
  `git -C #{path} rev-parse --abbrev-ref HEAD`.strip
end

def commits_ahead(path)
  `git -C #{path} rev-list --count @{upstream}..HEAD 2>/dev/null`.strip.to_i
end

def commits_behind(path)
  `git -C #{path} rev-list --count HEAD..@{upstream} 2>/dev/null`.strip.to_i
end
```

### Unified Status Command Design

**Command:** `dam status [brand] [project]`

**Output format:**
```
📊 Status: v-appydave/b65-guy-monroe-marketing-plan

Storage:
  📁 Local: ✓ exists (flat structure)
     Heavy files: no
     Light files: yes (5 SRT, 12 images, 3 docs)

  ☁️  S3 Staging: ✓ exists
     Files in sync: 3
     Need upload: 2 (15.3 MB)
     Need download: 0

  💾 SSD Backup: ✓ exists
     Last archived: 2025-11-08

Git:
  🌿 Branch: main
  📡 Remote: git@github.com:klueless-io/v-appydave.git
  ↕️  Status: 2 files modified, 1 untracked
  🔄 Sync: Behind by 0 commits
```

**Inferred display logic:**
```ruby
def show_status(brand, project)
  manifest = load_manifest(brand)
  project_entry = manifest.projects.find { |p| p.id == project }

  # Always show local (required)
  show_local_status(project_entry)

  # Show S3 only if s3-staging exists
  show_s3_status(brand, project) if project_entry.storage.s3.exists

  # Show SSD only if ssd_backup configured
  show_ssd_status(project_entry) if brand_info.locations.ssd_backup != "NOT-SET"

  # Show git only if git repo detected
  show_git_status(brand_path) if git_repo?(brand_path)
end
```

---

## Implementation Plan

### Phase 1: Configuration & Manifest (Foundation)

**Tasks:**
1. Add `git_remote` field to Brand model in Configuration module
2. Update brands.json schema documentation
3. Implement self-healing git remote inference logic
4. Add S3 storage field to Manifest schema
5. Update ManifestGenerator to detect S3 staging
6. Add tests for config and manifest changes

**Deliverables:**
- Updated brands.json with git_remote field
- Updated manifest with S3 tracking
- Self-healing git remote logic working
- 100% test coverage for new code

**Estimated effort:** 4-6 hours

---

### Phase 2: Unified Status Command

**Tasks:**
1. Create `DamStatus` class
2. Implement storage status (local/S3/SSD)
3. Implement git status query (live)
4. Implement inferred display logic
5. Add CLI command `dam status`
6. Add tests and documentation

**Deliverables:**
- `dam status [brand] [project]` command working
- Unified output showing all layers
- Inferred behavior (skips irrelevant sections)
- Usage documentation updated

**Estimated effort:** 6-8 hours

---

### Phase 3: Git Repository Commands

**Tasks:**
1. Create `RepoStatus` class
2. Implement `dam repo-status [brand]` command
3. Create `RepoSync` class
4. Implement `dam repo-sync [brand]` command
5. Create `RepoPush` class
6. Implement `dam repo-push [brand] [project]` command
7. Add dynamic brand discovery (use brands.json)
8. Add tests and documentation

**Deliverables:**
- `dam repo-status`, `dam repo-sync`, `dam repo-push` commands working
- Dynamic brand discovery (no hardcoded lists)
- Error handling for git failures
- Usage documentation updated

**Estimated effort:** 8-10 hours

---

### Phase 4: Testing & Documentation

**Tasks:**
1. Add Phase 4 to test plan
2. Update usage.md with new commands
3. Create integration tests
4. Test self-healing behavior
5. Test error scenarios
6. Performance testing (status command < 2s)

**Deliverables:**
- Complete test coverage
- Updated documentation
- Performance benchmarks
- User acceptance testing complete

**Estimated effort:** 4-6 hours

---

**Total estimated effort:** 22-30 hours

---

## Success Criteria

### Must Have (MVP)

1. ✅ **Unified status command works** - Shows local/S3/SSD/git in single view
2. ✅ **Git remote self-healing works** - Auto-populates from git repo if null
3. ✅ **S3 tracking in manifest** - projects.json includes S3 staging state
4. ✅ **repo-status command works** - Shows git status for brand repos
5. ✅ **repo-sync command works** - Pulls updates for brand repos
6. ✅ **Dynamic brand discovery** - No hardcoded brand lists

### Should Have

7. ✅ **repo-push command works** - Pushes specific project changes
8. ✅ **Inferred display** - Status skips irrelevant sections
9. ✅ **Error handling** - Graceful failures with clear messages
10. ✅ **Documentation complete** - Usage guide, test plan, PRD updated

### Could Have (Future)

11. ⏳ **repo-clone command** - Clone missing brand repos
12. ⏳ **Batch operations** - `dam repo-sync --all` for all brands
13. ⏳ **Status filtering** - `dam status --show-modified` (only changed files)
14. ⏳ **Git hooks integration** - Auto-update manifest on git push

---

## Open Questions

1. **Should `dam status` default to current project (PWD) or require explicit args?**
   - Option A: Auto-detect from PWD (like s3-up/s3-down)
   - Option B: Require explicit brand/project args
   - **Recommendation:** Option A (consistent with existing commands)

2. **Should repo-push auto-detect uncommitted changes and warn?**
   - Option A: Warn if uncommitted changes detected
   - Option B: Let git handle it (git push won't do anything)
   - **Recommendation:** Option A (better UX)

3. **Should manifest track S3 file-level details (file names, sizes)?**
   - Option A: Boolean only (`s3: { exists: true }`)
   - Option B: File inventory (`s3: { exists: true, files: [...] }`)
   - **Recommendation:** Option A (simpler, avoids staleness)

4. **Should git_remote support multiple remotes (origin, upstream)?**
   - Option A: Single remote only (origin)
   - Option B: Array of remotes
   - **Recommendation:** Option A (YAGNI - simple is better)

5. **What happens if git remote inference finds SSH URL but user needs HTTPS?**
   - Option A: Store whatever is found, let user manually edit
   - Option B: Prompt user to choose SSH vs HTTPS
   - **Recommendation:** Option A (user can edit brands.json if needed)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Git not installed on system | High | Check for git binary, show clear error with install instructions |
| Git remote inference fails | Medium | Leave git_remote as null, document manual config process |
| Manifest becomes stale (S3 state outdated) | Medium | Update manifest on S3 commands, regenerate if inconsistent |
| Performance (git status slow for large repos) | Low | Use `--porcelain` flag for faster parsing, timeout after 5s |
| Breaking changes to brands.json | High | Use backup system, backward compatibility (null git_remote valid) |

---

## Dependencies

- **Ruby 3.4.2** - Already in use
- **Git CLI** - Must be installed on system
- **brands.json** - Must have valid configuration
- **Manifest system** - Must be generated (`dam manifest`)

---

## Alternatives Considered

### Alternative 1: Keep git scripts separate (status quo)

**Pros:**
- No new code to write
- Simple shell scripts, easy to understand

**Cons:**
- Two separate tools (DAM + git scripts)
- No unified status view
- Hardcoded brand lists (maintenance burden)

**Decision:** Rejected - Integration provides better UX

### Alternative 2: Store git status in manifest

**Pros:**
- Faster status command (no live queries)
- All data in one place (manifest)

**Cons:**
- Staleness problem (git changes frequently)
- Manifest updates required after every git operation
- Complex synchronization logic

**Decision:** Rejected - Live queries are fast enough, staleness not worth it

### Alternative 3: Use GitHub API instead of git CLI

**Pros:**
- No git binary required
- Can check status remotely

**Cons:**
- Requires network connection
- Requires GitHub authentication
- Only works for GitHub (not GitLab, Bitbucket, self-hosted)
- Overkill for simple status checks

**Decision:** Rejected - git CLI is simpler and more universal

---

## Appendix: Example Workflows

### Workflow 1: Morning Sync Routine

**Scenario:** Team member starts work, needs to sync all repos

```bash
# Pull updates for all brands
dam repo-sync appydave

# Check unified status for active project
dam status appydave b65

# Work on project...
cd /video-projects/v-appydave/b65-guy-monroe-marketing-plan
# Edit subtitles, add images, etc.

# Commit changes
git add *.srt images/
git commit -m "Add chapter 3 subtitles and thumbnails"

# Push via DAM
dam repo-push appydave b65
```

### Workflow 2: Collaboration Handoff

**Scenario:** David uploads video files to S3 for Jan to edit

```bash
# David: Upload raw footage
cd /video-projects/v-appydave/b65-guy-monroe-marketing-plan
mkdir -p s3-staging
cp ~/ecamm/chapter-3-raw.mp4 s3-staging/
dam s3-up appydave b65

# David: Push subtitle updates
git add *.srt && git commit -m "Add chapter 3 script"
dam repo-push appydave b65

# Jan: Pull git updates and S3 files
dam repo-sync appydave
dam s3-down appydave b65

# Jan: Check what needs work
dam status appydave b65
```

### Workflow 3: Project Archive & Cleanup

**Scenario:** Complete project, archive to SSD, clean up S3

```bash
# Check final status
dam status appydave b63

# Archive to SSD
dam archive appydave b63

# Push final git state
dam repo-push appydave b63

# Clean up S3 (save storage costs)
dam s3-cleanup-remote appydave b63 --force
```

---

**End of PRD**
