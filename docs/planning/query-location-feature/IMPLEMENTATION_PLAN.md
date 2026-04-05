# FR-NEW: Query Location & App Registry Integration

**Status**: Proposed
**Priority**: Medium
**Created**: 2026-04-05
**Relates to**: `query_brain`, `llm_context` pipeline; `locations.json`, `apps.json`

---

## Problem

`query_brain` and `llm_context` work well for brain files but have no way to resolve project paths from the existing registries. When a user says "package the FliVideo project for LLM research", there is no single command that:
1. Looks up the project path from `locations.json` or `apps.json`
2. Knows which file groupings are relevant (docs, code, prompts, tests)
3. Feeds those paths directly into `llm_context`

Instead, the user must manually look up the path and write the `llm_context` invocation by hand every time.

---

## Proposed Solution

### Option A — `query_location` CLI (preferred)

New binary `bin/query_location.rb` that queries `~/.config/appydave/locations.json` and `~/.config/appydave/apps.json` by key, name, type, or brand.

```bash
# Find a project by key or name
query_location --find flivideo
query_location --find ss-prompt

# List all products
query_location --type product

# Get path only (for piping)
query_location --find flivideo --path-only

# Get JSON metadata
query_location --find flivideo --meta

# List all apps from apps.json
query_location --apps
query_location --apps --status active
```

Output modes:
- Default: path on a single line (pipeable to `llm_context`)
- `--meta`: JSON with key, path, description, type, status
- `--path-only`: bare path string

### Option B — Extend `jump.rb` with a query subcommand

Add `jump.rb query --find flivideo` rather than a new binary. Lower overhead, shares existing location-loading code.

**Recommendation**: Option B — reuse `jump.rb` infrastructure, add a `query` subcommand that outputs path/meta. Less surface area, same capability.

---

## File Groupings (Phase 2)

Once location lookup works, the second gap is "which files within a project are relevant for LLM research?" Today the user must specify patterns manually.

**Proposed**: A `.llm-groups.yaml` sidecar file at the project root declaring named groupings:

```yaml
# .llm-groups.yaml
groups:
  docs:
    - "docs/**/*.md"
    - "README.md"
    - "CLAUDE.md"
  code:
    - "lib/**/*.rb"
    - "bin/**/*.rb"
  tests:
    - "spec/**/*.rb"
  prompts:
    - "poem/**/*.json"
    - "poem/**/*.yaml"
```

Then:
```bash
# Package docs group for LLM
query_location --find appydave-tools --path-only | xargs -I{} llm_context -b {} --groups docs

# Or inline
llm_context -b ~/dev/ad/appydave-tools --groups docs,code
```

`llm_context` would read `.llm-groups.yaml` if present and expand the named groupings into `-i` patterns.

---

## Pipeline Vision (Full)

```bash
# Today (manual, fragile)
llm_context -b ~/dev/ad/flivideo -i 'lib/**/*.rb' -i 'docs/**/*.md' -f content -o clipboard

# After this feature (location-aware)
query_location --find flivideo --path-only | xargs -I{} llm_context -b {} --groups docs,code -f content -o clipboard

# Or shorthand once groups file exists
llm_context --project flivideo --groups docs -o clipboard
```

---

## Acceptance Criteria

- [ ] `jump.rb query --find <term>` returns matching location path(s)
- [ ] `jump.rb query --find <term> --meta` returns JSON with key, path, description, type
- [ ] `jump.rb query --type product` lists all product locations
- [ ] Output is pipeable to `llm_context -b`
- [ ] Apps from `apps.json` are also queryable (or a separate `--apps` flag)
- [ ] Spec coverage for new query subcommand

### Phase 2 (separate backlog item)
- [ ] `llm_context` reads `.llm-groups.yaml` and expands `--groups` flag into `-i` patterns
- [ ] `.llm-groups.yaml` standard defined and documented
- [ ] At least 3 projects have `.llm-groups.yaml` files (appydave-tools, flivideo, ss-prompt)

---

## Related Systems

- `~/.config/appydave/locations.json` — 70+ project locations (source of truth for `jump`)
- `~/.config/appydave/apps.json` — app registry with ports, start scripts, status
- `query_brain` — parallel tool for brain files; this is the project equivalent
- `llm_context` — the consumer; needs paths to operate
- `system-comprehension-pattern.md` — the pattern that produces the mental model; needs groupings to be useful at scale
- `appydave:system-context` skill — MISSING skill that generates `CONTEXT.md` per project; relates to Phase 2 groupings

---

## Notes

- Do NOT create a separate JSON registry — `locations.json` is already the source of truth
- The `jump` skill already knows about `locations.json`; extending `jump.rb` keeps things consistent
- Phase 2 (`.llm-groups.yaml`) is the real value unlock — Phase 1 is just plumbing
- This feature is what enables the "package project X for LLM research" workflow without manual path lookup every time
