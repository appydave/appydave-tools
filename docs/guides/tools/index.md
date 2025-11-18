# AppyDave Tools Documentation

Complete documentation for all appydave-tools with practical examples and AI agent use cases.

## Quick Navigation

### Core Content Tools

| Tool | Purpose | Status | Read Time |
|------|---------|--------|-----------|
| **[gpt-context](gpt-context.md)** | Gather project files for AI context | ✅ Active | 10 min |
| **[youtube-manager](youtube-manager.md)** | Manage YouTube video metadata | ✅ Active | 8 min |
| **[subtitle-processor](subtitle-processor.md)** | Clean and merge SRT files | ✅ Active | 7 min |
| **[move-images](move-images.md)** | Organize image assets for videos | ✅ Active | 8 min |

### Workflow & Automation Tools

| Tool | Purpose | Status | Read Time |
|------|---------|--------|-----------|
| **[youtube-automation](youtube-automation.md)** | Orchestrate YouTube workflows | ✅ Active | 8 min |
| **[configuration](configuration.md)** | Multi-channel setup & management | ✅ Active | 9 min |
| **[cli-actions](cli-actions.md)** | Framework for CLI tools | ✅ Infrastructure | 10 min |
| **[name-manager](name-manager.md)** | Parse and generate project names | ✅ Infrastructure | 8 min |

### Legacy & Specialized Tools

| Tool | Purpose | Status | Read Time |
|------|---------|--------|-----------|
| **[prompt-tools](prompt-tools.md)** | Text completion (OpenAI API) | ⚠️ Deprecated | 6 min |
| **[bank-reconciliation](bank-reconciliation.md)** | Process transaction data | ✅ Private | 8 min |

---

## Tool Categories

### 🎥 Video Production Tools

For managing video content workflows:

1. **[youtube-manager](youtube-manager.md)** - Update video metadata at scale
2. **[subtitle-processor](subtitle-processor.md)** - Clean and merge subtitles
3. **[move-images](move-images.md)** - Organize image assets
4. **[youtube-automation](youtube-automation.md)** - Automate workflows

### 🤖 AI & Context Tools

For working with AI assistants:

1. **[gpt-context](gpt-context.md)** - Gather files for AI (most important for AI agents)
2. **[prompt-tools](prompt-tools.md)** - Legacy OpenAI API (deprecated)

### ⚙️ Infrastructure Tools

For system setup and management:

1. **[configuration](configuration.md)** - Channel and API setup
2. **[cli-actions](cli-actions.md)** - Build custom CLI tools
3. **[name-manager](name-manager.md)** - Project naming patterns

### 💰 Financial Tools

For personal financial management:

1. **[bank-reconciliation](bank-reconciliation.md)** - Process transactions

---

## Getting Started

### First Time Users

1. **Read [configuration](configuration.md)** - Set up your channels
2. **Choose your workflow**:
   - Video content? → Start with [youtube-manager](youtube-manager.md)
   - AI assistance? → Start with [gpt-context](gpt-context.md)
   - Subtitles? → Read [subtitle-processor](subtitle-processor.md)

### For AI Agents

Each tool document includes **10 AI agent use cases** showing how AI can leverage the tool:

- **Code Review** - Gather context, analyze
- **Bug Fixing** - Understand codebase, suggest fixes
- **Automation** - Orchestrate workflows
- **Batch Processing** - Handle multiple items
- **Integration** - Combine tools for complex tasks

→ Check "Use Cases for AI Agents" section in each tool doc

### Command Examples

Quick reference for most-used commands:

```bash
# Gather context for AI
gpt_context -i '**/*.rb' -e 'spec/**/*' -d -o context.txt

# Get YouTube video details
youtube_manager get -v dQw4w9WgXcQ

# Update video metadata
youtube_manager update -v dQw4w9WgXcQ -t "New Title" -d "New description"

# Clean SRT subtitles
subtitle_processor clean -f input.srt -o output.srt

# Organize image assets
move_images -f project-name intro city-skyline

# Set up configuration
configuration create-channel
```

---

## Documentation Structure

Each tool document includes:

### 📝 "What It Does"
- Clear description of the tool's purpose
- What problems it solves
- Key capabilities

### 📖 "How to Use"
- Practical, copy-paste examples
- Common usage patterns
- Command reference with all options
- Configuration details

### 🤖 "Use Cases for AI Agents"
- **10 specific scenarios** showing AI agent integration
- Examples of how AI can discover and use the tool
- Workflow coordination examples
- Batch processing patterns

### 🔧 "Command Reference"
- Complete option lists
- Parameter descriptions
- Required vs optional flags
- Examples for each option

### 🐛 "Troubleshooting"
- Common issues and solutions
- Error messages and fixes
- FAQ section
- Configuration problems

### 💡 "Tips & Tricks"
- Best practices
- Efficiency suggestions
- Common patterns
- Performance tips

---

## Tool Relationships

### Data Flow

```
Downloaded Images
       ↓
[move-images]
       ↓
Organized Assets
       ↓
[youtube-manager]
       ↓
Video Metadata
       ↓
[youtube-automation]
       ↓
Published Videos
```

### AI Agent Workflow

```
Codebase
       ↓
[gpt-context]
       ↓
Project Context
       ↓
AI Agent
       ↓
Analysis/Code/Docs
```

### Configuration Hub

```
[configuration]
     ↓ provides setup for ↓
[youtube-manager]
[youtube-automation]
[gpt-context]
[cli-actions]
```

---

## Key Features Across Tools

### Parallel to Understand

**All tools follow consistent patterns:**

- **Option parsing**: `-i` for input, `-o` for output, `-d` for debug
- **Multiple patterns**: Can process multiple files with patterns
- **Flexible output**: Clipboard, file, or both
- **Help available**: All tools support `-h` or `--help`
- **Batch capable**: Most tools can process multiple items

### Common Options Across Tools

| Option | Meaning | Tools Using It |
|--------|---------|----------------|
| `-i` | Include/input | gpt_context, bank_reconciliation |
| `-e` | Exclude | gpt_context |
| `-o` | Output | gpt_context, subtitle_processor, others |
| `-d` | Debug | gpt_context, youtube_automation |
| `-f` | File/folder | subtitle_processor, bank_reconciliation |
| `-v` | Video ID | youtube_manager, get_video_action |
| `-t` | Title | youtube_manager, update_video_action |

---

## Use Case Finder

**Looking for a specific task?**

- **Batch update 50 YouTube videos?** → [youtube-manager](youtube-manager.md) + script
- **Understand a codebase before refactoring?** → [gpt-context](gpt-context.md)
- **Fix corrupted subtitles?** → [subtitle-processor](subtitle-processor.md)
- **Set up multi-channel YouTube?** → [configuration](configuration.md)
- **Prepare images for video?** → [move-images](move-images.md)
- **Build custom CLI tool?** → [cli-actions](cli-actions.md)
- **Manage project names?** → [name-manager](name-manager.md)
- **Automate video workflows?** → [youtube-automation](youtube-automation.md)
- **Process bank data?** → [bank-reconciliation](bank-reconciliation.md)

---

## Related Documentation

### Archive & Reference

- `archive/` folder contains:
  - `documentation-framework-proposal.md` - How we organize docs
  - `test-coverage-quick-wins.md` - Testing priorities
  - `codebase-audit-2025-01.md` - Codebase inventory
  - Other reference materials

### Digital Asset Management

- `dam/` folder contains:
  - `overview.md` - DAM system design

---

## Contributing to Documentation

### To Add Use Cases
Each tool has 10 AI agent use cases. To add more:
1. Open the tool's `.md` file
2. Find "Use Cases for AI Agents" section
3. Add new numbered use case with:
   - Brief command example
   - Bold "AI discovers:" line explaining what the agent learns
   - How the agent can apply it

### To Fix or Improve
- Suggest improvements via PR
- Follow the structure: What → How → Use Cases
- Keep examples practical and copy-paste ready

---

## Quick Command Cheat Sheet

```bash
# AI Context (most important for AI agents)
gpt_context -i '**/*.rb' -e 'spec/**/*' -d -o context.txt

# YouTube Operations
youtube_manager get -v VIDEO_ID
youtube_manager update -v VIDEO_ID -t "Title" -d "Description"

# Subtitles
subtitle_processor clean -f input.srt -o output.srt
subtitle_processor join -d ./ -f "*.srt" -o merged.srt

# Assets
move_images -f project-name section prefix

# Setup
configuration create-channel
configuration validate

# Automation
youtube_automation execute workflow_name
youtube_automation status job_id
```

---

## Status Legend

- ✅ **Active** - Stable, regularly used in production
- ⚠️ **Deprecated** - Still works but plan to migrate
- 🔧 **Maintenance** - Works, not actively developed
- 🟢 **Infrastructure** - Internal framework/utilities
- 🔴 **Private** - Personal/financial tools, not for sharing

---

**Last Updated**: November 2024
**Total Documentation**: ~2,900 lines
**Tools Documented**: 10
**Use Cases**: 100+ (10 per tool)

**Start reading**: Choose a tool above that matches your task!
