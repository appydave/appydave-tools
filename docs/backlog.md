# AppyDave Tools - Backlog

Requirements tracking for AppyDave Tools development.

---

## Requirements Table

| # | Requirement | Added | Status |
|---|-------------|-------|--------|
| 1 | FR-1: GPT Context token counting (see below) | 2025-12-06 | Pending |
| 2 | FR-2: GPT Context AI-friendly help system (see below) | 2025-12-07 | Pending |
| 3 | NFR-1: Improve test coverage for DAM commands | 2025-12-06 | Pending |
| 4 | FR-3: Jump Location Tool (see spec) | 2025-12-13 | ✅ Implemented 2025-12-13 |
| 5 | NFR-2: Claude Code Skill for Jump Tool (see below) | 2025-12-14 | ✅ Implemented 2025-12-14 |

---

## Pending Requirements

### FR-1: GPT Context Token Counting

**User Story**: As a developer using GPT Context, I want to see estimated token counts so I can ensure my context fits within LLM limits.

**Acceptance Criteria**:
- [ ] Display estimated token count in output
- [ ] Support common tokenizers (cl100k for GPT-4, claude for Claude)
- [ ] Show warning when exceeding common thresholds (100k, 200k)
- [ ] Optional via `--tokens` flag

**Technical Notes**:
- Consider tiktoken gem for OpenAI tokenization
- May need to estimate for Claude (no official Ruby tokenizer)

---

### FR-2: GPT Context AI-Friendly Help System

**Spec**: [docs/specs/fr-002-gpt-context-help-system.md](./specs/fr-002-gpt-context-help-system.md)

**User Story**: As an AI agent using GPT Context via skills, I want structured, comprehensive help output so I can understand all options and use the tool correctly.

**Priority**: High - enables AI skill integration

**Status**: Ready for Development - full spec available

---

### NFR-1: Improve Test Coverage for DAM Commands

**Goal**: Increase test coverage for DAM command implementations.

**Scope**:
- [ ] Add specs for `ListCommand`
- [ ] Add specs for `S3UpCommand` with mocked S3
- [ ] Add specs for `S3DownCommand` with mocked S3
- [ ] Add specs for `S3StatusCommand`

**Notes**:
- Use VCR or WebMock for S3 API calls
- Focus on edge cases: missing config, network errors, permission issues

---

## Completed Requirements

### NFR-2: Claude Code Skill for Jump Tool

**Completed**: 2025-12-14

**Implementation Summary**:
- Personal skill at `~/.claude/skills/jump/SKILL.md`
- Description includes brand names (appydave, voz, supportsignal, joy, aitldr, kiros), products (flivideo, storyline, klueless, dam), and trigger keywords
- Primary mode: Jump CLI commands (`jump search`, `jump get`, `jump list`)
- Fallback mode: Direct JSON read from `/ad/brains/brand-david/data-systems/collections/jump/current.json`
- Tool restrictions: `allowed-tools: Read, Bash, Grep, Glob`
- Includes natural language examples and key location reference table

**Testing**: Restart Claude Code and test with prompts like "Where is FliVideo?"

### FR-3: Jump Location Tool

**Spec**: [docs/specs/fr-003-jump-location-tool.md](./specs/fr-003-jump-location-tool.md)

**Completed**: 2025-12-13

**Implementation Summary**:
- CLI tool (`jump`) for managing development folder locations
- Single JSON config file (`~/.config/appydave/locations.json`)
- Fuzzy search with weighted scoring across all metadata
- CRUD operations (add/update/remove) with validation
- Reports by brand, client, type, tag
- Generation of shell aliases and help content
- 68 RSpec tests passing
- Follows Pattern 4 (Method Dispatch Full) from CLI patterns guide
- Dependency injection for PathValidator enables CI-compatible testing

---

## How to Use This File

### Adding a New Requirement

1. Add row to the Requirements Table
2. Add a section below with:
   - User story (for FRs)
   - Acceptance criteria
   - Technical notes

### Updating Status

- `Pending` - Not yet started
- `🔄 In Progress` - Being worked on
- `✅ Implemented YYYY-MM-DD` - Complete
- `⚠️ Needs Rework` - Issues found

### Requirement Types

- **FR-X** - Functional Requirements (user-facing features)
- **NFR-X** - Non-Functional Requirements (refactors, performance, tests)
