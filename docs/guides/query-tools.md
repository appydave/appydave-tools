---
title: Query Tools — brain, OMI, and LLM Context Pipeline
category: guides
tools: [query_brain, query_omi, llm_context]
status: active
created: 2026-04-04
---

# Query Tools — Brain, OMI, and LLM Context Pipeline

## Purpose

Three tools work together as a **file selection and context assembly pipeline** for AI-assisted workflows:

| Tool | Role | Output |
|------|------|--------|
| `query_brain` | Select brain knowledge files | File paths or JSON metadata |
| `query_omi` | Select OMI conversation files | File paths or JSON metadata |
| `llm_context` | Assemble file content for LLM | Tree listing or full content |

The tools are **composable**: query tools select files, `llm_context` loads them.

---

## What Is Being Queried

### query_brain
Reads `~/dev/ad/brains/audit/brains-index.json` — a pre-built index of all brain folders. Does **not** scan brain files at query time. The index contains per-brain metadata: name, category, activity_level, tags, status, file_count.

Brain folders live at `~/dev/ad/brains/<brain-name>/`. Each has an `INDEX.md` and optional content files.

### query_omi
Scans `~/dev/raw-intake/omi/*.md` and reads YAML frontmatter from each file. Enriched files (processed by Gemini extraction) have rich frontmatter. Raw files (unprocessed transcripts) have minimal frontmatter. Default behaviour: **enriched files only**.

### llm_context
Takes file paths (from stdin or arguments) and assembles content for LLM consumption. Two formats: `tree` (file listing) and `content` (file listing + full file content).

---

## query_brain API

```bash
query_brain [options]
```

| Flag | Description |
|------|-------------|
| `--find TERM` | Find brain by name, alias, or tag — unified search (repeatable) |
| `--category CAT` | All brains in a category (repeatable) |
| `--active` | All high-activity brains |
| `--files-only` | Exclude INDEX.md, return content files only |
| `--meta` | Return JSON metadata instead of file paths |

### Categories (as of 2026-04)
`claude-core`, `agent-frameworks`, `agent-systems`, `infrastructure`, `content-production`, `brand-strategy`, `knowledge-capture`, `client-infrastructure`, `lifestyle`, `private`

### Activity Levels
`high` (29 brains), `medium`, `low`, `none`

### Search Resolution Order (--find)
1. Exact brain name match
2. Alias match (from alias_index in brains-index.json)
3. Substring match on brain name
4. Tag match (falls through to tag_index)

### Examples
```bash
# Find a specific brain (name, partial name, or tag all work)
query_brain --find paperclip
query_brain --find agentic-engineering   # searches by tag

# Browse a category
query_brain --category agent-systems
query_brain --category agent-systems --category agent-frameworks

# All high-activity brains
query_brain --active

# Metadata instead of file paths
query_brain --active --meta
query_brain --find paperclip --meta
```

### --meta Output Structure
```json
[
  {
    "name": "paperclip",
    "category": "agent-systems",
    "activity_level": "high",
    "status": "active",
    "tags": ["paperclip", "multi-agent", "orchestration"],
    "file_count": 6
  }
]
```

---

## query_omi API

```bash
query_omi [options]
```

| Flag | Description |
|------|-------------|
| `--brain NAME` | Sessions where this brain appears in matched_brains |
| `--routing TYPE` | Filter by routing tag (pipe-delimited values supported) |
| `--activity ACT` | Filter by activity type (pipe-delimited values supported) |
| `--days N` | Sessions from the last N days (based on extracted_at) |
| `--limit N` | Return at most N results, most recent first |
| `--meta` | Return JSON metadata instead of file paths |

### Routing Values
`brain-update`, `til`, `todo-item`, `personal`, `archive`

### Activity Values
`planning`, `meeting`, `learning`, `debugging`, `reviewing`, `building`, `teaching`

### Enriched Frontmatter Structure
```yaml
signal: work
extraction_summary: "One-sentence summary of the conversation"
extracted_at: 2026-04-03
matched_brains: [agentic-os, anthropic-claude, paperclip]
activity: meeting|planning|learning
routing: brain-update
people_present: [david, nick]
people_mentioned: [boris]
entities_tools: [Claude, Gemini, Archon]
entities_projects: [Agent Workflow Builder]
entities_concepts: [token economics, RAG, prompt caching]
overflow_topics: [Thai chocolate, mask hardware]
```

### Examples
```bash
# Sessions flagged for brain updates (your backlog)
query_omi --routing brain-update
query_omi --routing brain-update --limit 10

# Recent planning sessions
query_omi --activity planning --days 7

# Everything related to a specific brain
query_omi --brain paperclip

# Metadata view — summaries without loading full files
query_omi --routing brain-update --limit 5 --meta
query_omi --brain paperclip --days 14 --meta
```

### --meta Output Structure
```json
[
  {
    "file": "2026-04-03-1705-group-debates.md",
    "extracted_at": "2026-04-03",
    "extraction_summary": "A group discusses LLM usage and agentic workflows...",
    "matched_brains": ["agentic-os", "anthropic-claude", "paperclip"],
    "activity": "meeting|planning",
    "routing": "brain-update",
    "entities_tools": ["Claude", "Gemini", "Archon"],
    "entities_projects": ["Archon"],
    "entities_concepts": ["token economics", "RAG"]
  }
]
```

---

## Pipeline Patterns

### Content pipeline — load files into LLM context
```bash
# Brain knowledge files → LLM
query_brain --find paperclip | xargs llm_context.rb -i -f content

# OMI sessions → LLM
query_omi --brain paperclip --limit 5 | xargs llm_context.rb -i -f content

# Mixed: brain + OMI for a topic
{ query_brain --find paperclip; query_omi --brain paperclip --limit 5; } | sort -u | xargs llm_context.rb -i -f content
```

### Metadata pipeline — summaries direct to LLM (no llm_context needed)
```bash
# What's in my brain-update backlog?
query_omi --routing brain-update --meta

# What are all my active brains?
query_brain --active --meta

# What OMI sessions touched paperclip recently?
query_omi --brain paperclip --days 14 --meta
```

### Discovery pattern — bounded queries for randomizer
```bash
# These return 1–20 results — good for random surfacing
query_brain --find paperclip            # 1 brain
query_brain --category agent-systems   # ~10 brains
query_omi --brain paperclip            # ~10 sessions
query_omi --routing til --limit 5      # 5 things-I-learned
```

---

## Two Different Data Shapes

**Brain files** are **curated knowledge** — processed, structured, human-maintained. High signal density. Use when you want what is known and confirmed.

**OMI files** are **conversation transcripts** — raw or AI-enriched recordings of spoken work sessions. Variable quality. Use when you want recent context, planning discussions, or to find what should be promoted into a brain.

These are intentionally separate query tools. Do not combine them by default.

---

## Key Files

| File | Purpose |
|------|---------|
| `/Users/davidcruwys/dev/ad/brains/audit/brains-index.json` | Brain index — built by brain-librarian |
| `/Users/davidcruwys/dev/raw-intake/omi/*.md` | OMI conversation transcripts |
| `/Users/davidcruwys/dev/ad/appydave-tools/bin/query_brain.rb` | Brain query CLI |
| `/Users/davidcruwys/dev/ad/appydave-tools/bin/query_omi.rb` | OMI query CLI |
| `/Users/davidcruwys/dev/ad/appydave-tools/bin/llm_context.rb` | File content assembler |
| `/Users/davidcruwys/dev/ad/appydave-tools/exe/query_brain` | Gem-installed wrapper |
| `/Users/davidcruwys/dev/ad/appydave-tools/exe/query_omi` | Gem-installed wrapper |
| `/Users/davidcruwys/dev/ad/appydave-tools/lib/appydave/tools/brain_context/brain_finder.rb` | BrainQuery implementation |
| `/Users/davidcruwys/dev/ad/appydave-tools/lib/appydave/tools/brain_context/omi_finder.rb` | OmiQuery implementation |
| `/Users/davidcruwys/dev/ad/appydave-tools/lib/appydave/tools/brain_context/options.rb` | Shared options struct |

---

## Rebuilding the Brain Index

The `brains-index.json` is not auto-updated. When brain folders change, rebuild it:

```bash
python /Users/davidcruwys/dev/ad/brains/.claude/skills/brain-librarian/scripts/build_brain_index.py build --all /Users/davidcruwys/dev/ad/brains
```

OMI files are queried directly — no index rebuild needed.

---

## Design Decisions

- **query_brain and query_omi are separate tools** — brains are confirmed knowledge, OMI is conversation. Different trust levels.
- **`--meta` bypasses llm_context** — metadata is already summarised; loading full file content adds tokens without value for discovery use cases.
- **enriched_only defaults to true** in query_omi — raw transcripts have no frontmatter to filter on; they're noise in most query contexts.
- **`--find` unifies name/alias/tag** — users shouldn't need to know whether something is a name or a tag.
- **`--active` standalone** — returns all 29 high-activity brains without needing to enumerate categories.
