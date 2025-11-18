# DAM Visualization Requirements

**Digital Asset Management - Web-Based Dashboard Specification**

This document defines the requirements for a web-based visual dashboard to manage video projects across brands, focusing on David ↔ Jan collaboration via S3 staging.

---

## Project Scope

**What This Is:**
- **DAM-specific visualization** - NOT a unified tool dashboard
- **Web-based** (Astro static site) - NOT terminal/CLI UI
- **S3 collaboration focus** - Short/medium-term staging, not long-term archival
- **Two-view system** - Brand overview + Project detail

**What This Is NOT:**
- Configuration management UI (config is foundational, not visualized)
- Unified dashboard for all tools (GPT Context, YouTube Manager, Subtitles are separate)
- Database-driven application (reads JSON manifests only)
- Replacement for CLI commands (provides clipboard buttons instead)

---

## User Personas

### David Cruwys (Primary User)
- **Role:** Owner, content creator, system architect
- **Environment:** Mac, code version (git clone)
- **Brands:** All 6 brands (appydave, aitldr, voz, kiros, beauty-and-joy, supportsignal)
- **Primary Workflows:**
  - Switch between projects quickly (b64 → b70 → SupportSignal)
  - Check S3 sync status before/after collaboration
  - Know what's on SSD when drive is unplugged
  - Find project codes for video cross-references
- **Pain Points:**
  - Remembering CLI commands (`dam s3-up appydave b65` vs `dam s3-down ...`)
  - Switching context between brands/projects
  - Knowing if Jan has uploaded changes to S3

### Jan (Support Team)
- **Role:** Team member, image/animation support
- **Environment:** Windows/WSL, gem version (`gem install appydave-tools`)
- **Brands:** Primarily appydave, aitldr (David assigns work)
- **Primary Workflows:**
  - Download project from S3 for editing
  - Upload edited files back to S3
  - See what projects are available
- **Pain Points:**
  - Getting lost in text-heavy help screens
  - Remembering complex command syntax
  - Understanding project status at a glance

### Mary (Future User)
- **Role:** Content creator (AI-TLDR)
- **Environment:** Non-technical (NO Ruby setup)
- **Access Method:** Public Cloudflare Pages deployment
- **Requirement:** View-only access to project status

### Vasilios & Ronnie (Client Users)
- **Role:** Clients (VOZ, Kiros, SupportSignal)
- **Environment:** Non-technical
- **Access Method:** Public Cloudflare Pages deployment
- **Requirement:** View project status (no access restrictions for MVP)
- **Note:** Not locked down per-brand (can see all projects)

---

## Core Use Cases

### Use Case 1: Daily Check-In (David)
**Goal:** "What's happening across my projects?"

**Scenario:**
- David opens dashboard in morning
- Sees brand overview: appydave (21), aitldr (3), voz (2)
- Notices b65 has S3 changes (Jan uploaded edits)
- Clicks b65 → Detail view
- Clicks "Sync from S3" button → Copies `dam s3-down appydave b65` to clipboard
- Runs command in terminal

**Data Needed:**
- Brand list with project counts
- Per-project S3 status indicator
- Quick-action clipboard buttons

---

### Use Case 2: Project Context Switching (David)
**Goal:** "I'm recording b64, but need to reference b57"

**Scenario:**
- David is mid-recording, mentions "see video b57 for details"
- Opens dashboard, searches for "b57"
- Sees b57 is archived (SSD only, not local)
- Notes: Can reference transcript/assets, but not video files
- Continues recording with correct info

**Data Needed:**
- Search/filter projects
- Storage location status (local/S3/SSD)
- Visual indication of what's available

---

### Use Case 3: Collaboration Workflow (David → Jan)
**Goal:** "Upload b70 for Jan to edit animations"

**Scenario:**
- David finishes recording b70
- Opens dashboard → b70 detail view
- Clicks "Upload to S3" → Copies `dam s3-up appydave b70`
- Runs command in terminal
- Sends Jan a message: "b70 ready for editing"

---

### Use Case 4: Collaboration Workflow (Jan → David)
**Goal:** "Download b70, edit, upload back"

**Scenario:**
- Jan receives message from David
- Opens dashboard → appydave brand
- Sees b70 with "S3 available" indicator
- Clicks "Download from S3" → Copies `dam s3-down appydave b70`
- Runs command in WSL terminal
- Edits animations
- Clicks "Upload to S3" → Copies `dam s3-up appydave b70`
- Uploads changes
- Notifies David

**Data Needed:**
- S3 availability indicator
- Download/upload clipboard buttons
- Project file listing (what's in S3)

---

### Use Case 5: Check SSD Status (David)
**Goal:** "What's on my SSD? (Drive not plugged in)"

**Scenario:**
- David's SSD is at home (not connected)
- Opens dashboard (reads cached manifest)
- Sees projects marked "SSD only" (400GB on SSD)
- Knows which projects need SSD connected to access

**Data Needed:**
- SSD status from manifest (last scan)
- Disk usage totals
- List of SSD-only projects

---

## Two-View System

### View 1: Brand Overview

**Purpose:** High-level status across all brands

**URL Structure:** `/` or `/brands`

**Data Displayed:**

1. **Brand Cards** (6 cards, grid layout)
   - Brand name (AppyDave, AITLDR, VOZ, etc.)
   - Project count (21 projects)
   - Disk usage (local: 11.5 GB, SSD: 400 GB)
   - Team members (David, Jan)
   - Quick stats:
     - Projects with S3 staging (3)
     - Local-only projects (15)
     - SSD-only projects (5)

2. **Filters/Search**
   - Text search (project ID or name)
   - Filter by brand
   - Filter by storage (has-s3, local-only, ssd-only)

3. **Recent Activity** (Future)
   - Last 5 projects updated
   - S3 uploads/downloads

**Interactions:**
- Click brand card → Navigate to Project List view for that brand
- Search bar → Filter visible brands/projects

**Layout:**
```
┌─────────────────────────────────────────────────────┐
│ DAM Dashboard - Brand Overview                      │
│                                                      │
│ [Search: ____________]  [Filter: All Brands ▼]     │
│                                                      │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐      │
│ │ AppyDave   │ │ AITLDR     │ │ VOZ        │      │
│ │ 21 projects│ │ 3 projects │ │ 2 projects │      │
│ │ 11.5 GB    │ │ 0.5 GB     │ │ 0.45 GB    │      │
│ │ S3: 3      │ │ S3: 1      │ │ S3: 0      │      │
│ └────────────┘ └────────────┘ └────────────┘      │
│                                                      │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐      │
│ │ Beauty&Joy │ │ Kiros      │ │ SupportSig │      │
│ │ 0 projects │ │ 0 projects │ │ 0 projects │      │
│ │ 0 GB       │ │ 0 GB       │ │ 0 GB       │      │
│ └────────────┘ └────────────┘ └────────────┘      │
└─────────────────────────────────────────────────────┘
```

---

### View 2: Project Detail

**Purpose:** Detailed status for a specific project

**URL Structure:** `/brands/{brand}/projects/{project-id}`

Example: `/brands/appydave/projects/b65-guy-monroe-marketing-plan`

**Data Displayed:**

1. **Project Header**
   - Project ID (b65-guy-monroe-marketing-plan)
   - Brand (AppyDave)
   - Type (FliVideo | Storyline | General)
   - Breadcrumb: Home → AppyDave → b65

2. **Storage Status** (3 sections)
   - **Local Storage**
     - Status: Present | Absent
     - Structure: Flat | Archived
     - Heavy files: Yes/No
     - Light files: Yes/No
     - Disk usage: 125 MB
   - **S3 Staging**
     - Status: Has files | Empty
     - File count: 2 files
     - Last sync: 2 hours ago (future)
   - **SSD Backup**
     - Status: Present | Absent
     - Path: b50-b99/b65-guy-monroe-marketing-plan
     - Disk usage: 8.2 GB

3. **Quick Actions** (Clipboard Buttons)
   - [📋 Upload to S3] → `dam s3-up appydave b65`
   - [📋 Download from S3] → `dam s3-down appydave b65`
   - [📋 Check S3 Status] → `dam s3-status appydave b65`
   - [📋 Archive to SSD] → `dam archive appydave b65`
   - [📋 Sync from SSD] → `dam sync-ssd appydave`

4. **File Listing** (if local exists)
   - `/recordings` (75 files, 6.5 GB)
   - `/assets` (12 files, 2 MB)
   - `/s3-staging` (2 files, 125 MB)

**Layout:**
```
┌──────────────────────────────────────────────────────────┐
│ AppyDave > b65-guy-monroe-marketing-plan                 │
│                                                           │
│ Type: FliVideo                                            │
│                                                           │
│ Storage Locations:                                        │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────┐│
│ │ 📁 Local        │ │ ☁️  S3 Staging   │ │ 💾 SSD      ││
│ │ ✅ Present      │ │ ✅ 2 files      │ │ ❌ Absent   ││
│ │ Flat structure  │ │                 │ │             ││
│ │ 125 MB          │ │                 │ │             ││
│ └─────────────────┘ └─────────────────┘ └─────────────┘│
│                                                           │
│ Quick Actions:                                            │
│ [📋 Upload to S3]  [📋 Download from S3]                 │
│ [📋 S3 Status]  [📋 Archive to SSD]                      │
│                                                           │
│ Files:                                                    │
│ /recordings  (75 files, 6.5 GB)                          │
│ /assets      (12 files, 2 MB)                            │
│ /s3-staging  (2 files, 125 MB)                           │
└──────────────────────────────────────────────────────────┘
```

---

## Data Sources

**All data comes from existing JSON manifests** (no database required):

1. **Brand configuration** - `~/.config/appydave/brands.json`
2. **Project manifests** - `{brand}/projects.json` (per brand)
3. **Settings** - `~/.config/appydave/settings.json`

**Data Refresh:**
- Static site reads manifests at build time
- User manually regenerates manifests via CLI: `dam manifest <brand>`
- Dashboard shows "Last updated" timestamp from manifest

---

## Technology Stack

### Frontend: Astro

**Why Astro:**
- Static site generation (no server required)
- Can read JSON directly (no database)
- Fast, modern, component-based
- Supports React/Svelte/Vue if needed
- Easy deployment (local file:// or hosted)

**Data Loading:**
```javascript
// src/pages/brands/[brand]/projects/[project].astro
---
import { getBrandProjects } from '@/data/manifests';

const { brand, project } = Astro.params;
const manifest = getBrandProjects(brand);
const projectData = manifest.projects.find(p => p.id === project);
---
```

### Deployment Options

1. **Local Development** (David's machine)
   - Source of truth (only David has all brands)
   - Astro dev server: `npm run dev`
   - Builds to `dist/` folder

2. **Static Build** (Shareable)
   - Build: `npm run build`
   - Output: `dist/` (HTML, CSS, JS)
   - Jan/Mary can open `dist/index.html` in browser

3. **Hosted** (Future)
   - Deploy to Netlify/Vercel/GitHub Pages
   - Auto-rebuild on manifest changes
   - Requires exposing manifests (git or API)

---

## UI Design Principles

### 1. Dyslexia-Friendly

**Do:**
- ✅ Soft color coding (green=good, yellow=warning, red=problem)
- ✅ Generous whitespace
- ✅ Large, readable fonts (16px+ body text)
- ✅ High contrast (but not harsh)
- ✅ Consistent layout/positioning

**Don't:**
- ❌ No emoji spam (avoid 📊 🎬 ⚙️ everywhere)
- ❌ No walls of text
- ❌ No complex tables
- ❌ No tiny fonts or low contrast

### 2. Color Coding System

| Color | Meaning | Usage |
|-------|---------|-------|
| **Green** (`#22c55e`) | Good / Present / Synced | Storage exists, files backed up |
| **Yellow** (`#eab308`) | Warning / Needs attention | Out of sync, needs upload |
| **Red** (`#ef4444`) | Problem / Missing | Storage absent, error |
| **Blue** (`#3b82f6`) | Info / Neutral | Informational badges |
| **Gray** (`#6b7280`) | Disabled / Inactive | Unavailable actions |

### 3. Spatial Design

**Avoid:**
- Long vertical lists (hard to scan)
- Horizontal scrolling
- Hidden/nested menus

**Prefer:**
- Grid layouts (brand cards)
- Visual hierarchy (header > sections > details)
- Inline status indicators (badges, icons)

---

## Clipboard Button Behavior

**Goal:** Don't execute commands, just copy them to clipboard

**Implementation:**
```javascript
function copyToClipboard(command) {
  navigator.clipboard.writeText(command);
  // Show toast: "Copied: dam s3-up appydave b65"
}
```

**Button Design:**
```html
<button
  class="clipboard-btn"
  data-command="dam s3-up appydave b65"
  onclick="copyToClipboard(this.dataset.command)"
>
  📋 Upload to S3
</button>
```

**User Workflow:**
1. Click button → Command copied to clipboard
2. Open terminal
3. Paste (Cmd+V / Ctrl+V)
4. Run command

---

## Additional Requirements

### Command Execution Options

**Clipboard Buttons (MVP):**
- Copy CLI command to clipboard
- User pastes and runs in terminal
- Safe, simple, works everywhere

**Direct Execution (Future):**
- Local development only (David/Jan)
- "Run it for me" button
- Calls Astro API endpoint → Executes Ruby CLI command
- Requires:
  - Astro running locally
  - Ruby CLI tools available
  - Server-side execution capability

### Manifest Data Source Challenges

**Problem:** Whose manifest is source of truth?

**Scenario:**
- David and Jan both run DAM locally
- Each generates manifests from their local state
- Manifests differ (David has SSD data, Jan doesn't)
- Astro site needs consistent data for Cloudflare Pages

**Solution (MVP):**
- **Source of truth:** David's machine (only one with all brands + SSD)
- **Workflow:**
  1. David generates manifests (`dam manifest all`, `dam s3-scan all`)
  2. David pushes manifests to Astro data folder (ETL process)
  3. Git commit → Cloudflare Pages rebuilds site
  4. Jan/Mary/Clients see David's view of the world

**Jan's Local Astro:**
- Jan can run Astro locally
- Reads David's manifests (from git)
- Cannot update published site (only David can)
- **Question:** Should Jan be able to generate his own local manifests for his local Astro view?

**Database Alternative (Out of Scope):**
- Use Convex database
- Both David/Jan push manifest updates to DB
- Astro site reads from DB (not git)
- Enables real-time collaborative view
- More complex infrastructure

### Project-Level Manifests

**Purpose:** Detailed file tree for single project

**Command:** `dam project-manifest <brand> <project>`

**Output:** `{project}/.project-manifest.json`

**Structure:**
```json
{
  "project_id": "b64-bmad-claude-sdk",
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
      "total_bytes": 2000000
    },
    "s3-staging": {
      "type": "directory",
      "file_count": 2,
      "total_bytes": 125000000
    },
    "transcripts": {
      "type": "directory",
      "file_count": 3,
      "total_bytes": 500000
    }
  }
}
```

**Characteristics:**
- **Transient** - Not required, regenerate on demand
- **Optional** - Dashboard works without it (shows booleans instead)
- **Git-ignored** - Too volatile to commit
- **On-demand** - Generate when needed for detail view
- **Future:** Clickable button in Astro to generate (local dev only)

### S3 Commands

**Brand-Level S3 Scan:**
- `dam s3-scan <brand>` - Scan all projects in brand
- `dam s3-scan all` - Scan all brands
- Updates brand manifest with real S3 file listings
- Queries AWS S3 bucket (not just local `s3-staging/` folder)

**Project-Level S3 Discover (Exists):**
- `dam s3-discover <brand> <project>` - List files for one project
- Shows available files in S3 staging
- Can generate shareable pre-signed URLs

### Transcript Locations

**FliVideo Projects:**
- **Primary:** `{project}/transcripts/` (future standard)
- **Legacy:** `{project}/s3-staging/*.srt` (temporary, migrating away)
- **Formats:** `.srt`, `.txt`
- **Per-segment transcripts:** Future enhancement (chapter-level + segment-level)

**Storyline Projects:**
- **Location:** `{project}/data/source/`
- **Files:**
  - `transcript.srt` - Subtitle format
  - `transcript.txt` - Plain text
  - `transcript-raw.txt` - Unedited
  - `words.json` - Word-level timing
  - `beats.json` - Story beats
  - `timestamps.txt` - Timing data

**Dashboard Integration:**
- Show "Has transcript: Yes/No" indicator (MVP)
- Link to open transcript (future)
- Full transcript preview (out of scope)

### Brand Configuration Extensions

**Color Coding:**
- Add `color` property to brands.json
- Example: `"color": "#3b82f6"` (blue), `"color": "#22c55e"` (green)
- Use for brand card backgrounds, badges, visual distinction
- May need multiple colors (primary, secondary)

**Example:**
```json
{
  "appydave": {
    "name": "AppyDave",
    "shortcut": "ad",
    "type": "owned",
    "color": "#3b82f6",
    "...": "..."
  }
}
```

## Future Enhancements (Out of Scope for MVP)

1. **Real S3 Sync Detection** - ✅ Addressed (dam s3-scan command)
2. **File-Level Diff** - Compare local vs S3 files (which changed?)
3. **Team Activity Feed** - Who uploaded what, when?
4. **Transcript Search** - Full-text search across all project transcripts
5. **FliVideo Chapter View** - Visual timeline of recordings
6. **Storyline Script View** - Display storyline.json data
7. **YouTube Publish Status** - Link projects to published videos
8. **Disk Usage Trends** - Historical disk usage over time
9. **Project-Level Manifest Auto-Generation** - Button in Astro to generate on-demand
10. **Direct Command Execution** - Run Ruby commands from Astro (local dev)
11. **Database Backend** - Convex for collaborative manifest updates

---

## Success Metrics

**MVP is successful if:**

1. **David can answer these questions in <5 seconds:**
   - "Does b65 have changes in S3?"
   - "What's my next project code?"
   - "Is b57 on my SSD or local?"

2. **Jan can perform these actions without asking David:**
   - Download a project from S3
   - Upload edited files back to S3
   - See what projects are available to work on

3. **Command confusion is eliminated:**
   - No more "was it `dam s3-up` or `dam up-s3`?"
   - Clipboard buttons provide exact syntax

4. **Context switching is faster:**
   - David can switch brands/projects without digging through filesystems
   - Visual layout reduces cognitive load

---

## Implementation Phases

### Phase 1: Data Model & Manifest Understanding (COMPLETED)
- ✅ Document entity schema
- ✅ Map data sources
- ✅ Understand manifest generation

### Phase 2: Astro Project Setup (Next)
- Create Astro project structure
- Set up data loading from manifests
- Basic routing (`/brands`, `/brands/{brand}/projects/{project}`)

### Phase 3: Brand Overview View
- Grid layout of brand cards
- Project counts, disk usage
- Search/filter

### Phase 4: Project Detail View
- Storage status display
- Clipboard buttons
- File listing

### Phase 5: Polish & Testing
- Dyslexia-friendly design
- Color coding
- David + Jan user testing

---

**Last updated**: 2025-11-18
