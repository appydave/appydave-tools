# GPT Context Gatherer - Vision & Strategy

**Purpose**: Enable AI-assisted development by efficiently packaging codebase context for Large Language Models.

---

## What Problem Does This Solve?

When working with AI assistants (Claude, ChatGPT, Copilot, Cursor), the quality of AI output directly correlates with the quality of context provided. Developers face these challenges:

1. **Manual file copying is tedious** - Selecting, opening, copying dozens of files wastes time
2. **Context limits are real** - LLMs have token limits; you can't feed entire codebases
3. **Relevance matters** - AI needs focused, relevant context, not noise
4. **Format affects comprehension** - AI understands structured input better than random dumps

**GPT Context Gatherer** solves these by automating intelligent context collection.

---

## Core Philosophy

### Single Purpose

GPT Context does ONE thing well: **gather project files into AI-ready format**.

It is NOT:
- A code search tool (use grep, ripgrep, Glob)
- A file manager (use Finder, ls)
- An AI assistant (use Claude, ChatGPT)
- A documentation generator (use YARD, RDoc)

### Developer-Centric Design

- **Command-line first** - Integrates with existing dev workflows
- **Pattern-based** - Uses familiar glob patterns developers already know
- **Clipboard-friendly** - Default output to clipboard for immediate paste
- **Composable** - Works with other tools (aider, scripts, pipelines)

### Format Flexibility

Different AI tasks need different context formats:

| Task | Best Format | Why |
|------|-------------|-----|
| Understanding structure | `tree` | Visual hierarchy |
| Code review | `content` | Full source code |
| API documentation | `json` | Structured data |
| AI-assisted coding | `aider` | Tool-specific format |

---

## Target Workflows

### Primary: AI-Assisted Development

```bash
# Quick context for Claude/ChatGPT question
gpt_context -i 'lib/auth/**/*.rb' -d

# Paste into AI chat, ask: "How does authentication work?"
```

### Secondary: aider Integration

```bash
# Generate aider command with files and prompt
gpt_context -i 'lib/api/**/*.rb' -f aider -p "Add rate limiting to these endpoints"
```

### Tertiary: Documentation & Onboarding

```bash
# Generate codebase overview for new team member
gpt_context -i 'lib/**/*.rb' -e 'spec/**/*' -f tree -o codebase-overview.txt
```

---

## Design Principles

### 1. Reasonable Defaults

- **Default output**: `clipboard` (most common use case)
- **Default format**: `tree,content` (structure + code)
- **Default debug**: `none` (quiet operation)

Users shouldn't need to specify common options.

### 2. Explicit Over Implicit

- Patterns are explicit (`'lib/**/*.rb'`), not magic
- Include patterns are additive, exclude patterns are subtractive
- Output targets are specified, not guessed

### 3. Non-Destructive

- Never modifies source files
- Clipboard is the only "destructive" default (overwrites previous clipboard)
- File output requires explicit `-o` flag

### 4. Transparent Operation

- Debug modes show exactly what's happening
- `params` shows configuration
- `info` shows collected content
- `debug` shows everything

---

## Relationship to Other Tools

### vs. DAM (Digital Asset Management)

| Aspect | GPT Context | DAM |
|--------|-------------|-----|
| **Purpose** | Collect code for AI context | Manage video project storage |
| **Input** | Source code files | Video assets (MP4, SRT, etc.) |
| **Output** | Text (clipboard/file) | Cloud/SSD storage |
| **Pattern** | Glob patterns | Brand/project structure |
| **State** | Stateless | Stateful (sync tracking) |
| **External services** | None | AWS S3 |

### vs. Built-in Tools

| Need | Use This |
|------|----------|
| Find files by name | `Glob`, `find` |
| Search file contents | `Grep`, `rg` |
| Package files for AI | **GPT Context** |
| Read single file | `Read`, `cat` |

---

## Evolution Roadmap

### Current State (v1.x)

- ✅ Pattern-based file collection
- ✅ Multiple output formats (tree, content, json, aider)
- ✅ Multiple output targets (clipboard, files)
- ✅ Line limiting for large files
- ✅ Base directory support

### Potential Enhancements

These are ideas, not commitments:

1. **Token counting** - Show estimated token count for context
2. **Smart truncation** - Automatically fit within token limits
3. **Preset patterns** - Named pattern sets (e.g., `--preset ruby-lib`)
4. **History** - Remember recent patterns per project
5. **MCP integration** - Expose as Model Context Protocol server

### Non-Goals

These will NOT be added:

- File editing capabilities
- Version control integration (that's git's job)
- Remote file access (that's DAM's job)
- AI inference (that's the AI's job)

---

## Success Metrics

GPT Context is successful when:

1. **Time saved** - Faster than manual file selection
2. **Context quality** - AI produces better responses with gathered context
3. **Adoption** - Becomes natural part of AI-assisted workflow
4. **Simplicity** - Learned in minutes, remembered for months

---

**Related Documentation**:
- [Architecture & Data Flow](./gpt-context-architecture.md)
- [Implementation Guide](./gpt-context-implementation-guide.md)
- [Usage Guide](../../guides/tools/gpt-context.md)
