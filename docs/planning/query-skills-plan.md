# Query Ecosystem — Skill Wrappers Plan

**Purpose**: Plan for creating thin skill wrappers around the four CLI tools in the query/gather ecosystem. Skills are shims — they call the Ruby CLI tools, not reimplementations.

**Status**: Planning
**Created**: 2026-04-05
**Depends on**: `query_apps` CLI tool (Phase 2 — complete, 76 tests passing)

---

## The Ecosystem

```
QUERY TOOLS (find files)              GATHER TOOL (assemble content)
─────────────────────────             ────────────────────────────
query_brain  → brain files      ─┐
query_omi    → OMI transcripts   ├──→  llm_context  →  LLM payload
query_apps   → app files        ─┘
```

Each query tool outputs file paths (one per line). `llm_context` consumes those paths via `--stdin` and assembles content. The skills wrap each CLI tool to make them discoverable by Claude Code.

---

## Current State

| CLI Tool | Skill Exists? | Location | Notes |
|----------|--------------|----------|-------|
| `query_omi` | **Yes** — `omi-query` | `appydave-plugins/appydave/skills/omi-query/` | Gold standard pattern |
| `query_brain` | **No** | — | `focus` skill has `resolve_brain.py` doing subset of same work |
| `query_apps` | **No** | — | CLI tool just completed |
| `llm_context` | **No** | — | Downstream assembler, different trigger pattern |

---

## Skill 1: `brain-query`

**Plugin**: `appydave-plugins/appydave/skills/brain-query/SKILL.md`

**Triggers**: "search brains for X", "find brain about X", "which brains cover X", "brain files for X", "what's in the X brain", "active brains", "brains tagged X", "brains in category X"

**Relationship to `focus`**: `focus` is an orientation skill — it reads and summarises a brain's INDEX.md. `brain-query` is a file discovery skill — it returns file paths for piping into `llm_context`. Different intents, complementary tools.

**Relationship to `resolve_brain.py`**: The Python script in the `focus` skill does brain name resolution (exact → fuzzy → ambiguous). `query_brain` in Ruby does the same thing plus tag lookup, category search, alias resolution, and file path output. Long term, `focus` should call `query_brain --find --meta` instead of `resolve_brain.py`. But that's a separate refactor — don't block this skill on it.

### CLI Interface (what the skill wraps)

```bash
# Find by name/alias/tag (4-tier resolution: exact → alias → substring → tag)
query_brain --find anthropic-claude
query_brain --find claude              # substring match
query_brain --find agent-systems       # tag match

# Find by category
query_brain --category claude-core
query_brain --category agent-frameworks

# Active (high-activity) brains
query_brain --active

# Metadata mode — JSON with name, category, activity_level, status, tags, file_count
query_brain --find claude --meta
query_brain --active --meta

# Exclude INDEX.md from results
query_brain --find paperclip --files-only

# Combine with llm_context
query_brain --find paperclip | llm_context --stdin -f content --smart
query_brain --find paperclip --files-only | llm_context --stdin -f tree
```

### Skill Structure

```
brain-query/
  SKILL.md         # Thin wrapper — triggers, CLI commands, common workflows
```

No scripts, no Python, no reference files. Just the SKILL.md documenting how to call `query_brain`.

### Skill Content Outline

1. **Description/triggers** in YAML frontmatter
2. **CLI Tool** section — show all flags with examples
3. **Two Output Modes** — file paths (default) vs `--meta` (JSON)
4. **Common Workflows**:
   - "What brains cover topic X?" → `query_brain --find X --meta`
   - "Load all files from brain X" → `query_brain --find X | llm_context --stdin -f content --smart`
   - "Which brains are active?" → `query_brain --active --meta`
   - "All brains in a category" → `query_brain --category claude-core --meta`
   - "Get brain docs without INDEX.md" → `query_brain --find X --files-only`
5. **Prerequisites** — `query_brain` installed (part of `appydave-tools`), `brains-index.json` must exist (built by brain-librarian's `build_brain_index.py`)
6. **Related Skills** — `focus` (orientation), `brain-librarian` (curation), `brain-bridge` (write to brain)

### Key Design Notes

- The skill should NOT reimplement resolution logic — just document the CLI flags
- `query_brain` already reads `brains-index.json` which is built by `build_brain_index.py` in the brain-librarian skill. The skill should mention this prerequisite
- The `--find` flag does 4-tier resolution internally (exact key → alias → substring → tag) — the skill doesn't need to know the tiers, just that `--find` handles fuzzy matching

---

## Skill 2: `app-query`

**Plugin**: `appydave-plugins/appydave/skills/app-query/SKILL.md`

**Triggers**: "get files from X app", "show me X's backend", "load X docs", "what apps have context", "list globs for X", "app files for X", "codebase of X", "understand X app", "X services", "X components", "X frontend", "X api"

### CLI Interface (what the skill wraps)

```bash
# Basic: app name + glob category
query_apps flihub --glob docs
query_apps angeleye --glob services

# Aliases resolve to multiple categories
query_apps flihub --glob backend         # → services + routes
query_apps flihub --glob frontend        # → components + views + styles

# Composites — pre-built bundles
query_apps flihub --glob understand      # → context + docs + types + config
query_apps flihub --glob codebase        # → services + routes + components + views

# Multiple globs (comma-separated)
query_apps flihub --glob docs,types,config

# Cross-app by pattern type
query_apps --pattern rvets --glob backend
query_apps --pattern nextjs --glob schema

# Discovery
query_apps flihub --list                 # available glob names for this app
query_apps --list-apps                   # all apps with context.globs.json

# Metadata mode
query_apps flihub --glob backend --meta

# Pipe to llm_context
query_apps flihub --glob understand | llm_context --stdin -f content --smart
query_apps angeleye --glob services | llm_context --stdin -f tree
```

### Skill Content Outline

1. **Description/triggers** in YAML frontmatter
2. **CLI Tool** section — all flags with examples
3. **Glob Resolution** — direct name → alias → composite → substring fallback
4. **Standard Vocabulary** — table of common category names and what they typically contain
5. **Common Workflows**:
   - "Help me understand app X" → `query_apps X --glob understand | llm_context --stdin -f content --smart`
   - "What's the API look like?" → `query_apps X --glob api`
   - "Show me all React code" → `query_apps X --glob react`
   - "What globs are available?" → `query_apps X --list`
   - "Which apps are queryable?" → `query_apps --list-apps`
   - "All RVETS backend code" → `query_apps --pattern rvets --glob backend`
6. **Prerequisites** — `query_apps` installed (appydave-tools), `context.globs.json` must exist in project root (generated by `system-context` skill)
7. **Related Skills** — `system-context` (generates context.globs.json), `llm-context` (downstream assembler)

### Key Design Notes

- The skill should explain the alias/composite concept so the agent knows "backend" is valid even though the globs file has "services" and "routes"
- Include the standard vocabulary table so agents can try common names without running `--list` first
- `context.globs.json` is generated by `system-context` — if it doesn't exist for an app, the skill should suggest running `/system-context` there first

---

## Skill 3: `llm-context`

**Plugin**: `appydave-plugins/appydave/skills/llm-context/SKILL.md`

**Triggers**: "gather files for context", "build llm context", "assemble context from files", "package files for llm", "get context from these files", "collect codebase", "gather code"

**Important distinction**: This is NOT a query tool. It's the downstream assembler. It takes file paths (from stdin or glob patterns) and produces formatted content for LLM consumption. The trigger pattern is different — it activates when the user wants to package/assemble, not when they want to search/find.

### CLI Interface (what the skill wraps)

```bash
# Direct glob patterns
llm_context -i 'lib/**/*.rb' -f content
llm_context -i 'src/**/*.ts' -e 'node_modules/**/*' -f tree,content

# Stdin mode — receive file paths from query tools
query_brain --find paperclip | llm_context --stdin -f content --smart
query_apps flihub --glob backend | llm_context --stdin -f content --smart
query_omi --brain til --days 7 | llm_context --stdin -f content --smart

# Output formats
llm_context -i 'lib/**/*.rb' -f tree           # directory tree only
llm_context -i 'lib/**/*.rb' -f content        # file contents with headers
llm_context -i 'lib/**/*.rb' -f json           # structured JSON
llm_context -i 'lib/**/*.rb' -f files          # file paths only
llm_context -i 'lib/**/*.rb' -f tree,content   # multiple formats
llm_context -i 'lib/**/*.rb' -f aider -p 'Add logging'  # aider command

# Output targets
llm_context -i 'lib/**/*.rb' -o clipboard      # copy to clipboard (default)
llm_context -i 'lib/**/*.rb' -o temp            # write to temp file, path on clipboard
llm_context -i 'lib/**/*.rb' -o context.txt     # write to specific file
llm_context -i 'lib/**/*.rb' -o stdout          # print to stdout
llm_context -i 'lib/**/*.rb' --smart            # auto-route: clipboard if ≤100k tokens, else temp

# Other options
llm_context -i 'lib/**/*.rb' -l 50              # limit to first 50 lines per file
llm_context -i 'lib/**/*.rb' -t                 # show token estimate
llm_context -i 'lib/**/*.rb' -b /some/other/dir # set base directory
```

### Skill Content Outline

1. **Description/triggers** in YAML frontmatter
2. **Position in the chain** — this is the ASSEMBLER, not a query tool. Diagram showing query tools → llm_context → LLM
3. **Two Input Modes**:
   - **Pattern mode**: `-i` and `-e` glob patterns, run from any directory
   - **Stdin mode**: `--stdin` receives file paths piped from query tools
4. **Output Formats** — table explaining tree, content, json, files, aider
5. **Output Targets** — clipboard, temp, file, stdout, `--smart` auto-routing
6. **Common Workflows**:
   - "Package this project's Ruby code" → `llm_context -i 'lib/**/*.rb' --smart`
   - "Get a tree view of the project" → `llm_context -i '**/*' -e 'node_modules/**/*' -f tree`
   - "Load brain files into context" → `query_brain --find X | llm_context --stdin -f content --smart`
   - "Load app backend for review" → `query_apps X --glob backend | llm_context --stdin -f content --smart`
   - "How big is this context?" → `llm_context -i 'src/**/*.ts' -t` (shows token estimate)
   - "Save context to a file" → `llm_context -i 'lib/**/*.rb' -f tree,content -o context.txt`
7. **The `--smart` flag** — auto-routes based on token count: clipboard if ≤100k tokens, temp file (path copied to clipboard) if larger. Mutually exclusive with explicit `-o clipboard` or `-o temp`
8. **Prerequisites** — `llm_context` installed (part of `appydave-tools`)
9. **Related Skills** — `brain-query`, `app-query`, `omi-query` (upstream query tools)

### Key Design Notes

- The skill description must NOT overlap with query tool triggers. "Get files from FliHub" → `app-query`. "Package these files for an LLM" → `llm-context`
- The `--smart` flag is the recommended default for most workflows — mention it prominently
- The skill should show the full pipeline pattern: `query_X ... | llm_context --stdin -f content --smart`
- Token estimation (`-t`) is useful for checking context window fit before sending to an LLM

---

## Skill 4: `system-context` Update (not a new skill)

The existing `system-context` skill in `appydave-plugins/appydave/skills/system-context/SKILL.md` needs an addition to generate `context.globs.json` alongside `CONTEXT.md`.

**This is NOT a new skill** — it's a modification to the existing skill.

### What to Add

After writing `CONTEXT.md`, the skill should also:

1. **Detect project pattern** from project files:
   - `package.json` with `workspaces` containing `shared/`, `server/`, `client/` → `rvets`
   - `package.json` with `next` dependency → `nextjs`
   - `Gemfile` or `*.gemspec` → `ruby-gem`
   - `pyproject.toml` or `requirements.txt` → `python`
   - Fallback: `unknown`

2. **Scan directory structure** and map to standard vocabulary:

   | Category | RVETS | Next.js | Ruby Gem | Python |
   |----------|-------|---------|----------|--------|
   | `docs` | `docs/**/*.md` | `docs/**/*.md` | `docs/**/*.md` | `docs/**/*.md` |
   | `types` | `shared/**/*.ts` | `types/**/*.ts`, `lib/db/schema/**/*.ts` | — | — |
   | `config` | `server/config.json`, `*.config.*` | `*.config.*`, `middleware.ts` | `config/**/*.json` | `*.yaml`, `*.toml` |
   | `services` | `server/src/services/**/*.ts` | — | — | — |
   | `routes` | `server/src/routes/**/*.ts` | `app/api/**/*.ts` | — | — |
   | `components` | `client/src/components/**/*.tsx` | `components/**/*.tsx` | — | — |
   | `views` | `client/src/views/**/*.tsx` | `app/**/*.tsx` (pages) | — | — |
   | `tests` | `**/*.test.ts`, `**/*.spec.ts` | `**/*.test.*` | `spec/**/*_spec.rb` | `tests/**/*.py` |
   | `styles` | `**/*.css` | `**/*.css` | — | — |
   | `context` | `CLAUDE.md`, `CONTEXT.md`, `STEERING.md` | same | same | same |
   | `lib` | — | — | `lib/**/*.rb` | `src/**/*.py` |
   | `bin` | — | — | `bin/*` | — |
   | `actions` | — | `lib/actions/**/*.ts` | — | — |
   | `validation` | — | `lib/validation/**/*.ts` | — | — |
   | `auth` | — | `lib/auth/**/*.ts` | — | — |
   | `mockups` | `.mochaccino/designs/**/*.html` | — | — | — |
   | `planning` | `docs/prd/**/*.md`, `docs/planning/**/*.md` | same | same | same |

3. **Only include categories that actually match files** — don't generate a `mockups` entry if `.mochaccino/` doesn't exist

4. **Generate standard aliases and composites**:

   ```json
   "aliases": {
     "backend": ["services", "routes"],
     "frontend": ["components", "views", "styles"],
     "api": ["routes", "types"],
     "data-layer": ["types", "schema"],
     "react": ["components", "views"],
     "ui": ["components", "views", "styles"]
   },
   "composites": {
     "understand": ["context", "docs", "types", "config"],
     "codebase": ["services", "routes", "components", "views"],
     "full": ["*"]
   }
   ```

   Only include alias/composite entries where the referenced categories exist in `globs`.

5. **Write `context.globs.json`** to project root alongside `CONTEXT.md`

6. **Add to CONTEXT.md sources** — include `context.globs.json` in the frontmatter sources list

### Validation

After generating, the skill should verify:
- Every glob in `globs` matches at least one file on disk
- Every alias references only categories that exist in `globs`
- Every composite references only categories that exist in `globs`
- `pattern` field is set

---

## Implementation Order

| Phase | What | Where | Depends On |
|-------|------|-------|------------|
| 1 | `brain-query` skill | `appydave-plugins/appydave/skills/brain-query/` | `query_brain` CLI (exists) |
| 2 | `app-query` skill | `appydave-plugins/appydave/skills/app-query/` | `query_apps` CLI (exists) |
| 3 | `llm-context` skill | `appydave-plugins/appydave/skills/llm-context/` | `llm_context` CLI (exists) |
| 4 | `system-context` update | `appydave-plugins/appydave/skills/system-context/SKILL.md` | `app-query` skill (to validate output) |
| 5 | Generate `context.globs.json` for 12 existing apps | Run `/system-context` in each project | Phase 4 |

Phases 1-3 are independent — can be done in any order or in parallel. Phase 4 depends on the `context.globs.json` format being finalized (which it is — see `query-apps-design.md`). Phase 5 is a batch operation.

---

## Decisions Made

| Decision | Choice | Why |
|----------|--------|-----|
| Skills are thin shims | Yes | Ruby tools have robust test suites; reimplementing in Python/Bash loses coverage |
| No scripts in skill folders | Correct | Skills just document CLI flags — no `scripts/` subdirectory needed |
| `focus` stays separate from `brain-query` | Yes | Different intent: orientation vs file discovery |
| `resolve_brain.py` stays for now | Yes | Refactor to use `query_brain` later; don't block skills on it |
| `llm-context` has different triggers than query skills | Yes | It's a downstream assembler, not a query tool |
| All skills go in `appydave` plugin | Yes | These are appydave-tools wrappers, not project-specific |

---

## Related Files

| What | Where |
|------|-------|
| `query-apps-design.md` (Phase 2 design) | `docs/planning/query-apps-design.md` |
| `omi-query` skill (pattern to follow) | `appydave-plugins/appydave/skills/omi-query/SKILL.md` |
| `query_brain` CLI | `bin/query_brain.rb` |
| `query_apps` CLI | `bin/query_apps.rb` |
| `llm_context` CLI | `bin/llm_context.rb` |
| BrainQuery implementation | `lib/appydave/tools/brain_context/brain_finder.rb` |
| AppQuery implementation | `lib/appydave/tools/app_context/app_finder.rb` |
| FileCollector implementation | `lib/appydave/tools/llm_context/file_collector.rb` |
| Locations registry | `~/.config/appydave/locations.json` |
| Brain index | `~/dev/ad/brains/brains-index.json` |
| System-context skill | `appydave-plugins/appydave/skills/system-context/SKILL.md` |
