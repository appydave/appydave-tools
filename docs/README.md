# AppyDave Tools Documentation

**Documentation organized by purpose:** guides (how to), architecture (why/how it works), templates (copy these), development (contribute).

---

## 📖 Guides (How To Use)

### Tools

- **[DAM - Digital Asset Management](./guides/tools/dam/)** - Video project storage orchestration
  - [Usage Guide](./guides/tools/dam/dam-usage.md) ✅
  - [Testing Plan](./guides/tools/dam/dam-testing-plan.md) ✅
- **[VideoFileNamer](./guides/tools/video-file-namer.md)** - Generate structured video segment filenames ✅
- **[GPT Context](./guides/tools/gpt-context.md)** - Gather files for AI context ✅
- **[YouTube Manager](./guides/tools/youtube-manager.md)** - Manage YouTube metadata ✅
- **[Subtitle Processor](./guides/tools/subtitle-processor.md)** - Clean/merge SRT files ✅
- **[Configuration Tool](./guides/tools/configuration.md)** - Manage config files ✅
- **[YouTube Automation](./guides/tools/youtube-automation.md)** - Automation workflows ✅
- **[Prompt Tools](./guides/tools/prompt-tools.md)** - OpenAI completion wrapper ✅
- **[Move Images](./guides/tools/move-images.md)** - Organize video assets ✅
- **[Bank Reconciliation](./guides/tools/bank-reconciliation.md)** - DEPRECATED ✅
- **[Name Manager](./guides/tools/name-manager.md)** - Naming utilities ✅
- **[CLI Actions](./guides/tools/cli-actions.md)** - CLI base actions ✅

### Platform-Specific

- **[Windows Setup](./guides/platforms/windows/)** - Windows/WSL installation ✅
  - [Installation Guide](./guides/platforms/windows/installation.md) ✅
  - [Testing Plan](./guides/platforms/windows/dam-testing-plan-windows-powershell.md) ✅

### Configuration

- **[Configuration Setup Guide](./guides/configuration-setup.md)** - Complete configuration reference ✅
  - Quick start, file locations, settings reference
  - Migration from legacy configs
  - Backup and recovery

### Future Configuration Guides

More detailed configuration guides (not yet created):

- **Settings Deep Dive** 📝 (detailed explanation of each setting)
- **Channels System** 📝 (YouTube channel management)
- **Brands System** 📝 (multi-brand/multi-tenant architecture)
- **Advanced Configuration** 📝 (environment-specific configs, team setups)

---

## 🏗️ Architecture (Understanding How It Works)

### DAM (Digital Asset Management)

**Complete documentation for DAM visualization and CLI system:**

- **[Implementation Roadmap](./architecture/dam/implementation-roadmap.md)** ⭐ START HERE - Complete development guide ✅
- **[DAM Vision](./architecture/dam/dam-vision.md)** - Strategic vision and roadmap ✅
- **[Data Model](./architecture/dam/dam-data-model.md)** - Complete entity schema and relationships ✅
- **[Visualization Requirements](./architecture/dam/dam-visualization-requirements.md)** - Astro dashboard specification ✅
- **[CLI Enhancements](./architecture/dam/dam-cli-enhancements.md)** - Command requirements specification ✅
- **[CLI Implementation Guide](./architecture/dam/dam-cli-implementation-guide.md)** - Code-level implementation details ✅
- **[Jan Collaboration Guide](./architecture/dam/jan-collaboration-guide.md)** - Team workflow reference ✅

**DAM Design Decisions:**
- **[002 - Client Sharing](./architecture/dam/design-decisions/002-client-sharing.md)** 🔄 IN PROGRESS
- **[003 - Git Integration](./architecture/dam/design-decisions/003-git-integration.md)** 📋 PLANNED

### CLI Architecture

- **[CLI Patterns](./architecture/cli/cli-patterns.md)** - CLI architecture patterns ✅
- **[CLI Pattern Comparison](./architecture/cli/cli-pattern-comparison.md)** - Visual pattern guide ✅

### Configuration Systems

- **[Configuration Systems Analysis](./architecture/configuration/configuration-systems.md)** - How brands/channels/NameManager relate ✅

### Design Decisions (General)

- **[001 - Unified Brands Configuration](./architecture/design-decisions/001-unified-brands-config.md)** ✅ COMPLETED
- **[Session: 2025-11-09 DAM Refactoring](./architecture/design-decisions/session-2025-11-09.md)** ✅

---

## 📋 Templates (Copy These)

Ready-to-use configuration templates:

- **[settings.example.json](./templates/settings.example.json)** - Settings template ✅
- **[channels.example.json](./templates/channels.example.json)** - Channels template ✅
- **[.env.example](./templates/.env.example)** - Environment variables template ✅
- **brands.example.json** 📝 (not yet created - should mirror brands.json structure with placeholders)

**To use templates:**
```bash
# Copy to config directory
cp docs/templates/settings.example.json ~/.config/appydave/settings.json
cp docs/templates/channels.example.json ~/.config/appydave/channels.json

# Copy .env to project root
cp docs/templates/.env.example .env

# Edit with your values
ad_config -e
```

---

## 🛠️ Development (Contributing)

Documentation for contributors and developers:

- **[CODEX Recommendations](./development/codex-recommendations.md)** - AI coding guidelines ✅

### Future Development Topics

Planned documentation for contributors:

- **Contributing Guide** 📝 (how to contribute, PR process, coding standards)
- **Testing Guide** 📝 (how to run tests, write specs, coverage requirements)
- **Release Process** 📝 (semantic versioning, CI/CD, gem publishing)
- **Development Setup** 📝 (rbenv, bundler, guard, development workflow)

---

## 🗄️ Archive

Historical and deprecated documentation:

- **[Archive](./archive/)** - Deprecated documentation ✅

---

## 📂 Directory Structure

```
docs/
├── README.md (this file)                          # Documentation index
│
├── guides/                                        # HOW TO use things
│   ├── tools/                                     # Individual tool guides
│   │   ├── dam/                                   # DAM-specific guides
│   │   │   ├── dam-usage.md
│   │   │   └── dam-testing-plan.md
│   │   ├── gpt-context.md
│   │   ├── youtube-manager.md
│   │   ├── subtitle-processor.md
│   │   ├── configuration.md
│   │   └── ... (11 tool guides total)
│   │
│   └── platforms/                                 # Platform-specific setup
│       └── windows/                               # Windows/WSL guides
│           ├── README.md
│           ├── installation.md
│           └── dam-testing-plan-windows-powershell.md
│
├── architecture/                                  # WHY/HOW systems work
│   ├── dam/                                       # DAM system documentation
│   │   ├── implementation-roadmap.md              # ⭐ START HERE - Complete dev guide
│   │   ├── dam-vision.md                          # Strategic vision
│   │   ├── dam-data-model.md                      # Entity schema
│   │   ├── dam-visualization-requirements.md      # Astro dashboard spec
│   │   ├── dam-cli-enhancements.md                # CLI implementation
│   │   ├── jan-collaboration-guide.md             # Team workflow
│   │   └── design-decisions/                      # DAM-specific PRDs
│   │       ├── 002-client-sharing.md
│   │       └── 003-git-integration.md
│   │
│   ├── cli/                                       # CLI architecture
│   │   ├── cli-patterns.md                        # CLI patterns
│   │   └── cli-pattern-comparison.md              # Pattern guide
│   │
│   ├── configuration/                             # Configuration system
│   │   └── configuration-systems.md               # System overlap analysis
│   │
│   └── design-decisions/                          # General PRDs, ADRs, session logs
│       ├── 001-unified-brands-config.md
│       └── session-2025-11-09.md
│
├── templates/                                     # COPY THESE files
│   ├── settings.example.json
│   ├── channels.example.json
│   └── .env.example
│
├── development/                                   # FOR CONTRIBUTORS
│   └── codex-recommendations.md
│
└── archive/                                       # OLD/DEPRECATED
    └── ... (historical docs)
```

---

## 🔍 Quick Reference

### By Task

| Task | Documentation |
|------|---------------|
| **DAM development** | [Implementation Roadmap](./architecture/dam/implementation-roadmap.md) ⭐ |
| **Video storage management** | [DAM Usage](./guides/tools/dam/dam-usage.md) |
| **S3 sync for collaboration** | [DAM Usage](./guides/tools/dam/dam-usage.md) |
| **Understand DAM architecture** | [DAM Data Model](./architecture/dam/dam-data-model.md) |
| **Build DAM dashboard** | [Visualization Requirements](./architecture/dam/dam-visualization-requirements.md) |
| **Gather AI context** | [GPT Context](./guides/tools/gpt-context.md) |
| **Manage YouTube videos** | [YouTube Manager](./guides/tools/youtube-manager.md) |
| **Process subtitles** | [Subtitle Processor](./guides/tools/subtitle-processor.md) |
| **Configure tools** | [Configuration Tool](./guides/tools/configuration.md) |
| **Set up on Windows** | [Windows Setup](./guides/platforms/windows/) |
| **Build new CLI tool** | [CLI Patterns](./architecture/cli/cli-patterns.md) |
| **Understand system design** | [Configuration Systems](./architecture/configuration/configuration-systems.md) |

### By Audience

| Audience | Start Here |
|----------|------------|
| **DAM Developers** | [Implementation Roadmap](./architecture/dam/implementation-roadmap.md) ⭐ |
| **End Users** | [Guides](#-guides-how-to-use) - Individual tool documentation |
| **Windows Users** | [Windows Setup](./guides/platforms/windows/) |
| **Team Members (Jan)** | [Jan Collaboration Guide](./architecture/dam/jan-collaboration-guide.md) |
| **Developers** | [Development](#%EF%B8%8F-development-contributing) - Contributing guides |
| **Contributors** | [CLI Patterns](./architecture/cli/cli-patterns.md) |
| **Architects** | [Architecture](#%EF%B8%8F-architecture-understanding-how-it-works) - System design |

---

## Legend

- ✅ = Exists (real file with content)
- 📝 = Placeholder (future documentation, not yet created)
- 🔄 = In Progress
- 📋 = Planned

---

## 📝 Documentation Standards

All documentation in this repository follows the [AI Conventions](../../.ai-conventions.md):

- **File naming**: `kebab-case` for all markdown files
- **Exceptions**: `README.md`, `CHANGELOG.md`, `CLAUDE.md` (uppercase allowed)
- **Location**: Organized by category in subdirectories
- **Cross-referencing**: Relative links between documents

---

## 🤝 Contributing Documentation

When adding new documentation:

1. **Choose the right location**:
   - How-to guides → `guides/tools/` or `guides/platforms/`
   - System understanding → `architecture/`
   - Design decisions → `architecture/design-decisions/`
   - Templates → `templates/`
   - Contributor info → `development/`

2. **Use kebab-case** for filenames (e.g., `my-new-tool.md`)

3. **Update this index** with a link to your new document

4. **Follow existing patterns** - check similar docs for style guidance

5. **Mark status** - Use ✅ for complete docs, 📝 for placeholders

---

**Last updated**: 2025-11-18
