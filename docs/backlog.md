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
| 6 | BUG-1: Jump CLI get/remove commands fail to find entries (see below) | 2025-12-15 | Pending |

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

### BUG-1: Jump CLI get/remove Commands Fail to Find Entries

**Priority**: High - Core functionality broken

**Summary**: The `get` and `remove` commands fail to find locations by key, while `search` successfully finds the same entries.

**Steps to Reproduce**:
```bash
# Search finds the entry ✅
bin/jump.rb search awb-team
# Result: Shows awb-team with jump alias jwb-team

# Get fails to find the same entry ❌
bin/jump.rb get awb-team
# Result: "Location not found"

# Remove also fails ❌
bin/jump.rb remove test-minimal --force
# Result: "No locations found."
```

**Affected Commands**:
- `get <key>` - Returns "Location not found" or "No locations found"
- `remove <key>` - Returns "No locations found"

**Working Commands**:
- `search <terms>` - Works correctly, finds entries
- `list` - Works correctly, shows all entries
- `list --format json` - Works correctly

**Suspected Cause**:
The `get` and `remove` commands likely use a different key lookup mechanism than `search`. Possibilities:
1. **Exact match vs fuzzy match** - `get` might expect an exact internal key format that differs from what's displayed
2. **Case sensitivity** - Key matching might be case-sensitive
3. **Index/cache issue** - Commands might be reading from different data sources or a stale index
4. **Key field mismatch** - The lookup might be checking a different field than `key`

**Evidence**:
When `get agent-workflow-build` failed, it suggested: "Did you mean: test-minimal, test-full, dev?" - This suggests the lookup is working but matching against something unexpected (possibly only returning entries without certain fields, or using a different search algorithm).

**Config Location**: `~/.config/appydave/locations.json`

**Investigation Points**:
- Compare how `search` resolves entries vs `get`/`remove`
- Check `lib/appydave/tools/name_manager/` for lookup logic
- Look at `LocationRegistry#find` or similar method
- Verify the key field being matched against

**Acceptance Criteria**:
- [ ] `get <key>` finds entry when `search <key>` finds it
- [ ] `remove <key>` finds entry when `search <key>` finds it
- [ ] Add regression tests for key lookup consistency
- [ ] Document root cause in commit message

---

## Completed Requirements

### NFR-2: Claude Code Skill for Jump Tool

**Completed**: 2025-12-14

**Implementation Summary**:
- Personal skill at `~/.claude/skills/jump/SKILL.md`
- Description includes brand names (appydave, voz, supportsignal, joy, aitldr, kiros), products (flivideo, storyline, klueless, dam), and trigger keywords
- Primary mode: Jump CLI commands (`jump search`, `jump get`, `jump list`)
- Fallback mode: Direct JSON read from `/ad/brains/brand-dave/data-systems/collections/jump/current.json`
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
