# DAM Implementation Roadmap

**Digital Asset Management Visualization System**

This roadmap provides a comprehensive guide for implementing the DAM visualization dashboard, organizing all documentation, epics, and tasks into a clear development path.

---

## 📚 Documentation Overview

All DAM-related documentation has been organized into a cohesive structure. Here's what each document covers:

### Core Architecture Documents

| Document | Purpose | Key Content |
|----------|---------|-------------|
| **[dam-vision.md](dam-vision.md)** | Strategic vision and roadmap | Long-term goals, future enhancements, product direction |
| **[dam-data-model.md](dam-data-model.md)** | Complete data model schema | Entities, relationships, data sources, state inference rules |
| **[dam-visualization-requirements.md](dam-visualization-requirements.md)** | Product requirements for dashboard | User personas, use cases, UI design, technology stack |
| **[dam-cli-enhancements.md](dam-cli-enhancements.md)** | CLI tool changes needed | New commands, naming consolidation, implementation phases |
| **[jan-collaboration-guide.md](jan-collaboration-guide.md)** | Team collaboration workflow | Jan's setup guide, S3 workflows, command reference |

### Design Decisions

| Document | Status | Topic |
|----------|--------|-------|
| **[design-decisions/002-client-sharing.md](design-decisions/002-client-sharing.md)** | 🔄 IN PROGRESS | Client access to DAM dashboard (Mary, Vasilios, Ronnie) |
| **[design-decisions/003-git-integration.md](design-decisions/003-git-integration.md)** | 📋 PLANNED | Git-based manifest distribution strategy |

### Related Documentation (Other Systems)

| Document | Location | Topic |
|----------|----------|-------|
| **Configuration Systems** | `../configuration/configuration-systems.md` | How brands/channels/settings relate |
| **CLI Patterns** | `../cli/cli-patterns.md` | CLI architecture patterns |
| **CLI Pattern Comparison** | `../cli/cli-pattern-comparison.md` | Visual pattern guide |
| **Design Decision 001** | `../design-decisions/001-unified-brands-config.md` | Unified brands configuration (completed) |

---

## 🎯 Development Epics

The implementation is organized into **3 main epics** that can be developed in parallel or sequentially:

### Epic 1: CLI Data Infrastructure ⚙️

**Goal:** Provide complete data foundation for dashboard via manifest generation

**Status:** 🔄 PARTIALLY IMPLEMENTED (needs enhancements)

**Key Tasks:**

1. **Naming Consolidation** (dam-cli-enhancements.md - Phase 1)
   - [ ] Rename executables to use dash naming (`ad-dam`, `ad-config`, etc.)
   - [ ] Update bin/ directory structure
   - [ ] Create symlinks for old names with deprecation warnings
   - [ ] Update documentation references

2. **Brand-Level S3 Scan** (dam-cli-enhancements.md - Phase 2)
   - [ ] Implement `ad-dam s3-scan <brand>` command
   - [ ] Query AWS S3 bucket for actual file listings
   - [ ] Update brand manifest with S3 file count, sizes, timestamps
   - [ ] Add `storage.s3.file_count`, `storage.s3.total_bytes`, `storage.s3.last_modified`
   - [ ] Implement `ad-dam s3-scan all` for bulk scanning

3. **Project-Level Manifests** (dam-cli-enhancements.md - Phase 3)
   - [ ] Implement `ad-dam project-manifest <brand> <project>` command
   - [ ] Generate `.project-manifest.json` with tree structure
   - [ ] Include subdirectory breakdown (e.g., `recordings/recordings-bmad-v6/`)
   - [ ] Calculate file counts and sizes per directory
   - [ ] Add to .gitignore (transient file)

4. **Bulk Operations** (dam-cli-enhancements.md - Phase 4)
   - [ ] Implement `ad-dam manifest all` (all brands)
   - [ ] Implement `ad-dam refresh <brand>` (manifest + s3-scan)
   - [ ] Implement `ad-dam refresh all` (complete rebuild)
   - [ ] Add progress indicators for long operations

5. **Enhanced Manifest Output** (dam-cli-enhancements.md - Phase 5)
   - [ ] Add transcript detection to brand manifests
   - [ ] Add project type confidence scores
   - [ ] Add brand color configuration support
   - [ ] Include last_updated timestamps

**Reference Documents:**
- [dam-cli-enhancements.md](dam-cli-enhancements.md) - Complete CLI specification
- [dam-data-model.md](dam-data-model.md) - Manifest schema and entity definitions

**Success Criteria:**
- ✅ All 6 brands have complete manifests (local + S3 + SSD data)
- ✅ Project-level manifests can be generated on-demand
- ✅ Naming is consistent across all CLI tools
- ✅ Jan can run `ad-dam manifest all` to get complete view

---

### Epic 2: Astro Dashboard - Brand Overview 🌐

**Goal:** Create main dashboard showing all brands and high-level project status

**Status:** 📋 NOT STARTED (design complete, ready to implement)

**Key Tasks:**

1. **Astro Project Setup**
   - [ ] Create new Astro project
   - [ ] Configure TypeScript
   - [ ] Set up Tailwind CSS (dyslexia-friendly theme)
   - [ ] Configure build for Cloudflare Pages deployment

2. **Data Loading**
   - [ ] Create data loader for brand manifests
   - [ ] Read manifests from `video-projects/{brand}/projects.json`
   - [ ] Aggregate brand-level statistics (project counts, disk usage)
   - [ ] Handle missing/stale manifests gracefully

3. **Brand Grid View**
   - [ ] Create brand card component (soft colors, large text)
   - [ ] Display brand name, project count, disk usage
   - [ ] Show team members (avatars/initials)
   - [ ] Color-code storage status (green=synced, yellow=local-only, red=issues)
   - [ ] Add brand color configuration support

4. **Project Summary Table**
   - [ ] Sortable/filterable table of all projects
   - [ ] Columns: ID, Type, Local, S3, SSD, Disk Usage
   - [ ] Pattern matching filter (e.g., `b6*` for b60-b69)
   - [ ] Click to navigate to project detail view

5. **Clipboard Actions**
   - [ ] Add "Copy Command" buttons (MVP)
   - [ ] Commands: `ad-dam list <brand>`, `ad-dam manifest <brand>`, `ad-dam refresh <brand>`
   - [ ] Toast notification on copy

6. **Responsive Design**
   - [ ] Desktop layout (grid + table)
   - [ ] Mobile layout (stacked cards)
   - [ ] Tablet layout (2-column grid)

**Reference Documents:**
- [dam-visualization-requirements.md](dam-visualization-requirements.md) - Complete UI specification
- [dam-data-model.md](dam-data-model.md) - Manifest data structure

**Success Criteria:**
- ✅ David can see all 6 brands at a glance
- ✅ Jan can identify which projects need syncing
- ✅ Mary/Clients can see project status without CLI knowledge
- ✅ Dashboard is readable on mobile devices

---

### Epic 3: Astro Dashboard - Project Detail 📁

**Goal:** Deep dive view for individual project with storage locations and actions

**Status:** 📋 NOT STARTED (design complete, ready to implement)

**Key Tasks:**

1. **Routing Setup**
   - [ ] Create dynamic route: `/project/[brand]/[projectId]`
   - [ ] Handle short names (b65 → b65-guy-monroe-marketing-plan)
   - [ ] 404 handling for missing projects

2. **Project Overview Section**
   - [ ] Display project ID, type, description
   - [ ] Show recording date, duration (if available)
   - [ ] Display team members working on project

3. **Storage Locations Panel**
   - [ ] **Local Storage:** Path, structure (flat/archived), file counts, disk usage
   - [ ] **S3 Staging:** Status, file count, last_modified, sync indicator
   - [ ] **SSD Backup:** Path, disk usage, availability status
   - [ ] Color-coded indicators (green=present, gray=missing)

4. **File Tree View** (if project-level manifest exists)
   - [ ] Collapsible directory tree
   - [ ] Show subdirectories (e.g., `recordings/recordings-bmad-v6/`)
   - [ ] File counts per directory
   - [ ] Disk usage per directory
   - [ ] Fallback to brand manifest booleans if no project manifest

5. **Transcript Display**
   - [ ] Show transcript availability (yes/no indicator)
   - [ ] Link to transcript file location (FliVideo vs Storyline paths)
   - [ ] Future: Inline transcript preview

6. **Action Buttons** (Clipboard MVP)
   - [ ] Upload to S3: `ad-dam s3-up <brand> <project>`
   - [ ] Download from S3: `ad-dam s3-down <brand> <project>`
   - [ ] Check sync status: `ad-dam s3-status <brand> <project>`
   - [ ] Archive to SSD: `ad-dam archive <brand> <project>`
   - [ ] Generate project manifest: `ad-dam project-manifest <brand> <project>`

7. **Sync Status Visualization**
   - [ ] Matrix view: Local ✅ | S3 ✅ | SSD ❌ → "Active collaboration"
   - [ ] Inferred state labels (see dam-data-model.md - Sync State table)
   - [ ] Recommendations (e.g., "Archive to SSD after publishing")

**Reference Documents:**
- [dam-visualization-requirements.md](dam-visualization-requirements.md) - UI specifications
- [dam-data-model.md](dam-data-model.md) - Storage inference rules, sync states

**Success Criteria:**
- ✅ David can see complete project status at a glance
- ✅ Jan can copy S3 sync commands without memorizing syntax
- ✅ Clients can understand project location without technical knowledge
- ✅ File tree provides insight into project organization

---

## 🚀 Getting Started

### For CLI Development (Epic 1)

**Start here:** [dam-cli-enhancements.md](dam-cli-enhancements.md)

**Recommended order:**
1. Read data model to understand manifest structure: [dam-data-model.md](dam-data-model.md)
2. Review existing manifest generator: `lib/appydave/tools/dam/manifest_generator.rb`
3. Implement Phase 2 (S3 scan) first - highest priority for collaboration
4. Test with `ad-dam s3-scan appydave` on real data
5. Move to Phase 3 (project manifests) for detailed views

**Testing:**
- Run against real brand data (`v-appydave`, `v-voz`)
- Verify S3 API calls with `--dry-run` flag
- Check manifest JSON structure matches schema

### For Astro Development (Epic 2 & 3)

**Start here:** [dam-visualization-requirements.md](dam-visualization-requirements.md)

**Recommended order:**
1. Read visualization requirements for UI design patterns
2. Review data model for manifest JSON structure
3. Set up Astro project with Tailwind CSS
4. Build Brand Overview (Epic 2) first - simpler, establishes patterns
5. Build Project Detail (Epic 3) second - leverages Epic 2 components

**Testing:**
- Use existing brand manifests from `/Users/davidcruwys/dev/video-projects/v-*/projects.json`
- Test with David's full dataset (6 brands, 50+ projects)
- Test mobile/tablet responsive layouts
- Verify clipboard functionality across browsers

### For Team Collaboration

**Start here:** [jan-collaboration-guide.md](jan-collaboration-guide.md)

**Use cases:**
- Jan setting up Windows/WSL environment
- Understanding S3 upload/download workflows
- Quick command reference

---

## 📋 Implementation Priority

**Recommended development sequence:**

### Phase 1: CLI Foundation (Week 1-2)
- Epic 1, Task 2: S3 Scan command (highest priority for collaboration)
- Epic 1, Task 3: Project-level manifests (enables detailed views)
- Epic 1, Task 4: Bulk operations (improves workflow)

### Phase 2: Dashboard MVP (Week 3-4)
- Epic 2: Brand Overview (complete)
- Epic 3: Project Detail (basic - storage locations only, no file tree)

### Phase 3: Enhancement (Week 5-6)
- Epic 1, Task 1: Naming consolidation (improves UX)
- Epic 3: Project Detail - File tree view (requires project manifests)
- Epic 1, Task 5: Enhanced manifest output (adds transcript detection)

### Phase 4: Polish (Week 7+)
- Dashboard: Direct command execution (beyond clipboard)
- Dashboard: Real-time manifest regeneration
- CLI: Testing suite expansion

---

## 🎓 Key Learnings from Planning

**Data Model Insights:**
- State is **inferred from filesystem**, not database-driven
- Manifests are **generated snapshots**, not live queries
- David's machine is **source of truth** (only one with SSD access)

**UI Design Principles:**
- **Dyslexia-friendly:** Soft colors, large fonts, generous whitespace
- **No emoji spam:** User prefers color coding over icons
- **Clipboard-first:** MVP copies commands, doesn't execute them

**Team Workflows:**
- **David → Jan:** Upload to S3, Jan downloads, edits, uploads back
- **David → Clients:** Read-only Cloudflare Pages deployment
- **Manifest updates:** David generates → Git → Cloudflare Pages rebuilds

**Technical Decisions:**
- **Astro static site:** No database, git-friendly, Cloudflare Pages deployment
- **JSON manifests:** Two levels (brand + project), project manifests are transient
- **S3 detection:** Currently local-only, needs AWS API queries for accuracy

---

## 🔗 Quick Reference Links

**Primary Documentation:**
- [DAM Vision](dam-vision.md) - Strategic direction
- [Data Model](dam-data-model.md) - Schema and entities
- [Visualization Requirements](dam-visualization-requirements.md) - UI specification
- [CLI Enhancements](dam-cli-enhancements.md) - Command implementation
- [Jan Collaboration Guide](jan-collaboration-guide.md) - Team workflow

**Related Systems:**
- [Configuration Systems](../configuration/configuration-systems.md) - Brands/channels relationship
- [CLI Patterns](../cli/cli-patterns.md) - CLI architecture
- [Design Decision 001](../design-decisions/001-unified-brands-config.md) - Unified brands config

**Code References:**
- Manifest Generator: `lib/appydave/tools/dam/manifest_generator.rb`
- Brand Config: `~/.config/appydave/brands.json`
- Settings Config: `~/.config/appydave/settings.json`

---

**Last updated:** 2025-11-18
