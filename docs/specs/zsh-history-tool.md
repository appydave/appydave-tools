# ZSH History Tool - Implementation Specification

## Overview

A Ruby CLI tool to parse, filter, and clean ZSH history files. Part of the appydave-tools gem.

**Primary Goals:**
1. View clean, filtered ZSH history (remove noise)
2. Optionally rewrite ~/.zsh_history with filtered content
3. Filter by time range (last N days)
4. Categorize commands as wanted/unwanted/unsure using configurable patterns

**CLI Pattern:** Pattern 1 (Simple Procedural) - single-purpose tool with OptionParser

---

## Table of Contents

1. [Requirements](#requirements)
2. [Architecture](#architecture)
3. [Data Structures](#data-structures)
4. [ZSH History Format](#zsh-history-format)
5. [Parsing Algorithm](#parsing-algorithm)
6. [Filter System](#filter-system)
7. [CLI Interface](#cli-interface)
8. [Configuration](#configuration)
9. [File Structure](#file-structure)
10. [Implementation Phases](#implementation-phases)
11. [Testing Strategy](#testing-strategy)
12. [Future Enhancements](#future-enhancements)

---

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Parse ~/.zsh_history including multi-line commands | Must |
| FR-2 | Extract timestamps and convert to datetime | Must |
| FR-3 | Apply exclude patterns to filter out noise | Must |
| FR-4 | Apply include patterns to keep valuable commands | Must |
| FR-5 | Filter by date range (--days N) | Must |
| FR-6 | Display clean history to stdout | Must |
| FR-7 | Rewrite ~/.zsh_history with filtered content (--write) | Should |
| FR-8 | Show statistics (counts per category) | Should |
| FR-9 | Search within history (--grep) | Could |
| FR-10 | Interactive review of unsure commands | Could |

### Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | Process 50,000+ history entries in < 5 seconds |
| NFR-2 | Create backup before rewriting history file |
| NFR-3 | Handle corrupted/malformed history entries gracefully |
| NFR-4 | UTF-8 support for international characters |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI Layer                                │
│                    bin/zsh_history.rb                           │
│         (OptionParser, argument handling, output)               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Service Layer                              │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Parser    │  │   Filter    │  │  Formatter  │             │
│  │             │  │             │  │             │             │
│  │ - read()    │  │ - apply()   │  │ - clean()   │             │
│  │ - parse()   │  │ - match()   │  │ - stats()   │             │
│  │ - join()    │  │ - categorize│  │ - write()   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Config Layer                                │
│           ~/.config/appydave/zsh_history.json                   │
│                                                                  │
│  { "exclude_patterns": [...], "include_patterns": [...] }       │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **CLI** | Parse arguments, orchestrate workflow, handle I/O |
| **Parser** | Read ZSH history file, reconstruct multi-line commands |
| **Filter** | Apply patterns, categorize commands, filter by date |
| **Formatter** | Format output for display, generate stats, write files |
| **Config** | Load/save filter patterns from JSON config |

---

## Data Structures

### Command Struct

```ruby
Command = Struct.new(
  :timestamp,      # Integer - Unix timestamp from history
  :datetime,       # Time - Parsed datetime
  :text,           # String - Full command text (multi-line joined)
  :is_multiline,   # Boolean - Was this a continuation command?
  :category,       # Symbol - :wanted, :unwanted, :unsure
  :raw_lines,      # Array<String> - Original lines from file
  keyword_init: true
)
```

### FilterResult Struct

```ruby
FilterResult = Struct.new(
  :wanted,         # Array<Command>
  :unwanted,       # Array<Command>
  :unsure,         # Array<Command>
  :stats,          # Hash - { total:, wanted:, unwanted:, unsure: }
  keyword_init: true
)
```

### Config Structure

```ruby
Config = Struct.new(
  :exclude_patterns,  # Array<String> - Regex patterns to exclude
  :include_patterns,  # Array<String> - Regex patterns to include
  :history_path,      # String - Path to history file (default: ~/.zsh_history)
  keyword_init: true
)
```

---

## ZSH History Format

### Standard Format

```
: 1699876543:0;cd ~/dev
: 1699876550:0;git status
: 1699876560:0;ls -la
```

**Pattern:** `: <timestamp>:<duration>;<command>`

- `timestamp` - Unix epoch seconds
- `duration` - Command duration (often 0)
- `command` - The actual command text

### Multi-line Commands

Commands ending with `\` continue on the next line:

```
: 1699876570:0;docker run \
  --name myapp \
  -p 3000:3000 \
  myimage:latest
```

**Reconstruction:** Join lines, remove trailing `\`, preserve internal whitespace.

### Edge Cases

| Case | Example | Handling |
|------|---------|----------|
| Corrupted timestamp | `: abc:0;cmd` | Skip or use epoch 0 |
| Missing semicolon | `: 123:0cmd` | Skip line |
| Binary/garbled data | `\x00\x01\x02` | Skip line |
| Empty command | `: 123:0;` | Skip line |
| Very long command | 10000+ chars | Truncate for display, keep for filtering |

---

## Parsing Algorithm

### Pseudocode

```
function parse_history(file_path):
    lines = read_all_lines(file_path)
    commands = []
    current_command = nil

    for each line in lines:
        # Try to match history entry format
        if match = line.match(/^: (\d+):\d+;(.*)$/):
            timestamp = match[1].to_i
            command_text = match[2]

            # If we were building a multi-line command, finalize it
            if current_command:
                commands.append(current_command)
                current_command = nil

            # Check if this is a continuation command
            if command_text.ends_with?('\'):
                current_command = Command.new(
                    timestamp: timestamp,
                    text: command_text.chomp('\\'),
                    is_multiline: true,
                    raw_lines: [line]
                )
            else:
                commands.append(Command.new(
                    timestamp: timestamp,
                    text: command_text,
                    is_multiline: false,
                    raw_lines: [line]
                ))

        # Line doesn't match format - might be continuation
        else:
            if current_command:
                # Append to current multi-line command
                current_command.raw_lines.append(line)

                if line.ends_with?('\'):
                    current_command.text += "\n" + line.chomp('\\')
                else:
                    current_command.text += "\n" + line
                    commands.append(current_command)
                    current_command = nil
            else:
                # Orphan line - skip or log warning
                log_warning("Orphan line: #{line}")

    # Don't forget trailing command
    if current_command:
        commands.append(current_command)

    return commands
```

### Implementation Notes

1. **Read entire file** - ZSH history is typically < 10MB, safe to load into memory
2. **Handle encoding** - Use `File.read(path, encoding: 'UTF-8', invalid: :replace)`
3. **Preserve raw lines** - Needed for accurate rewriting
4. **Convert timestamps** - `Time.at(timestamp)` for datetime

---

## Filter System

### Filter Logic

```
for each command in commands:
    # First, check date range
    if options.days and command.datetime < (now - days):
        skip command entirely

    # Check exclude patterns first (noise removal)
    for pattern in exclude_patterns:
        if command.text matches pattern:
            command.category = :unwanted
            break

    # If not excluded, check include patterns
    if command.category != :unwanted:
        for pattern in include_patterns:
            if command.text matches pattern:
                command.category = :wanted
                break

    # If neither matched, it's unsure
    if command.category == nil:
        command.category = :unsure
```

### Default Exclude Patterns

Based on analysis of the user's history files:

```json
{
  "exclude_patterns": [
    "^[a-z]$",
    "^[a-z]{2}$",
    "^ls$",
    "^ls -",
    "^pwd$",
    "^clear$",
    "^exit$",
    "^cd$",
    "^cd -$",
    "^\\.$",
    "^\\.\\.$",
    "^git status$",
    "^git diff$",
    "^git log$",
    "^git pull$",
    "^gs$",
    "^gd$",
    "^gl$",
    "^h$",
    "^history",
    "^which ",
    "^type ",
    "^cat ",
    "^head ",
    "^tail ",
    "^echo \\$",
    "^\\[\\d+\\]",
    "^davidcruwys\\s+\\d+",
    "^zsh: command not found",
    "^X Process completed",
    "^Coverage report",
    "^Line Coverage:",
    "^Finished in \\d",
    "^\\d+ examples, \\d+ failures"
  ]
}
```

**Pattern Categories:**

| Category | Examples | Rationale |
|----------|----------|-----------|
| Single chars | `^[a-z]$` | Typos, not real commands |
| Navigation | `^cd$`, `^pwd$`, `^ls` | High frequency, low value |
| Git read-only | `^git status$`, `^git diff$` | Exploratory, not actions |
| Output lines | `^davidcruwys\\s+\\d+`, `^\[\\d+\]` | Command output, not commands |
| Error messages | `^zsh: command not found` | Noise |
| Test output | `^Finished in`, `^\\d+ examples` | RSpec/test runner output |

### Default Include Patterns

```json
{
  "include_patterns": [
    "^j[a-z]",
    "^dam ",
    "^vat ",
    "^claude ",
    "^c-sonnet",
    "^bun run ",
    "^npm run ",
    "^rake ",
    "^bundle ",
    "^git commit",
    "^git push",
    "^git add",
    "^gac ",
    "^kfeat ",
    "^kfix ",
    "^docker ",
    "^brew install",
    "^gem install",
    "^npm install"
  ]
}
```

**Pattern Categories:**

| Category | Examples | Rationale |
|----------|----------|-----------|
| Jump aliases | `^j[a-z]` | Navigation shortcuts, useful reference |
| AppyDave tools | `^dam `, `^vat ` | Custom tooling usage |
| Claude | `^claude `, `^c-sonnet` | AI assistant commands |
| Build/run | `^bun run `, `^npm run ` | Development workflow |
| Git writes | `^git commit`, `^git push` | Meaningful actions |
| Installs | `^brew install`, `^gem install` | System changes worth tracking |

---

## CLI Interface

### Command Structure

```bash
# Primary command - show clean history
zsh_history clean [options]

# Options
  -d, --days N           Only show last N days
  -w, --write            Rewrite ~/.zsh_history (creates backup)
  -s, --stats            Show statistics only
  -g, --grep PATTERN     Search within history
  -u, --unsure           Include unsure commands in output
  -a, --all              Show all commands (no filtering)
  -v, --verbose          Show which pattern matched each command
  -h, --help             Show help
```

### Usage Examples

```bash
# View clean history (default: wanted only)
zsh_history clean

# View last 7 days
zsh_history clean --days 7

# View with unsure commands included
zsh_history clean --unsure

# Search for docker commands in last 30 days
zsh_history clean --days 30 --grep docker

# Show statistics
zsh_history clean --stats

# Rewrite history file (creates backup first)
zsh_history clean --days 90 --write

# Debug: see which patterns matched
zsh_history clean --verbose
```

### Output Formats

**Default (clean):**
```
2024-11-15 09:30:22  dam s3-up appydave b70
2024-11-15 09:35:10  bun run dev
2024-11-15 10:00:00  git commit -m 'update docs'
```

**Stats:**
```
ZSH History Statistics
═══════════════════════════════════════
Total commands:    12,543
Wanted:             2,341  (18.7%)
Unwanted:           9,876  (78.7%)
Unsure:               326  ( 2.6%)

Date range: 2024-01-01 to 2024-11-15 (319 days)
```

**Verbose:**
```
2024-11-15 09:30:22  [WANTED: ^dam ]  dam s3-up appydave b70
2024-11-15 09:31:00  [EXCLUDE: ^ls$]  ls
2024-11-15 09:35:10  [WANTED: ^bun run ]  bun run dev
```

---

## Configuration

### Config File Location

```
~/.config/appydave/zsh_history.json
```

### Full Config Schema

```json
{
  "history_path": "~/.zsh_history",
  "backup_before_write": true,
  "backup_dir": "~/.config/appydave/backups",
  "exclude_patterns": [
    "^[a-z]$",
    "^ls$",
    "^pwd$",
    "^clear$",
    "^exit$",
    "^cd$",
    "^git status$",
    "^git diff$",
    "^git log$"
  ],
  "include_patterns": [
    "^j[a-z]",
    "^dam ",
    "^claude ",
    "^bun run ",
    "^npm run ",
    "^git commit",
    "^git push"
  ],
  "output": {
    "datetime_format": "%Y-%m-%d %H:%M:%S",
    "show_multiline_indicator": true,
    "max_command_length": 200
  }
}
```

### Config Integration

Uses existing `Appydave::Tools::Configuration` system:

```ruby
module Appydave::Tools::Configuration::Models
  class ZshHistoryConfig < ConfigBase
    # Auto-loads from ~/.config/appydave/zsh_history.json

    def exclude_patterns
      data['exclude_patterns'] || DEFAULT_EXCLUDE_PATTERNS
    end

    def include_patterns
      data['include_patterns'] || DEFAULT_INCLUDE_PATTERNS
    end
  end
end
```

---

## File Structure

### New Files to Create

```
lib/appydave/tools/zsh_history/
├── parser.rb              # Parse ZSH history file
├── filter.rb              # Apply patterns, categorize
├── formatter.rb           # Output formatting, stats
└── command.rb             # Command struct definition

lib/appydave/tools/configuration/models/
└── zsh_history_config.rb  # Config model

bin/
└── zsh_history.rb         # CLI entry point

exe/
└── zsh_history            # Gem executable wrapper

spec/appydave/tools/zsh_history/
├── parser_spec.rb
├── filter_spec.rb
├── formatter_spec.rb
└── fixtures/
    ├── simple_history.txt
    ├── multiline_history.txt
    └── corrupted_history.txt

docs/
├── specs/
│   └── zsh-history-tool.md  # This document
└── usage/
    └── zsh-history.md       # User guide (create after implementation)
```

### Module Registration

Add to `lib/appydave/tools.rb`:

```ruby
require_relative 'tools/zsh_history/command'
require_relative 'tools/zsh_history/parser'
require_relative 'tools/zsh_history/filter'
require_relative 'tools/zsh_history/formatter'
```

Add config to `lib/appydave/tools/configuration/config.rb`:

```ruby
register_config(:zsh_history, Models::ZshHistoryConfig)
```

---

## Implementation Phases

### Phase 1: Core Parser (MVP)

**Goal:** Parse history file and display commands with timestamps

**Tasks:**
1. Create `Command` struct
2. Implement `Parser.parse(file_path)`
3. Handle single-line commands
4. Handle multi-line commands (\ continuations)
5. Basic CLI that outputs parsed commands
6. Unit tests for parser

**Deliverable:**
```bash
zsh_history clean  # Shows all commands with timestamps
```

### Phase 2: Filtering

**Goal:** Apply include/exclude patterns

**Tasks:**
1. Create `Filter` class with `apply(commands, config)`
2. Implement pattern matching (Regexp)
3. Categorize as wanted/unwanted/unsure
4. Add `--stats` flag
5. Unit tests for filter

**Deliverable:**
```bash
zsh_history clean        # Shows filtered (wanted) commands
zsh_history clean --stats  # Shows counts
```

### Phase 3: Date Filtering

**Goal:** Filter by time range

**Tasks:**
1. Add `--days N` option
2. Parse timestamps into Time objects
3. Filter commands older than N days
4. Handle timezone correctly

**Deliverable:**
```bash
zsh_history clean --days 7
```

### Phase 4: Configuration

**Goal:** Load patterns from config file

**Tasks:**
1. Create `ZshHistoryConfig` model
2. Register with configuration system
3. Load exclude/include patterns from JSON
4. Use defaults if config doesn't exist
5. Document default patterns

**Deliverable:**
```bash
# Uses ~/.config/appydave/zsh_history.json
zsh_history clean
```

### Phase 5: Write Mode

**Goal:** Rewrite history file

**Tasks:**
1. Add `--write` flag
2. Create backup before writing
3. Write filtered commands in ZSH history format
4. Validate output before overwriting
5. Safety checks (don't write if < 10% of original)

**Deliverable:**
```bash
zsh_history clean --days 90 --write
```

### Phase 6: Polish

**Goal:** User experience improvements

**Tasks:**
1. Add `--grep` for searching
2. Add `--verbose` for debugging patterns
3. Add `--unsure` to include unsure commands
4. Improve output formatting
5. Create user documentation
6. Add to CLAUDE.md tool list

---

## Testing Strategy

### Unit Tests

**Parser:**
```ruby
RSpec.describe Appydave::Tools::ZshHistory::Parser do
  describe '#parse' do
    it 'parses single-line commands'
    it 'parses multi-line commands with continuations'
    it 'extracts timestamps correctly'
    it 'handles corrupted lines gracefully'
    it 'handles empty file'
    it 'handles missing file'
  end
end
```

**Filter:**
```ruby
RSpec.describe Appydave::Tools::ZshHistory::Filter do
  describe '#apply' do
    it 'excludes commands matching exclude patterns'
    it 'includes commands matching include patterns'
    it 'marks unmatched commands as unsure'
    it 'respects pattern priority (exclude first)'
    it 'handles empty pattern lists'
  end

  describe '#filter_by_date' do
    it 'filters commands older than N days'
    it 'keeps commands within N days'
    it 'handles commands at boundary'
  end
end
```

### Test Fixtures

**simple_history.txt:**
```
: 1699876543:0;cd ~/dev
: 1699876550:0;git status
: 1699876560:0;ls -la
: 1699876570:0;dam s3-up appydave b70
```

**multiline_history.txt:**
```
: 1699876543:0;docker run \
  --name myapp \
  -p 3000:3000 \
  myimage:latest
: 1699876600:0;echo "done"
```

**corrupted_history.txt:**
```
: 1699876543:0;valid command
garbage line here
: badtimestamp:0;another
: 1699876600:0;valid again
```

### Integration Tests

```ruby
RSpec.describe 'zsh_history CLI' do
  it 'displays clean history'
  it 'filters by days'
  it 'shows stats'
  it 'creates backup before writing'
  it 'refuses to write if too few commands remain'
end
```

---

## Future Enhancements

### v1.1 - Interactive Review

```bash
zsh_history review
# Shows unsure commands one by one
# User types 'w' (wanted), 'u' (unwanted), 's' (skip)
# Updates config with new patterns
```

### v1.2 - Pattern Suggestions

```bash
zsh_history suggest
# Analyzes unsure commands
# Suggests patterns based on frequency
# "Found 47 commands starting with 'npx' - add to include? (y/n)"
```

### v1.3 - Export/Import

```bash
zsh_history export --format json > history.json
zsh_history export --format txt > history.txt
zsh_history import --from other_machine.txt
```

### v1.4 - Deduplication

```bash
zsh_history clean --dedupe
# Removes duplicate commands, keeping most recent
```

---

## Appendix: Pattern Reference

### Regex Cheat Sheet

| Pattern | Matches | Example |
|---------|---------|---------|
| `^` | Start of line | `^git` matches "git status" |
| `$` | End of line | `^ls$` matches only "ls" |
| `\s` | Whitespace | `^cd\s` matches "cd ~/dev" |
| `\d+` | One or more digits | `^\d+` matches "123 foo" |
| `[a-z]` | Single lowercase letter | `^[a-z]$` matches "a", "b" |
| `.*` | Any characters | `^git.*push` matches "git push origin main" |
| `\|` | Literal pipe (escaped) | `\|` matches commands with pipes |

### Common Pattern Examples

```ruby
# Match all npm/yarn commands
"^(npm|yarn|bun) "

# Match all git write operations
"^git (add|commit|push|rebase|merge|cherry-pick)"

# Match any command with a pipe
"\\|"

# Match any command with sudo
"^sudo "

# Match docker/docker-compose
"^docker(-compose)? "
```
