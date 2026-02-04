# CLI Pattern Comparison

Quick reference for choosing the right pattern when creating new CLI tools.

## Overview

AppyDave Tools uses **four CLI patterns**, each optimized for different scales:

- **Pattern 1**: 1 operation - Simple, linear
- **Pattern 2**: 2-5 commands - Inline routing
- **Pattern 3**: 6-9 commands - BaseAction (shared validation)
- **Pattern 4**: 10+ commands - Delegated CLI (testable)

## Visual Comparison

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PATTERN 1: SINGLE-COMMAND                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bin/tool.rb ──────────┐                                           │
│                        │                                            │
│  lib/tools/tool/ ◄─────┘                                           │
│    ├── options.rb    (Options struct)                              │
│    ├── logic.rb      (Core business logic)                         │
│    └── support.rb    (Supporting classes)                          │
│                                                                     │
│  Characteristics:                                                   │
│  • One operation, multiple options                                 │
│  • Linear execution flow                                           │
│  • Minimal routing logic                                           │
│                                                                     │
│  Examples: gpt_context, move_images                                │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              PATTERN 2: MULTI-COMMAND INLINE ROUTING                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bin/tool.rb ──────────┬──────────┐                                │
│    (CLI class)         │          │                                 │
│    • clean_cmd()       │          │                                 │
│    • join_cmd()        │          │                                 │
│                        │          │                                 │
│  lib/tools/tool/ ◄─────┴──────────┘                                │
│    ├── clean.rb      (Clean command)                               │
│    └── join.rb       (Join command)                                │
│                                                                     │
│  Characteristics:                                                   │
│  • 2-5 related commands                                            │
│  • Each command = method in CLI class                              │
│  • Dedicated OptionParser per command                              │
│                                                                     │
│  Examples: subtitle_processor, configuration                       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              PATTERN 3: MULTI-COMMAND BASEACTION                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bin/tool.rb ──────────┬──────────┬──────────┐                     │
│    (Routes commands)   │          │          │                      │
│                        │          │          │                      │
│  lib/cli_actions/ ◄────┴──────────┴──────────┘                     │
│    ├── base_action.rb    (Template method)                         │
│    ├── get_action.rb     (Inherits BaseAction)                     │
│    └── update_action.rb  (Inherits BaseAction)                     │
│                        │          │          │                      │
│  lib/tools/tool/ ◄─────┴──────────┴──────────┘                     │
│    ├── service_one.rb    (Shared business logic)                   │
│    └── service_two.rb                                              │
│                                                                     │
│  Characteristics:                                                   │
│  • 6+ commands OR shared validation patterns                       │
│  • Each command = Action class                                     │
│  • Template method enforces consistency                            │
│                                                                     │
│  Examples: youtube_manager                                         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                 PATTERN 4: DELEGATED CLI CLASS                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bin/tool.rb ──────────────┐                                       │
│    (30 lines)              │                                        │
│    cli = CLI.new           │                                        │
│    exit(cli.run(ARGV))     │                                        │
│                            │                                        │
│  lib/tools/tool/ ◄─────────┘                                       │
│    ├── cli.rb              (Full CLI class - 400+ lines)            │
│    │   ├── def run(args)   (Entry point with case/when)            │
│    │   ├── run_search      (Command dispatcher)                    │
│    │   ├── run_add         (Command dispatcher)                    │
│    │   └── run_remove      (Command dispatcher)                    │
│    │                                                                │
│    ├── search.rb           (Business logic)                        │
│    ├── crud.rb             (Business logic)                        │
│    └── config.rb           (Configuration)                         │
│                                                                     │
│  spec/tools/tool/                                                   │
│    ├── cli_spec.rb         (Test CLI behavior!)                    │
│    ├── search_spec.rb      (Business logic tests)                  │
│    └── crud_spec.rb        (Business logic tests)                  │
│                                                                     │
│  Characteristics:                                                   │
│  • 10+ commands - Scales excellently                              │
│  • CLI is testable (RSpec with mocks)                             │
│  • Dependency injection (config, output, validators)              │
│  • Exit codes (0-4 for different errors)                          │
│  • Professional-grade architecture                                │
│                                                                     │
│  Example: jump (10 commands, 29-line bin/, 400+ line lib/cli.rb)  │
└─────────────────────────────────────────────────────────────────────┘
```

## Decision Matrix

| Criteria | Pattern 1 | Pattern 2 | Pattern 3 | Pattern 4 |
|----------|-----------|-----------|-----------|-----------|
| **Number of commands** | 1 | 2-5 | 6-9 | 10+ |
| **Complexity** | Low | Medium | High | High |
| **Setup time** | Fast | Medium | Slower | Slower |
| **Scalability** | ❌ | ⚠️ | ✅ | ✅✅ |
| **Testable CLI** | N/A | ❌ | ❌ | ✅ |
| **Consistency enforcement** | N/A | ❌ | ✅ | ⚠️ |
| **Easy to understand** | ✅ | ✅ | ⚠️ | ⚠️ |
| **Shared validation** | N/A | ❌ | ✅ | ⚠️ |
| **Commands share logic** | N/A | ⚠️ | ✅ | ⚠️ |
| **Exit codes** | ⚠️ | ⚠️ | ⚠️ | ✅ |
| **Dependency injection** | ❌ | ❌ | ❌ | ✅ |
| **Professional-grade** | Simple only | Medium tools | ✅ | ✅✅ |

Legend:
- ✅ Excellent fit
- ⚠️ Works but not ideal
- ❌ Not applicable / Poor fit

## File Count Comparison

### Pattern 1 (gpt_context)
```
bin/gpt_context.rb                           1 file
lib/appydave/tools/gpt_context/
  ├── options.rb                             3 files
  ├── file_collector.rb
  └── output_handler.rb
────────────────────────────────────────────
Total: 4 files
```

### Pattern 2 (subtitle_processor)
```
bin/subtitle_processor.rb                    1 file
lib/appydave/tools/subtitle_processor/
  ├── clean.rb                               2 files
  └── join.rb
────────────────────────────────────────────
Total: 3 files (2 commands)
```

### Pattern 3 (youtube_manager)
```
bin/youtube_manager.rb                       1 file
lib/appydave/tools/cli_actions/
  ├── base_action.rb                         3 files (shared)
  ├── get_video_action.rb
  └── update_video_action.rb
lib/appydave/tools/youtube_manager/
  ├── get_video.rb                           2+ files
  └── update_video.rb
────────────────────────────────────────────
Total: 6+ files (2 commands)
```

### Pattern 4 (jump)
```
bin/jump.rb                                  1 file (30 lines!)
lib/appydave/tools/jump/
  ├── cli.rb                                 1 file (400+ lines)
  ├── config.rb                              1 file
  ├── search.rb                              1 file
  ├── crud.rb                                1 file
  ├── validators/
  │   └── path_validator.rb                  1 file
  ├── formatters/
  │   ├── table_formatter.rb                 3 files
  │   ├── json_formatter.rb
  │   └── paths_formatter.rb
  └── generators/
      └── aliases_generator.rb               1 file
────────────────────────────────────────────
Total: 10+ files (10 commands)
```

## Code Volume Comparison

### For a tool with 2 commands (get, update):

| Pattern | Lines of Code | Files | Boilerplate |
|---------|---------------|-------|-------------|
| Pattern 1 | N/A | N/A | Not applicable |
| Pattern 2 | ~150 LOC | 3 | Low |
| Pattern 3 | ~200 LOC | 6 | Medium |
| Pattern 4 | ~250 LOC | 4 | Medium |

**Recommendation:** Use Pattern 2 for 2-5 commands

### For a tool with 10 commands:

| Pattern | bin/ LOC | lib/ LOC | Total LOC | Files |
|---------|----------|----------|-----------|-------|
| Pattern 2 | 800-1600 | 500 | 1300-2100 | 11 |
| Pattern 3 | 80 | 2000+ | 2080+ | 21+ |
| Pattern 4 | 30 | 1500+ | 1530+ | 10+ |

**Recommendation:** Use Pattern 4 for 10+ commands (cleaner, testable)

## When to Refactor Between Patterns

### Pattern 1 → Pattern 2
**Trigger:** Need to add a second command

**Effort:** Medium - Requires restructuring bin/ file

### Pattern 2 → Pattern 3
**Trigger:**
- Command count reaches 6-9
- Commands share significant validation logic
- Need consistent error handling across commands
- Don't need CLI testing

**Effort:** Medium-High - Create BaseAction, convert methods to Action classes

### Pattern 2 → Pattern 4
**Trigger:**
- Command count reaches 10+
- bin/ file exceeds 500 lines
- Want to test CLI behavior
- Building professional-grade tool

**Effort:** Medium - Move CLI class to lib/, add dependency injection, create CLI tests

### Pattern 3 → Pattern 4
**Trigger:**
- Want to test CLI behavior (exit codes, output)
- Need dependency injection for testing
- Commands growing beyond 10+
- BaseAction pattern feels constraining

**Effort:** Medium - Convert Actions to methods in CLI class, add dependency injection

## Real-World Examples

### Pattern 1: gpt_context
**Purpose:** Gather files for AI context

**Commands:** 1 (implicit)

**Options:**
- `-i` include patterns
- `-e` exclude patterns
- `-f` format
- `-o` output target

**Why Pattern 1?** Single purpose tool with many options but ONE operation

---

### Pattern 2: subtitle_processor
**Purpose:** Process SRT subtitle files

**Commands:** 2
- `clean` - Remove tags, normalize
- `join` - Merge multiple files

**Why Pattern 2?** 
- Two distinct operations
- Each has different options
- Operations don't share validation logic

---

### Pattern 3: youtube_manager
**Purpose:** Manage YouTube videos via API

**Commands:** 2 (could expand to 6+)
- `get` - Fetch video details
- `update` - Update metadata

**Why Pattern 3?**
- Both require video ID validation
- Both use YouTube API authorization
- Future commands: `delete`, `upload`, `list`, `analyze`
- Shared pattern: authorize → validate → execute → report

---

### Pattern 4: jump
**Purpose:** Manage development folder locations

**Commands:** 10
- `search` - Fuzzy search locations
- `get` - Get by exact key
- `list` - List all locations
- `add` - Add new location
- `update` - Update existing location
- `remove` - Remove location
- `validate` - Validate paths exist
- `report` - Generate reports
- `generate` - Generate shell aliases
- `info` - Show configuration info

**Why Pattern 4?**
- 10 commands - Too many for Pattern 2/3
- Want to test CLI behavior (exit codes, output formatting)
- Professional development tool (needs dependency injection)
- Complex CLI logic (400+ lines in lib/cli.rb)
- Multiple output formatters (table, json, paths)
- Comprehensive help system

**Key benefits:**
- ✅ Full RSpec test coverage of CLI behavior
- ✅ Mock config, validators in tests
- ✅ Test exit codes (0 = success, 1-4 = different errors)
- ✅ Thin bin/ wrapper (29 lines)
- ✅ Professional-grade architecture

## Anti-Patterns to Avoid

### ❌ Don't: Mix patterns
```ruby
# bin/tool.rb
class ToolCLI
  def initialize
    @commands = {
      'clean' => method(:clean),           # Pattern 2 style
      'join' => JoinAction.new             # Pattern 3 style
    }
  end
end
```

**Why bad?** Inconsistent command handling makes maintenance difficult

**Fix:** Choose one pattern and stick with it

---

### ❌ Don't: Put business logic in bin/
```ruby
# bin/tool.rb (BAD)
def clean_subtitles(args)
  content = File.read(args[0])
  content.gsub!(/<u>/, '')  # Business logic in CLI
  File.write(args[1], content)
end
```

**Why bad?** Can't reuse logic programmatically, hard to test

**Fix:** Move logic to lib/
```ruby
# bin/tool.rb (GOOD)
def clean_subtitles(args)
  cleaner = Appydave::Tools::SubtitleProcessor::Clean.new(file_path: args[0])
  cleaner.clean
  cleaner.write(args[1])
end

# lib/appydave/tools/subtitle_processor/clean.rb
class Clean
  def clean
    @content.gsub(/<u>/, '')
  end
end
```

---

### ❌ Don't: Use BaseAction for 1-2 commands
```ruby
# Overkill for 2 commands
class GetAction < BaseAction; end
class UpdateAction < BaseAction; end
```

**Why bad?** Unnecessary complexity, harder to understand

**Fix:** Use Pattern 2 for 2-5 commands

---

## Migration Checklist

When migrating an existing tool or creating a new one:

- [ ] Choose pattern using decision tree
- [ ] Create directory structure
- [ ] Implement executable in `bin/`
- [ ] Implement business logic in `lib/`
- [ ] Add `# frozen_string_literal: true`
- [ ] No `require` statements in `lib/` (except Ruby stdlib)
- [ ] No CLI code in `lib/` classes (except Pattern 4: CLI in lib/cli.rb)
- [ ] Write RSpec tests for business logic (Pattern 4: also test CLI class)
- [ ] Register in `appydave-tools.gemspec`
- [ ] Document in `CLAUDE.md`
- [ ] Create `_doc.md` in module directory
- [ ] Test with `rake spec`
- [ ] Test CLI with `bin/tool.rb --help`

---

**Last updated:** 2025-02-04
