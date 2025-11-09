# AppyDave Tools Documentation

**Welcome to the AppyDave Tools documentation!**

This directory contains comprehensive documentation for all tools, features, and development guides.

---

## 📚 Quick Navigation

### User Documentation

- **[VAT (Video Asset Tools)](./vat/)** - Video project storage orchestration
  - [Usage Guide](./vat/usage.md) - Complete usage reference
  - [Testing Plan](./vat/vat-testing-plan.md) - User acceptance testing
  - [Implementation Status](./vat/vat-implementation-status.md) - Feature matrix
  - [Integration Plan](./vat/vat-integration-plan.md) - Migration details
  - [Refactoring Summary](./vat/vat-refactoring-summary.md) - Architecture changes

- **[Tools](./tools/)** - Individual tool documentation
  - GPT Context Gatherer
  - YouTube Manager
  - Subtitle Processor
  - Configuration Management
  - And more...

### Developer Documentation

- **[Development Guides](./development/)** - How to build tools
  - [CLI Architecture Patterns](./development/cli-architecture-patterns.md) - Pattern reference
  - [Pattern Comparison](./development/pattern-comparison.md) - Visual guide
  - [Quick Reference](./development/README.md) - Fast pattern selection

### System Documentation

- **[Project & Brand Systems Analysis](./project-brand-systems-analysis.md)** - Deep dive into overlapping systems
  - VAT system (storage orchestration)
  - Channels configuration (YouTube metadata)
  - NameManager (naming conventions)
  - Integration points and recommendations

### Archive

- **[Archive](./archive/)** - Deprecated documentation
  - Old versions of documentation
  - Historical reference material

---

## 🎯 Common Tasks

### "I want to use a tool"
→ See individual tool documentation in [`tools/`](./tools/) or [`vat/`](./vat/)

### "I want to build a new tool"
→ Start with [`development/README.md`](./development/README.md) for CLI pattern selection

### "I want to understand the architecture"
→ Read [`development/cli-architecture-patterns.md`](./development/cli-architecture-patterns.md)

### "I want to understand how systems relate"
→ Read [`project-brand-systems-analysis.md`](./project-brand-systems-analysis.md)

---

## 📂 Directory Structure

```
docs/
├── README.md (this file)                          # Documentation index
├── project-brand-systems-analysis.md              # System overlap analysis
│
├── vat/                                           # VAT documentation
│   ├── usage.md                                   # User guide
│   ├── vat-testing-plan.md                        # Testing guide
│   ├── vat-implementation-status.md               # Feature status
│   ├── vat-integration-plan.md                    # Integration details
│   └── vat-refactoring-summary.md                 # Architecture changes
│
├── tools/                                         # Individual tool docs
│   ├── gpt-context.md
│   ├── youtube-manager.md
│   ├── subtitle-processor.md
│   └── ... (more tools)
│
├── development/                                   # Developer guides
│   ├── README.md                                  # Quick reference
│   ├── cli-architecture-patterns.md               # Pattern guide
│   └── pattern-comparison.md                      # Visual comparison
│
└── archive/                                       # Old documentation
    └── ... (deprecated docs)
```

---

## 🔍 Finding What You Need

### By Tool Name

| Tool | Documentation |
|------|---------------|
| **VAT** | [`vat/usage.md`](./vat/usage.md) |
| **GPT Context** | [`tools/gpt-context.md`](./tools/gpt-context.md) |
| **YouTube Manager** | [`tools/youtube-manager.md`](./tools/youtube-manager.md) |
| **Subtitle Processor** | [`tools/subtitle-processor.md`](./tools/subtitle-processor.md) |
| **Configuration** | [`tools/configuration.md`](./tools/configuration.md) |

### By Task

| Task | Documentation |
|------|---------------|
| **Video storage management** | [`vat/usage.md`](./vat/usage.md) |
| **S3 sync for collaboration** | [`vat/usage.md`](./vat/usage.md) |
| **Gather AI context** | [`tools/gpt-context.md`](./tools/gpt-context.md) |
| **Manage YouTube videos** | [`tools/youtube-manager.md`](./tools/youtube-manager.md) |
| **Process subtitles** | [`tools/subtitle-processor.md`](./tools/subtitle-processor.md) |
| **Build new CLI tool** | [`development/cli-architecture-patterns.md`](./development/cli-architecture-patterns.md) |

### By Audience

| Audience | Start Here |
|----------|------------|
| **End Users** | Individual tool docs in [`tools/`](./tools/) or [`vat/`](./vat/) |
| **Developers** | [`development/README.md`](./development/README.md) |
| **Contributors** | [`development/cli-architecture-patterns.md`](./development/cli-architecture-patterns.md) |
| **Architects** | [`project-brand-systems-analysis.md`](./project-brand-systems-analysis.md) |

---

## 🆕 Recently Added

- **2025-11-09**: VAT refactoring to Pattern 2 architecture
- **2025-11-09**: CLI architecture patterns documentation
- **2025-11-09**: Project & brand systems analysis
- **2025-11-08**: VAT integration into appydave-tools

---

## 📝 Documentation Standards

All documentation in this repository follows the [AI Conventions](../../.ai-conventions.md):

- **File naming**: `kebab-case` for all markdown files
- **Exceptions**: `README.md`, `CHANGELOG.md`, `CLAUDE.md` (uppercase allowed)
- **Location**: Organized by category in subdirectories
- **Cross-referencing**: Relative links between documents

---

## 🤝 Contributing

When adding new documentation:

1. **Choose the right location**:
   - Tool documentation → `tools/`
   - VAT-specific → `vat/`
   - Developer guides → `development/`
   - System analysis → root of `docs/`

2. **Use kebab-case** for filenames (e.g., `my-new-tool.md`)

3. **Update this index** with a link to your new document

4. **Follow existing patterns** - check similar docs for style guidance

---

**Last updated**: 2025-11-09
