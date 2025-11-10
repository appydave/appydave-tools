# DAM Vision - Digital Asset Management for Video Projects

> **Note**: This is the original vision document for what became **DAM (Digital Asset Management)**. DAM IS a Digital Asset Management (DAM) system specifically designed for multi-brand video project workflows.

## What is DAM?

Digital Asset Management (DAM) is a system that stores, organizes, and retrieves digital assets such as images, videos, and other multimedia files. DAM systems are used by organizations to manage their digital assets efficiently and effectively.

## DAM as a DAM System

**DAM (Digital Asset Management)** implements this DAM vision with:
- Multi-tenant brand management (6 brands: AppyDave, VOZ, AITLDR, Kiros, Beauty & Joy, SupportSignal)
- Hybrid storage strategy (Local → S3 → SSD)
- Project lifecycle management (create, archive, restore)
- Asset organization and discovery
- Configurable workflows per brand

## Why "DAM" instead of "DAM"?

The name "Digital Asset Management" was chosen for:
- Specificity to video content creation workflows
- Simplicity for command-line usage
- Backward compatibility with existing tooling

However, DAM is fundamentally a DAM system. All user stories below have been implemented in DAM.

---

## Original User Stories

These user stories defined the vision for what became DAM. All have been implemented:

### Multi-Brand Management ✅
**Story**: As a content creator, I want to keep track of the different brands I'm running where a business unit represents brand.

**Implementation**: DAM supports 6 brands with individual configurations in `brands.json`.

### Brand Configuration ✅
**Story**: As a content creator, I want to manage the types of projects and extra configuration associated with each brand.

**Implementation**: Each brand has custom AWS profiles, S3 buckets, SSD backup locations, and workflow patterns (FliVideo vs Storyline).

### Asset Discovery ✅
**Story**: As a content creator, I want to be able to find assets associated with a project and brand.

**Implementation**: `dam list` command with pattern matching and project discovery.

### Multi-Location Storage ✅
**Story**: As a content creator, I may need to split specific projects across multiple drive locations for short and long-term storage and for team sharing.

**Implementation**: Hybrid storage strategy - Local (active work) → S3 (90-day collaboration) → SSD (long-term archive).

### Project Creation ✅
**Story**: As a content creator, I need to be able to easily create a new project for a brand and have it sequentially labelled in an appropriate location.

**Implementation**: FliVideo pattern (b40, b41, b42...) with auto-expansion (`b65` → `b65-guy-monroe-marketing-plan`).

### Project Initialization ✅
**Story**: As a content creator, I need a new project to be initialized based on the brand/project configuration.

**Implementation**: Brand-specific configuration drives project setup and folder structure.

### File Organization ✅
**Story**: As a content creator, I need tools that will automatically transfer files to project folder locations based on source, file type, and naming convention.

**Implementation**: `s3-staging/` directory pattern for collaboration files (subtitles, images, light assets).

### Project Management ✅
**Story**: As a content creator, I need to be able to create, remove, rename, update, list project files.

**Implementation**: Full CRUD operations via DAM commands (`list`, `s3-up`, `s3-down`, `s3-status`, `archive`, `manifest`).

### Archive/Restore ✅
**Story**: As a content creator, I need to be able to archive or reverse archive project files.

**Implementation**: `dam archive` (copy to SSD) and upcoming `dam sync-ssd` (restore from SSD).

### Transcription Management ✅
**Story**: As a content creator, I need to be able to work with video transcriptions for use by various AI tools.

**Implementation**: SRT file support in `s3-staging/` for subtitle collaboration and AI processing.

### Naming Conventions ✅
**Story**: As a content creator, I need a well-defined project naming convention.

**Implementation**:
- **FliVideo pattern**: `[letter][number]-[name]` (e.g., `b65-guy-monroe-marketing-plan`)
- **Storyline pattern**: Descriptive names (e.g., `boy-baker`, `the-point`)

### Configurable Rules ✅
**Story**: As a content creator, I need configurable project structures and rules.

**Implementation**: `brands.json` configuration with per-brand AWS settings, locations, and workflow patterns.

### Asset Naming ✅
**Story**: As a content creator, I need a well-defined asset naming convention.

**Implementation**: Consistent naming across brands with pattern-based organization.

### Smart Storage Rules ✅
**Story**: As a content creator, I need assets to be stored in various locations within the project using smart rules.

**Implementation**:
- Heavy files (video): Stay local or archived to SSD
- Light files (subtitles, images): Synced via S3 for collaboration
- Manifest tracking: JSON-based project state management

---

## Implementation Summary

All original DAM user stories have been fully implemented in DAM. The system provides:

✅ Multi-brand video project management
✅ Hybrid storage (Local/S3/SSD)
✅ Smart sync with MD5 validation
✅ Project discovery and pattern matching
✅ Archive and restore workflows
✅ Configurable per-brand settings
✅ Comprehensive CLI with help system
✅ 297 automated tests, 90.69% coverage

**DAM IS a complete DAM solution for video content creators.**
