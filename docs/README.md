# AppyDave Tools Documentation

**Documentation organized by purpose:** guides (how to), architecture (why/how it works), templates (copy these), development (contribute).

---

## Two Major Systems

AppyDave Tools contains **two major systems** with comprehensive documentation, plus several smaller utilities:

| System | Purpose | Domain | Audience |
|--------|---------|--------|----------|
| **[DAM](#-dam-digital-asset-management)** | Video project storage orchestration | Video assets, S3, SSD | Video creators, editors |
| **[GPT Context](#-gpt-context-gatherer)** | AI context collection from codebases | Source code, AI assistants | Developers, AI users |

### Quick Comparison

| Aspect | DAM | GPT Context |
|--------|-----|-------------|
| **Input** | Video files (MP4, SRT, MOV) | Source code files |
| **Output** | Cloud/SSD storage | Text (clipboard/files) |
| **State** | Stateful (sync tracking) | Stateless |
| **External services** | AWS S3 | None |
| **Configuration** | brands.json, settings.json | CLI options only |
| **Primary command** | `vat` | `gpt_context` |

---

## 🎬 DAM (Digital Asset Management)

**Purpose**: Multi-tenant video project storage orchestration for content creators.

### Guides (How to Use)

- **[DAM Usage Guide](./guides/tools/dam/dam-usage.md)** ✅ - Complete command reference
- **[DAM Testing Plan](./guides/tools/dam/dam-testing-plan.md)** ✅ - Verification procedures
- **[Windows Testing](./guides/platforms/windows/dam-testing-plan-windows-powershell.md)** ✅ - Windows-specific testing

### Architecture (How it Works)

- **[Implementation Roadmap](./architecture/dam/implementation-roadmap.md)** ⭐ START HERE
- **[DAM Vision](./architecture/dam/dam-vision.md)** ✅ - Strategic vision and roadmap
- **[Data Model](./architecture/dam/dam-data-model.md)** ✅ - Entity schema and relationships
- **[Visualization Requirements](./architecture/dam/dam-visualization-requirements.md)** ✅ - Astro dashboard spec
- **[CLI Enhancements](./architecture/dam/dam-cli-enhancements.md)** ✅ - Command requirements
- **[CLI Implementation Guide](./architecture/dam/dam-cli-implementation-guide.md)** ✅ - Code-level details
- **[Jan Collaboration Guide](./architecture/dam/jan-collaboration-guide.md)** ✅ - Team workflow

### Design Decisions

- **[002 - Client Sharing](./architecture/dam/design-decisions/002-client-sharing.md)** 🔄 IN PROGRESS
- **[003 - Git Integration](./architecture/dam/design-decisions/003-git-integration.md)** 📋 PLANNED

### Quick Start

```bash
# List all brands
vat list

# List projects for a brand
vat list appydave

# Upload to S3 for collaboration
vat s3-up appydave b65

# Download from S3
vat s3-down appydave b65

# Check sync status
vat s3-status appydave b65

# Archive to SSD
vat archive appydave b63
```

---

## 🤖 GPT Context Gatherer

**Purpose**: Collect and package codebase files for AI assistant context.

### Guides (How to Use)

- **[GPT Context Usage Guide](./guides/tools/gpt-context.md)** ✅ - Complete command reference with examples

### Architecture (How it Works)

- **[GPT Context Vision](./architecture/gpt-context/gpt-context-vision.md)** ✅ - Strategic vision and philosophy
- **[GPT Context Architecture](./architecture/gpt-context/gpt-context-architecture.md)** ✅ - Data flow and components
- **[GPT Context Implementation Guide](./architecture/gpt-context/gpt-context-implementation-guide.md)** ✅ - Code-level details

### Quick Start

```bash
# Gather Ruby files for AI context (copies to clipboard)
gpt_context -i '**/*.rb' -e 'spec/**/*' -d

# Save to file with tree structure
gpt_context -i 'lib/**/*.rb' -f tree,content -o context.txt

# Generate aider command
gpt_context -i 'lib/**/*.rb' -f aider -p "Add logging to all methods"

# JSON format for structured output
gpt_context -i 'src/**/*.ts' -f json -o codebase.json
```

---

## 📖 Other Tools (Guides)

Smaller utilities with usage documentation:

| Tool | Purpose | Status |
|------|---------|--------|
| **[VideoFileNamer](./guides/tools/video-file-namer.md)** | Generate structured video segment filenames | ✅ |
| **[YouTube Manager](./guides/tools/youtube-manager.md)** | Manage YouTube video metadata via API | ✅ |
| **[Subtitle Processor](./guides/tools/subtitle-processor.md)** | Clean and merge SRT subtitle files | ✅ |
| **[Configuration Tool](./guides/tools/configuration.md)** | Manage JSON config files | ✅ |
| **[YouTube Automation](./guides/tools/youtube-automation.md)** | Prompt sequence automation | ✅ |
| **[Prompt Tools](./guides/tools/prompt-tools.md)** | OpenAI completion wrapper (deprecated API) | ✅ |
| **[Move Images](./guides/tools/move-images.md)** | Organize video asset images | ✅ |
| **[Name Manager](./guides/tools/name-manager.md)** | Naming utilities and conventions | ✅ |
| **[CLI Actions](./guides/tools/cli-actions.md)** | Base CLI action patterns | ✅ |
| **[Bank Reconciliation](./guides/tools/bank-reconciliation.md)** | DEPRECATED | ✅ |

### Platform-Specific

- **[Windows Setup](./guides/platforms/windows/)** ✅ - Windows/WSL installation
  - [Installation Guide](./guides/platforms/windows/installation.md) ✅
  - [Testing Plan](./guides/platforms/windows/dam-testing-plan-windows-powershell.md) ✅

### Configuration

- **[Configuration Setup Guide](./guides/configuration-setup.md)** ✅ - Complete configuration reference
  - Quick start, file locations, settings reference
  - Migration from legacy configs
  - Backup and recovery

#### Future Configuration Guides

- **Settings Deep Dive** 📝 (detailed explanation of each setting)
- **Channels System** 📝 (YouTube channel management)
- **Brands System** 📝 (multi-brand/multi-tenant architecture)
- **Advanced Configuration** 📝 (environment-specific configs, team setups)

---

## 🏗️ General Architecture

Cross-cutting architectural documentation:

### CLI Architecture

- **[CLI Patterns](./architecture/cli/cli-patterns.md)** ✅ - CLI architecture patterns
- **[CLI Pattern Comparison](./architecture/cli/cli-pattern-comparison.md)** ✅ - Visual pattern guide

### Configuration Systems

- **[Configuration Systems Analysis](./architecture/configuration/configuration-systems.md)** ✅ - How brands/channels/NameManager relate

### Design Decisions (General)

- **[001 - Unified Brands Configuration](./architecture/design-decisions/001-unified-brands-config.md)** ✅ COMPLETED
- **[Session: 2025-11-09 DAM Refactoring](./architecture/design-decisions/session-2025-11-09.md)** ✅

---

## 📋 Templates (Copy These)

Ready-to-use configuration templates:

- **[settings.example.json](./templates/settings.example.json)** ✅ - Settings template
- **[channels.example.json](./templates/channels.example.json)** ✅ - Channels template
- **[.env.example](./templates/.env.example)** ✅ - Environment variables template
- **brands.example.json** 📝 (not yet created)

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

- **[CODEX Recommendations](./development/codex-recommendations.md)** ✅ - AI coding guidelines

### Future Development Topics

- **Contributing Guide** 📝 (how to contribute, PR process, coding standards)
- **Testing Guide** 📝 (how to run tests, write specs, coverage requirements)
- **Release Process** 📝 (semantic versioning, CI/CD, gem publishing)
- **Development Setup** 📝 (rbenv, bundler, guard, development workflow)

---

## 🗄️ Archive

Historical and deprecated documentation:

- **[Archive](./archive/)** ✅ - Deprecated documentation

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
│   │   ├── gpt-context.md                         # GPT Context usage
│   │   ├── youtube-manager.md
│   │   ├── subtitle-processor.md
│   │   ├── configuration.md
│   │   └── ... (11 tool guides total)
│   │
│   └── platforms/                                 # Platform-specific setup
│       └── windows/
│           ├── README.md
│           ├── installation.md
│           └── dam-testing-plan-windows-powershell.md
│
├── architecture/                                  # WHY/HOW systems work
│   ├── dam/                                       # DAM system documentation
│   │   ├── implementation-roadmap.md              # ⭐ START HERE
│   │   ├── dam-vision.md
│   │   ├── dam-data-model.md
│   │   ├── dam-visualization-requirements.md
│   │   ├── dam-cli-enhancements.md
│   │   ├── dam-cli-implementation-guide.md
│   │   ├── jan-collaboration-guide.md
│   │   └── design-decisions/
│   │       ├── 002-client-sharing.md
│   │       └── 003-git-integration.md
│   │
│   ├── gpt-context/                               # GPT Context documentation
│   │   ├── gpt-context-vision.md                  # Strategic vision
│   │   ├── gpt-context-architecture.md            # Data flow & components
│   │   └── gpt-context-implementation-guide.md    # Code-level details
│   │
│   ├── cli/                                       # CLI architecture
│   │   ├── cli-patterns.md
│   │   └── cli-pattern-comparison.md
│   │
│   ├── configuration/                             # Configuration system
│   │   └── configuration-systems.md
│   │
│   └── design-decisions/                          # General PRDs, ADRs
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
| **Gather code for AI** | [GPT Context Usage](./guides/tools/gpt-context.md) |
| **Understand GPT Context design** | [GPT Context Architecture](./architecture/gpt-context/gpt-context-architecture.md) |
| **Extend GPT Context** | [GPT Context Implementation](./architecture/gpt-context/gpt-context-implementation-guide.md) |
| **Video storage management** | [DAM Usage](./guides/tools/dam/dam-usage.md) |
| **S3 sync for collaboration** | [DAM Usage](./guides/tools/dam/dam-usage.md) |
| **Understand DAM architecture** | [DAM Data Model](./architecture/dam/dam-data-model.md) |
| **Build DAM dashboard** | [Visualization Requirements](./architecture/dam/dam-visualization-requirements.md) |
| **DAM development** | [Implementation Roadmap](./architecture/dam/implementation-roadmap.md) ⭐ |
| **Manage YouTube videos** | [YouTube Manager](./guides/tools/youtube-manager.md) |
| **Process subtitles** | [Subtitle Processor](./guides/tools/subtitle-processor.md) |
| **Configure tools** | [Configuration Tool](./guides/tools/configuration.md) |
| **Set up on Windows** | [Windows Setup](./guides/platforms/windows/) |
| **Build new CLI tool** | [CLI Patterns](./architecture/cli/cli-patterns.md) |
| **Understand system design** | [Configuration Systems](./architecture/configuration/configuration-systems.md) |

### By Audience

| Audience | Start Here |
|----------|------------|
| **AI-Assisted Developers** | [GPT Context Usage](./guides/tools/gpt-context.md) |
| **GPT Context Contributors** | [GPT Context Implementation](./architecture/gpt-context/gpt-context-implementation-guide.md) |
| **Video Creators** | [DAM Usage](./guides/tools/dam/dam-usage.md) |
| **DAM Developers** | [Implementation Roadmap](./architecture/dam/implementation-roadmap.md) ⭐ |
| **End Users** | [Guides](#-other-tools-guides) - Individual tool documentation |
| **Windows Users** | [Windows Setup](./guides/platforms/windows/) |
| **Team Members (Jan)** | [Jan Collaboration Guide](./architecture/dam/jan-collaboration-guide.md) |
| **Contributors** | [CLI Patterns](./architecture/cli/cli-patterns.md) |
| **Architects** | [Architecture](#%EF%B8%8F-general-architecture) - System design |

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

**Last updated**: 2025-12-06
