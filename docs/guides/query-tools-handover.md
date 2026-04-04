---
title: Handover — Query Tools Session (2026-04-04)
type: handover
---

# Handover — Query Tools Session (2026-04-04)

## What Was Built

Three tools in `appydave-tools` now work as a unified query pipeline:

- **`query_brain`** — queries the brains knowledge index
- **`query_omi`** — queries OMI conversation transcripts by frontmatter
- **`llm_context`** — assembles file content for LLM consumption (pre-existing, unchanged)

Full documentation: `/Users/davidcruwys/dev/ad/appydave-tools/docs/guides/query-tools.md`

---

## What Changed Today

### API Simplification
Both query tools had their APIs simplified — fewer flags, unified search:

**query_brain**: `--find` replaces separate `--brain` + `--tag`. `--active` replaces broken `--activity-min`. Removed: `--status` (dead code), `--tag`, `--activity-min`.

**query_omi**: Added `--days N` and `--limit N`. Removed: `--signal`, `--date-from`, `--date-to`, `--enriched-only` (enriched is now default).

### New --meta Mode
Both tools now support `--meta` — returns JSON metadata instead of file paths. This is a **separate pipeline** from llm_context, used when you want summaries without loading full file content.

### Bug Fixed
`query_brain --active` was silently returning nothing. Fixed — now correctly returns all 29 high-activity brains.

---

## Relevant Skills That May Want This Context

### OMI Skill (`/Users/davidcruwys/dev/ad/appydave-plugins/appydave/skills/omi/`)
The `query_omi` tool is the programmatic interface to the same OMI data that the OMI skill works with. The frontmatter fields (`routing`, `matched_brains`, `extraction_summary`, etc.) that `query_omi` filters on are produced by the OMI enrichment pipeline. The skill should know:
- `--routing brain-update` surfaces the backlog of conversations that should feed into brains
- `--meta` gives extraction summaries without loading full transcripts

### Brain Librarian (wherever it lives)
The `query_brain` tool consumes `brains-index.json` built by brain-librarian. The librarian should know:
- Index must be at `~/dev/ad/brains/audit/brains-index.json`
- Fields used: `activity_level`, `tags`, `category`, `status`, `file_count`, `index_path`, `files[]`
- `files[]` array is currently empty for most brains — only `INDEX.md` is returned. Populating this would make `query_brain --find X` return actual content files, not just index files.

### LLM Context Skill (if one exists)
The pipeline pattern is: `query_brain --find X | xargs llm_context.rb -i -f content`. The query tools are the **selector layer** feeding into llm_context as the **assembler layer**.

---

## What Is Not Done Yet (Intentionally Deferred)

- **Randomizer** — a discovery tool that pre-validates queries against result counts and randomly surfaces one. Concept is clear, not yet implemented. Would live as `/Users/davidcruwys/dev/ad/appydave-tools/bin/random_context.rb`.
- **Markdown format for --meta** — decided against. JSON is sufficient for LLM consumption and adding a format flag adds complexity back that was just removed.
