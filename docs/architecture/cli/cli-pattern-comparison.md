# CLI Pattern Comparison

Quick reference for choosing the right pattern when creating new CLI tools.

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
```

## Decision Matrix

| Criteria | Pattern 1 | Pattern 2 | Pattern 3 |
|----------|-----------|-----------|-----------|
| **Number of commands** | 1 | 2-5 | 6+ |
| **Complexity** | Low | Medium | High |
| **Setup time** | Fast | Medium | Slower |
| **Scalability** | ❌ | ⚠️ | ✅ |
| **Consistency enforcement** | N/A | ❌ | ✅ |
| **Easy to understand** | ✅ | ✅ | ⚠️ |
| **Shared validation** | N/A | ❌ | ✅ |
| **Commands share logic** | N/A | ⚠️ | ✅ |

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

## Code Volume Comparison

For a tool with **2 commands** (get, update):

| Pattern | Lines of Code | Files | Boilerplate |
|---------|---------------|-------|-------------|
| Pattern 1 | N/A | N/A | Not applicable |
| Pattern 2 | ~150 LOC | 3 | Low |
| Pattern 3 | ~200 LOC | 6 | Medium |

**Recommendation:** Use Pattern 2 for 2-5 commands, switch to Pattern 3 at 6+

## When to Refactor Between Patterns

### Pattern 1 → Pattern 2
**Trigger:** Need to add a second command

**Effort:** Medium - Requires restructuring bin/ file

### Pattern 2 → Pattern 3
**Trigger:** 
- Command count reaches 6+
- Commands share significant validation logic
- Need consistent error handling across commands

**Effort:** Medium-High - Create BaseAction, convert methods to Action classes

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
- [ ] No CLI code in `lib/` classes
- [ ] Write RSpec tests for business logic
- [ ] Register in `appydave-tools.gemspec`
- [ ] Document in `CLAUDE.md`
- [ ] Create `_doc.md` in module directory
- [ ] Test with `rake spec`
- [ ] Test CLI with `bin/tool.rb --help`

---

**Last updated:** 2025-11-08
