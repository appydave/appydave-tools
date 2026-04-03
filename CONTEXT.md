---
generated: 2026-04-03
generator: system-context
status: snapshot
sources:
  - README.md
  - appydave-tools.gemspec
  - lib/appydave/tools.rb
  - lib/appydave/tools/dam/brand_resolver.rb
  - lib/appydave/tools/dam/project_resolver.rb
  - lib/appydave/tools/jump/commands/generate.rb
  - docs/dam/batch-s3-listing-requirements.md
  - CHANGELOG.md (versions 0.76.0-0.77.7)
regenerate: "Run /appydave:system-context in the repo root"
---

# AppyDave Tools — System Context

## Purpose
Eliminate repetitive manual tasks from YouTube content creation workflows by bundling single-purpose CLI utilities that operate independently on video projects, metadata, and assets.

## Domain Concepts
- **Brand** — A business entity that owns video projects (AppyDave, VOZ, SupportSignal, etc.). Shortcuts (ad, joy, ss) resolve to brand keys (appydave, beauty-and-joy, supportsignal) in configs.
- **Project** — A discrete video deliverable. Named by pattern: FliVideo uses short codes (b65 → expands to b65-guy-monroe-marketing-plan), Storyline uses full names (boy-baker). Projects contain assets, metadata, and source files.
- **Digital Asset Management (DAM)** — Hybrid 3-tier storage: local working copies → S3 staging for collaboration (90-day lifecycle) → SSD archive for long-term cold storage. Orchestrates file sync and lifecycle across tiers.
- **Project Naming Patterns** — FliVideo: `b<num>` (short) expands to `b<num>-*` full name. Patterns like `b6*` match b60-b69. Storyline uses exact full names (no expansion).
- **Configuration-driven Architecture** — JSON configs (settings, channels, brands) stored in `~/.config/appydave/` per developer; secrets (.env) gitignored. Enables team collaboration: shared structure, per-dev customization.
- **Multi-channel YouTube Management** — Handles multiple YouTube channels (each with code, name, handle, locations). Single tool manages metadata updates across channels.

## Design Decisions
- **Single consolidated repository** — instead of separate gems per tool. Reduces maintenance overhead, enables code reuse, allows individual tools to be featured in standalone tutorials.
- **Single-purpose tools that operate independently** — each CLI does one thing (llm_context, youtube_manager, dam, etc.). Prevents feature creep, keeps coupling low, enables composition.
- **Configuration as data** — JSON files enable team sharing of project structure + team-specific path customization in .env. Separates secrets (API keys) from configuration (paths, channels).
- **Hybrid storage lifecycle** — S3 for short-term collaboration, SSD for archive. Balances cost (S3 pay-per-access), availability (local for daily work), and durability (SSD backup).
- **Brand/Project resolution layer** — BrandResolver + ProjectResolver decouple CLI input (shortcuts like ad, b65) from system state (config keys, full paths). Users type short codes; system maps to canonical names.
- **Parallel status checking** — `dam list <brand> --s3` parallelizes git and S3 status checks instead of N sequential API calls. Reduces list latency from 3-5s to <1s.

## Scope Limits
- Does NOT edit video files directly — only manages metadata, assets, and file organization. Video editing remains in post-production tools (Premiere, DaVinci, etc.).
- Does NOT provide local playback or streaming — focuses on storage, sync, and metadata. Video playback via external players or YouTube.
- Does NOT implement YouTube OAuth UI — wraps Google's authentication library. OAuth token generation handled by google-api-client flows, not custom UI.
- Does NOT manage individual files in DAM — operates on whole project directories as atomic units. Granular file operations are external (rsync, direct S3 CLI).
- Does NOT provide IDE integration for Jump tool — generates shell aliases and help text. IDE navigation handled by native IDE shortcuts or external plugins.
- Does NOT handle video versioning or branching — DAM is a flat archive. Version control (git) handles project versioning separately from media storage.
