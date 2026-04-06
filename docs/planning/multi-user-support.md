---
title: Multi-User Support — AppyDave Tools
status: planning
created: 2026-04-05
context: Lars onboarding — first external user of appydave-tools
---

# Multi-User Support

## Current State

AppyDave Tools was built for a single user on David's M4 creator machine. It is not intentionally single-user — the architecture is already mostly correct — but it has never been tested with a second person's folder structure.

**What works for multi-user today:**
- Config is stored in `~/.config/appydave/` — per-user, not shared, no collision
- `gem install appydave-tools` gives Lars a clean install with no locations
- All tools read their paths from `~/.config/appydave/locations.json` at runtime

**What doesn't work yet:**
- Lars starts with an empty `locations.json` — no seed, no onboarding flow
- Lars's dev folder structure is unknown (capturing via `ls ~/dev/` in next relay session)
- David's `locations.json` has 100 entries, all pointing to `/Users/davidcruwys/` — not portable
- Brain query, OMI query, and LLM context tools likely assume specific location keys exist (e.g., `brain`, `omi`) — if Lars's keys are different or missing, these will fail silently or error

---

## Tools Lars Needs

### 1. Jump (immediate value)

The `jump` command generates shell aliases for folder navigation. Lars currently has only `jb` (jump to brain) — hardcoded, not managed by this tool.

**What Lars gets after setup:**
- Any folder registered in `locations.json` becomes a `j<alias>` shell alias
- Running `jump generate` writes a `.aliases` file; sourcing it activates them
- He can register his `~/dev/clients/`, relay folder, growth-intelligence repo, etc.

**Blocker:** He needs entries in `locations.json` before any aliases are generated.

### 2. Brain Query

Queries Lars's second brain folder structure. Likely reads from a location keyed `brain` in `locations.json`.

**Risk:** Key name may be hardcoded. Need to verify the tool reads `brain` key or is configurable.

### 3. OMI Query

Queries saved OMI transcripts. Likely reads from a location keyed `omi` or a path in `settings.json`.

**Risk:** Lars's OMI intake is at `~/dev/raw-intake/omi/` — this needs to be registered in his config.

### 4. LLM Context Builder

Builds context bundles for pasting into LLM sessions. Probably reads from multiple registered locations.

**Risk:** May depend on several location keys existing. Needs testing with minimal config.

---

## Installation Plan for Lars

```bash
gem install appydave-tools
```

Then verify:

```bash
appydave --version
appydave jump report
```

`jump report` with an empty `locations.json` should return zero locations without error — if it crashes, that's the first bug to fix.

### After Install — Bootstrap Lars's Locations

Lars needs a minimal seed `locations.json` tailored to his machine. Suggested starting set once we know his `~/dev/` structure:

| Key | Path (approximate) | Purpose |
|-----|--------------------|---------|
| `dev` | `~/dev` | Root dev folder |
| `brain` | `~/dev/brains/` | Second brain |
| `omi` | `~/dev/raw-intake/omi/` | OMI transcripts |
| `clients` | `~/dev/clients/` | Client work |
| `growth` | `~/dev/clients/lars-projects/growth-intelligence/` | Growth Intelligence repo |
| `relay` | `~/Dropbox/relay/people/david-lars/` | Relay folder |

Lars adds these via `appydave jump add` or by editing `~/.config/appydave/locations.json` directly.

---

## Known Gaps to Resolve

1. **Empty-config behaviour** — run all four tools with a blank `locations.json` and confirm they fail gracefully, not with a Ruby stack trace
2. **Location key conventions** — are keys like `brain` and `omi` hardcoded in brain-query and omi-query, or configurable? Document the expected keys.
3. **Aliases output path** — `aliases-output-path` in `settings.json` tells jump where to write the `.aliases` file. Lars needs this set before `jump generate` works. Default: `~/.config/appydave/aliases.sh` (check current default).
4. **Shell sourcing** — after `jump generate`, Lars needs `source ~/.config/appydave/aliases.sh` (or equivalent) in his `.zshrc`. This needs to be part of the setup guide.
5. **Ruby version** — gemspec requires `>= 2.7`. Lars's Ruby version is unknown — check during session.

---

## What This Is Not

This is not a multi-tenant SaaS problem. Each user has their own machine, their own `~/.config/appydave/`, and their own gem install. There is no shared state. The "multi-user support" work is really:

- Making sure the tools don't assume David's paths
- Providing a repeatable onboarding flow for a new machine
- Writing a short setup guide Lars can follow independently next time
