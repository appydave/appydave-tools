# Documentation Framework Proposal

**Purpose:** Define a comprehensive, maintainable documentation structure for AppyDave Tools

**Date:** January 2025

---

## Current State Analysis

### What We Have
```
docs/
├── ai-tool-discovery.md              # AI agent guide (excellent)
├── codebase-audit-2025-01.md         # Code quality audit
├── tool-documentation-analysis.md    # Doc quality assessment
├── purpose-and-philosophy.md         # Project philosophy
├── usage/
│   └── gpt-context.md                # Only 1 of 7 tools documented
└── dam/
    └── overview.md                   # Partial DAM tool docs

Root:
├── README.md                         # User-facing overview (good)
├── CLAUDE.md                         # AI assistant index (660 lines - too large)
├── CHANGELOG.md                      # Auto-generated
└── CODE_OF_CONDUCT.md                # Standard
```

### What's Missing
- **Individual tool documentation** (only 1 of 7 tools has detailed docs)
- **Development guides** (architecture, patterns, contributing)
- **API/module documentation** (internal code structure)
- **Troubleshooting guides** (common issues, debugging)
- **Testing documentation** (conventions, patterns, how to write tests)
- **Configuration examples** (JSON templates, .env examples)
- **Workflow guides** (FliVideo workflow, multi-channel setup)

### Problems with Current Structure
1. **CLAUDE.md is bloated** (660 lines - should be 100-200 line index)
2. **README.md duplicates content** (tool descriptions in both README and CLAUDE.md)
3. **No clear hierarchy** (usage/ has 1 file, dam/ orphaned)
4. **Missing cross-references** (docs don't link to each other)
5. **No versioning strategy** (which docs apply to which versions)

---

## Proposed Documentation Structure

```
appydave-tools/
│
├── README.md                         # 🎯 PRIMARY ENTRY POINT (100-150 lines)
├── CLAUDE.md                         # 🤖 AI AGENT INDEX (100-150 lines)
├── CHANGELOG.md                      # 📝 Auto-generated version history
├── CODE_OF_CONDUCT.md                # 🤝 Community standards
│
└── docs/
    │
    ├── 📑 INDEX.md                   # ⭐ DOCUMENTATION MAP (meta-index)
    │
    ├── 01-getting-started/           # 🚀 New user onboarding
    │   ├── installation.md
    │   ├── quick-start.md
    │   ├── first-time-setup.md
    │   └── common-workflows.md
    │
    ├── 02-tools/                     # 🛠️ Tool-specific documentation
    │   ├── gpt-context.md            # ⭐ PRIMARY TOOL
    │   ├── youtube-manager.md
    │   ├── subtitle-processor.md
    │   ├── configuration-manager.md
    │   ├── move-images.md
    │   ├── prompt-tools.md           # ⚠️ DEPRECATED
    │   └── youtube-automation.md     # ⚠️ INTERNAL
    │
    ├── 03-workflows/                 # 🎬 End-to-end scenarios
    │   ├── flivideo-production.md
    │   ├── multi-channel-management.md
    │   ├── ai-assisted-development.md
    │   ├── bulk-video-updates.md
    │   └── team-collaboration.md
    │
    ├── 04-configuration/             # ⚙️ Setup and config
    │   ├── overview.md
    │   ├── channels-config.md
    │   ├── settings-config.md
    │   ├── youtube-automation-config.md
    │   ├── environment-variables.md
    │   └── examples/                 # JSON templates
    │       ├── channels.example.json
    │       ├── settings.example.json
    │       └── .env.example
    │
    ├── 05-development/               # 👨‍💻 Developer documentation
    │   ├── architecture.md
    │   ├── code-conventions.md
    │   ├── testing-guide.md
    │   ├── contributing.md
    │   ├── release-process.md
    │   └── patterns/
    │       ├── base-action-pattern.md
    │       ├── configuration-system.md
    │       └── type-system.md
    │
    ├── 06-api-reference/             # 📚 Internal API docs
    │   ├── cli-actions/
    │   │   ├── base-action.md
    │   │   └── action-lifecycle.md
    │   ├── configuration/
    │   │   ├── config.md
    │   │   └── models.md
    │   ├── gpt-context/
    │   │   ├── file-collector.md
    │   │   └── output-handler.md
    │   ├── youtube-manager/
    │   │   ├── authorization.md
    │   │   └── api-wrapper.md
    │   ├── subtitle-processor/
    │   │   ├── clean.md
    │   │   └── join.md
    │   └── types/
    │       ├── base-model.md
    │       └── type-system.md
    │
    ├── 07-troubleshooting/           # 🔧 Problem solving
    │   ├── common-issues.md
    │   ├── bundler-rbenv.md
    │   ├── youtube-auth-errors.md
    │   ├── openai-api-errors.md
    │   └── debugging-guide.md
    │
    ├── 08-ai-assistance/             # 🤖 AI agent resources
    │   ├── tool-discovery.md         # ✅ EXISTS (ai-tool-discovery.md)
    │   ├── claude-code-guide.md      # How to use with Claude Code
    │   ├── chatgpt-integration.md    # Using with ChatGPT
    │   └── prompt-templates/
    │       ├── codebase-analysis.md
    │       └── debugging-assistance.md
    │
    ├── 09-philosophy/                # 💡 Project vision
    │   ├── purpose-and-philosophy.md # ✅ EXISTS
    │   ├── design-principles.md
    │   └── roadmap.md
    │
    └── 10-appendix/                  # 📎 Reference materials
        ├── codebase-audit-2025-01.md # ✅ EXISTS
        ├── tool-documentation-analysis.md # ✅ EXISTS
        ├── glossary.md
        └── migration-guides/
            └── subtitle-manager-to-processor.md
```

---

## Document Templates

### Template: Tool Documentation (`docs/02-tools/[tool-name].md`)

```markdown
# [Tool Name]

**Status:** ✅ ACTIVE | ⚠️ DEPRECATED | 🔒 INTERNAL

**CLI Command:** `tool_name`

**Gem Installation:** Available after `gem install appydave-tools`

---

## Quick Reference

\`\`\`bash
# Most common use case
tool_name [basic command]
\`\`\`

**When to use this tool:** [One sentence]

**Related tools:** [Links to related docs]

---

## Overview

### The Problem

[Clear problem statement from user perspective]

### The Solution

[How this tool solves the problem]

### What It Does

- **Operation 1**: [Description]
- **Operation 2**: [Description]

---

## Installation & Setup

### Prerequisites

- [Requirement 1]
- [Requirement 2]

### First-Time Setup

\`\`\`bash
[Setup commands]
\`\`\`

### Configuration

[If applicable, link to configuration docs]

---

## Usage Examples

### Basic Usage

\`\`\`bash
# Example 1: [Description]
tool_name [command]

# Example 2: [Description]
tool_name [command]
\`\`\`

### Advanced Usage

\`\`\`bash
# Example 3: [Description]
tool_name [command with options]
\`\`\`

### Real-World Scenarios

#### Scenario 1: [Name]

**Context:** [When you'd do this]

\`\`\`bash
[Commands]
\`\`\`

**Result:** [What happens]

---

## Command Reference

### Options

| Flag | Long Form | Description | Default |
|------|-----------|-------------|---------|
| `-x` | `--example` | [Description] | [Default] |

### Exit Codes

- `0` - Success
- `1` - [Error type]

---

## Troubleshooting

### Common Issues

#### Issue: [Problem description]
**Symptoms:** [What user sees]
**Solution:** [Fix]

#### Issue: [Another problem]
**Symptoms:** [What user sees]
**Solution:** [Fix]

### Debug Mode

\`\`\`bash
tool_name [command] --debug
\`\`\`

---

## Integration with Other Tools

- **Works with:** [Tool links]
- **Typical workflow:** [Brief description]
- **See also:** [Workflow docs link]

---

## API Reference

**For developers:** See [API docs link]

**Internal modules:**
- [Module 1 link]
- [Module 2 link]

---

## Contributing

See [Development Guide](../05-development/contributing.md)

**Test coverage:** [Percentage] - [Link to specs]

---

## Version History

- **Current version:** [Version] ([Changelog link])
- **Breaking changes:** [If applicable]
- **Deprecation notices:** [If applicable]

---

**Related Documentation:**
- [Workflow guide link]
- [Configuration guide link]
- [Troubleshooting link]
```

---

### Template: Workflow Documentation (`docs/03-workflows/[workflow-name].md`)

```markdown
# [Workflow Name]

**Use case:** [One sentence description]

**Tools used:** [List of tools]

**Time to complete:** [Estimate]

---

## Overview

[Brief description of this workflow and when to use it]

---

## Prerequisites

- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Configuration needed]

---

## Step-by-Step Guide

### Step 1: [Action]

**Why:** [Explanation]

\`\`\`bash
[Commands]
\`\`\`

**Expected result:** [What happens]

---

### Step 2: [Action]

**Why:** [Explanation]

\`\`\`bash
[Commands]
\`\`\`

**Expected result:** [What happens]

---

### Step 3: [Action]

[Continue pattern...]

---

## Complete Example

\`\`\`bash
# Full workflow from start to finish
[All commands in sequence]
\`\`\`

---

## Troubleshooting This Workflow

### If Step X Fails

[Debugging steps]

### Common Mistakes

- **Mistake 1:** [Description and fix]
- **Mistake 2:** [Description and fix]

---

## Variations

### Variation 1: [Name]

[How to adapt workflow]

### Variation 2: [Name]

[How to adapt workflow]

---

## Related Workflows

- [Link to related workflow 1]
- [Link to related workflow 2]

---

**See also:**
- [Tool documentation links]
- [Configuration guide links]
```

---

### Template: API Reference (`docs/06-api-reference/[module]/[class].md`)

```markdown
# [Class Name]

**Module:** `Appydave::Tools::[ModuleName]::[ClassName]`

**File:** `lib/appydave/tools/[path]/[file].rb`

**Test Coverage:** [Percentage] - [Spec file link]

---

## Overview

[Brief description of what this class does]

**Parent class:** [If applicable]

**Included modules:** [If applicable]

---

## Public API

### Instance Methods

#### `#method_name(param1, param2)`

**Description:** [What it does]

**Parameters:**
- `param1` (Type) - [Description]
- `param2` (Type) - [Description]

**Returns:** (Type) - [Description]

**Raises:**
- `ErrorType` - [When]

**Example:**

\`\`\`ruby
instance = ClassName.new
result = instance.method_name(arg1, arg2)
\`\`\`

---

### Class Methods

[Same structure as instance methods]

---

## Usage Examples

### Example 1: [Scenario]

\`\`\`ruby
[Code example]
\`\`\`

---

## Internal Implementation

**Design pattern:** [If applicable]

**Dependencies:**
- [Module 1]
- [Module 2]

---

## Testing

**Spec file:** `spec/appydave/tools/[path]/[file]_spec.rb`

**Coverage:** [Percentage]

**Example spec:**

\`\`\`ruby
RSpec.describe Appydave::Tools::ClassName do
  [Example test structure]
end
\`\`\`

---

## Related Classes

- [Link to related class 1]
- [Link to related class 2]

---

**See also:**
- [User-facing tool documentation]
- [Pattern documentation]
```

---

## Root File Specifications

### README.md (100-150 lines)

**Purpose:** Primary entry point for users discovering the project

**Structure:**
1. **Hero section** (1-2 lines) - What is this?
2. **Why this exists** (2-3 lines) - Problem statement
3. **Quick wins** (5 bullet points) - Value proposition
4. **Installation** (3 lines) - One command
5. **Tool index** (7 tools x 2 lines each) - Name + one-liner
6. **Quick start** (3 lines) - Simplest example
7. **Documentation links** (5 lines) - Where to go next
8. **Philosophy** (2 lines + link) - Brief mention
9. **Contributing** (3 lines + link)
10. **License** (2 lines)

**What NOT to include:**
- ❌ Full tool documentation (goes in docs/02-tools/)
- ❌ Command reference (goes in tool docs)
- ❌ Troubleshooting (goes in docs/07-troubleshooting/)
- ❌ Architecture details (goes in docs/05-development/)

---

### CLAUDE.md (100-150 lines)

**Purpose:** AI assistant index and quick reference

**Structure:**
1. **Project summary** (3 lines) - What is this?
2. **Quick reference table** (10 lines) - Tools + status
3. **Critical setup** (15 lines) - Bundler/rbenv fix
4. **Common commands** (20 lines) - Development, testing, build
5. **Documentation index** (30 lines) - Links to all docs
6. **AI assistant notes** (20 lines) - How to use docs effectively
7. **Key patterns** (10 lines) - Important code patterns to know

**What NOT to include:**
- ❌ Full command examples (link to tool docs)
- ❌ Detailed explanations (link to relevant docs)
- ❌ Security guides (link to troubleshooting)
- ❌ Configuration examples (link to config docs)

**Links to:**
- docs/INDEX.md (documentation map)
- docs/02-tools/ (individual tool docs)
- docs/08-ai-assistance/tool-discovery.md (for discovery)
- docs/07-troubleshooting/ (for common issues)

---

### docs/INDEX.md (50-75 lines)

**Purpose:** Documentation navigation hub

**Structure:**
1. **Quick navigation** - Links to all doc sections
2. **By audience** - New user, developer, AI agent paths
3. **By task** - "I want to..." links
4. **Documentation status** - Which docs are complete/WIP
5. **Contributing to docs** - How to add/update docs

---

## Documentation Principles

### 1. Single Source of Truth
- Each concept documented in ONE place
- Other docs link to that source
- No duplication between README, CLAUDE, and detailed docs

### 2. Progressive Disclosure
- README: Overview + links
- Tool docs: Usage + examples
- API docs: Implementation details
- Each layer deeper than the last

### 3. Task-Oriented
- Organize by "what user wants to do"
- Not "what the code structure is"
- Workflow guides > API docs for users

### 4. AI-Friendly
- Clear headings and structure
- Keywords for discovery
- Cross-references between docs
- Machine-readable formats where helpful

### 5. Maintainable
- Templates for consistency
- Clear ownership per doc
- Version-controlled
- CI checks for broken links

---

## Documentation Coverage Goals

### Phase 1: Foundation (Priority 1 - Do First)
- [ ] Slim down CLAUDE.md to 100-150 lines
- [ ] Create docs/INDEX.md
- [ ] Complete docs/02-tools/ for 5 active tools:
  - [ ] gpt-context.md ✅ (already exists)
  - [ ] youtube-manager.md
  - [ ] subtitle-processor.md
  - [ ] configuration-manager.md
  - [ ] move-images.md
- [ ] Create docs/01-getting-started/:
  - [ ] installation.md
  - [ ] quick-start.md
- [ ] Create docs/07-troubleshooting/bundler-rbenv.md

### Phase 2: Workflows (Priority 2)
- [ ] Complete docs/03-workflows/:
  - [ ] flivideo-production.md
  - [ ] multi-channel-management.md
  - [ ] ai-assisted-development.md
- [ ] Create docs/04-configuration/overview.md
- [ ] Add JSON examples to docs/04-configuration/examples/

### Phase 3: Development (Priority 3)
- [ ] Complete docs/05-development/:
  - [ ] architecture.md
  - [ ] testing-guide.md
  - [ ] contributing.md
- [ ] Create docs/06-api-reference/ for key modules:
  - [ ] cli-actions/base-action.md
  - [ ] configuration/config.md
  - [ ] types/base-model.md

### Phase 4: Polish (Priority 4)
- [ ] Complete remaining API reference docs
- [ ] Add more troubleshooting guides
- [ ] Create migration guides
- [ ] Add prompt templates for AI assistance

---

## Migration Strategy

### Step 1: Create Structure
1. Create directory structure (01-10 folders)
2. Create docs/INDEX.md
3. Create templates in each folder

### Step 2: Move Existing Docs
1. Keep: ai-tool-discovery.md → 08-ai-assistance/tool-discovery.md
2. Keep: purpose-and-philosophy.md → 09-philosophy/
3. Move: audits → 10-appendix/
4. Keep: usage/gpt-context.md → 02-tools/gpt-context.md

### Step 3: Extract from README/CLAUDE
1. Extract tool details from README → 02-tools/
2. Extract workflow info → 03-workflows/
3. Extract troubleshooting → 07-troubleshooting/
4. Slim down README to index + links
5. Slim down CLAUDE to index + links

### Step 4: Fill Gaps
1. Write missing tool docs (4 tools)
2. Write getting-started guides
3. Write key workflow guides
4. Write critical troubleshooting guides

### Step 5: Link Everything
1. Add cross-references between docs
2. Update README with doc links
3. Update CLAUDE.md with doc links
4. Update docs/INDEX.md

---

## Maintenance Plan

### Ownership
- **README.md**: Project maintainer
- **CLAUDE.md**: Project maintainer
- **docs/02-tools/**: Tool authors + maintainer
- **docs/03-workflows/**: Workflow users + maintainer
- **docs/05-development/**: Core contributors
- **docs/06-api-reference/**: Auto-generated where possible

### Review Schedule
- **Weekly**: Check for outdated examples
- **Per release**: Update version-specific docs
- **Quarterly**: Audit doc coverage vs codebase
- **Annually**: Major doc restructure if needed

### Quality Checks
- [ ] CI: Check for broken internal links
- [ ] CI: Check for missing required sections (per template)
- [ ] CI: Check that code examples are syntactically valid
- [ ] Manual: Verify examples work (spot-check per release)

---

## Success Metrics

### For Users
- Time to first successful tool use: < 5 minutes
- Can find answer to question: < 2 minutes
- Confidence in tool selection: > 90%

### For Contributors
- Time to understand codebase: < 30 minutes
- Can find where to add feature: < 5 minutes
- Can write conformant test: < 10 minutes

### For AI Agents
- Correct tool identification: > 95%
- Can generate working example: > 90%
- Finds relevant docs: < 30 seconds

### For Maintainers
- Time to update doc: < 15 minutes
- Doc coverage of codebase: > 80%
- Broken link rate: < 1%

---

## Notes on Implementation

### What to Write First
1. docs/INDEX.md (navigation hub)
2. Slim CLAUDE.md (AI agent index)
3. docs/02-tools/ for active tools (user-facing)
4. docs/07-troubleshooting/bundler-rbenv.md (critical pain point)
5. docs/01-getting-started/ (onboarding)

### What Can Wait
- Detailed API reference (06-api-reference/)
- Advanced workflow variations
- Comprehensive troubleshooting
- Historical appendix materials

### What Could Be Auto-Generated
- docs/06-api-reference/ (from YARD/RDoc comments)
- Command option tables (from OptionParser definitions)
- Test coverage stats (from SimpleCov)
- Changelog summaries (from git history)

---

## Open Questions

1. **Versioning**: Should docs be versioned per gem release? (Probably yes for breaking changes)
2. **Format**: Markdown vs alternatives? (Markdown is best for AI agents and GitHub)
3. **Hosting**: GitHub Pages? (Could render nice static site from markdown)
4. **Search**: Add search functionality? (GitHub search works, static site could add)
5. **Localization**: Support multiple languages? (Not priority, but structure should allow it)
6. **Examples**: Inline vs separate files? (Inline for short, separate for long/runnable)
7. **Video**: Add video tutorials? (Nice-to-have, links in markdown)

---

**Recommendation:** Start with Phase 1 (Foundation), validate with users/AI agents, then iterate based on feedback.

**Estimated Effort:**
- Phase 1: 8-12 hours
- Phase 2: 6-8 hours
- Phase 3: 10-15 hours
- Phase 4: 15-20 hours
- **Total:** 40-55 hours for complete framework implementation

**Priority Order:** Phase 1 > Phase 2 > Phase 4 > Phase 3 (skip API docs initially, focus on user/workflow docs)
