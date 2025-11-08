# AppyDave Tools - Purpose & Philosophy

## Overview

**AppyDave Tools** is a consolidated productivity toolkit built for AppyDave's YouTube content creation workflow. All utilities live in one repository for easier maintenance compared to managing separate codebases.

## Philosophy

### Consolidated Toolkit
- **One repository** - All tools in single codebase for easier management
- **YouTube workflow focus** - Built specifically for content creator productivity
- **Single-purpose utilities** - Each tool solves one specific problem
- **Independent operation** - Tools work standalone, no forced dependencies
- **Shareable individually** - Individual tools can be featured in standalone videos

### AppyDave Context
- Built for AppyDave's specific workflows and needs
- Published publicly as part of AppyDave's knowledge sharing
- Tools demonstrate productivity techniques for YouTube creators
- Language-agnostic approach (currently Ruby, could be rewritten if needed)

### Practical Implementation
- Solve real workflow problems quickly
- Iterate based on actual YouTube production usage
- Simple, working implementations
- Documentation reflects real content creation scenarios

## Tool Categories

### AI & Context Management
- **GPT Context Gatherer** - Collect project files for AI context analysis
- **Prompt Tools** - AI prompt completion workflows

### Content & Media
- **Subtitle Manager** - Process and join SRT subtitle files
- **YouTube Manager** - Manage YouTube video metadata via API
- **YouTube Automation** - Automated YouTube workflows with GPT agents
- **Move Images** - Organize downloaded images into project folders

### Configuration
- **Configuration Tool** - Manage multi-channel and project configurations

## Design Principles

1. **CLI-First** - Command-line tools for speed and scriptability
2. **Single-Purpose** - Each tool does one thing well
3. **Independent** - No forced dependencies between tools
4. **Documented** - Clear examples for real-world usage
5. **Open Source** - MIT licensed for community benefit

## Integration Options

### Claude Code Integration
- Future: Claude skill interface to access tools directly
- Current: Standard CLI usage from terminal

### Sharing with Other Projects
When sharing these tools, three key paths to reference:
1. **Project root** - `/Users/davidcruwys/dev/ad/appydave-tools/`
2. **Tools directory** - `/Users/davidcruwys/dev/ad/appydave-tools/bin/`
3. **Documentation** - `/Users/davidcruwys/dev/ad/appydave-tools/docs/`

## Repository Strategy

### Why One Codebase?
- **Easier maintenance** - Single repo vs managing multiple separate repos
- **Version control** - Already established with semantic-release
- **Shared infrastructure** - Common testing, linting, CI/CD
- **Cohesive documentation** - All tools documented together

### Language Flexibility
- Currently implemented in Ruby
- Not tied to Ruby as identity - could be rewritten in another language
- Implementation language is a practical choice, not a constraint

## Use Cases

Primary use case is **AppyDave's YouTube workflow**, including:
- **Developers** - Gathering code context for AI assistants
- **Content Creators** - Video subtitle management, metadata updates
- **Automators** - Scripting repetitive YouTube tasks
- **Multi-Channel Managers** - Managing configurations across channels

## Future Direction

- Add new tools as AppyDave workflow needs arise
- Individual tools may be featured in standalone video tutorials
- Keep tools independent and single-purpose
- Maintain public access for community learning
- Claude skill integration for easier access

## Not Goals

- ❌ Building a monolithic framework
- ❌ Creating tool dependencies or required workflows
- ❌ Enterprise-scale features or complexity
- ❌ Forcing users to adopt the entire suite

## Contributing

Contributions welcome for:
- Bug fixes to existing tools
- Documentation improvements
- New single-purpose tools that fit the workflow
- Performance improvements

Not looking for:
- Tools that create dependencies between existing utilities
- Framework-style architectures
- Features that complicate simple tools
