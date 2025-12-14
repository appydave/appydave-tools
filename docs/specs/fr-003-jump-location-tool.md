# FR-3: Jump Location Tool

**Status**: Ready for Development
**Added**: 2025-12-13
**Priority**: High - enables unified location management across terminal, Claude Code, and generated config

---

## Summary

A Ruby CLI tool for managing development folder locations with a single source of truth (JSON config) that serves:
- Terminal users (fuzzy search, jump aliases)
- Claude Code (via skill with JSON output)
- Generated shell configuration (aliases-jump.zsh)

---

## Problem Statement

Current pain points:
1. Jump aliases (`jad`, `jss`, `jgb`) are hard to remember
2. No single source of truth - aliases defined in one file, help documentation duplicated elsewhere
3. In Claude Code, need to find folder paths but have no searchable system
4. Locations organized by multiple dimensions (brand, client, type, technology) but no way to view by these dimensions
5. Locations become stale (folders deleted/moved) with no validation

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     locations.json                          │
│                  (Single Source of Truth)                   │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  jump CLI    │      │  Generated   │      │ Claude Skill │
│              │      │    Files     │      │              │
│ - search     │      │              │      │ Calls CLI    │
│ - add/remove │      │ aliases-     │      │ with --format│
│ - validate   │      │ jump.zsh     │      │ json flag    │
│ - reports    │      │              │      │              │
│ - generate   │      │ help content │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
        │
        ▼
┌──────────────┐
│   Terminal   │
│              │
│ j alias      │
│ ah + fzf     │
└──────────────┘
```

---

## File Locations

| File | Path |
|------|------|
| Tool code | `lib/appydave/tools/jump/` |
| Config file | `~/.config/appydave/locations.json` |
| Generated aliases | `~/.oh-my-zsh/custom/aliases-jump.zsh` |
| Help content | `~/.oh-my-zsh/custom/data/jump-help.txt` |
| Claude skill | `~/.claude/skills/jump-locations.md` |

**Note**: Config follows existing pattern - stored in `~/.config/appydave/` alongside `settings.json`, `channels.json`, etc. Uses the same config infrastructure with injectable paths for testing.

---

## Data Model

### locations.json Structure

```json
{
  "meta": {
    "version": "1.0",
    "last_validated": "2025-12-13T10:00:00Z"
  },
  "categories": {
    "type": {
      "description": "Kind of location",
      "values": ["brand", "client", "gem", "video", "brain", "site", "tool", "config"]
    },
    "technology": {
      "description": "Primary language/framework",
      "values": ["ruby", "javascript", "typescript", "python", "astro"]
    }
  },
  "brands": {
    "appydave": {
      "aliases": ["ad", "appy", "dave"],
      "description": "AppyDave brand"
    },
    "flivideo": {
      "aliases": ["fli"],
      "description": "FliVideo brand"
    }
  },
  "clients": {
    "supportsignal": {
      "aliases": ["ss"],
      "description": "SupportSignal client"
    }
  },
  "locations": [
    {
      "key": "ad-tools",
      "path": "~/dev/ad/appydave-tools",
      "jump": "jad-tools",
      "brand": "appydave",
      "type": "tool",
      "tags": ["ruby", "cli"],
      "description": "AppyDave CLI tools"
    }
  ]
}
```

### Location Entry Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| key | Yes | - | Unique identifier (alphanumeric + hyphens, lowercase) |
| path | Yes | - | Directory path (supports ~) |
| jump | No | `j` + key | Shell alias name |
| brand | No | - | Associated brand key |
| client | No | - | Associated client key |
| type | No | - | Category type |
| tags | No | [] | Searchable tags array |
| description | No | - | Human description |

---

## CLI Commands

### Command Name

`jump` (installed via gem as `jump`)

### Search & Retrieval

```bash
# Fuzzy search (primary use case)
jump search <terms>
jump search appydave ruby
jump search ss app

# Get by exact key
jump get <key>
jump get ad-tools

# List all
jump list

# All commands support --format
jump search appydave --format json|table|paths
```

### CRUD Operations

```bash
# Add
jump add --key <key> --path <path> [--jump alias] [--brand brand] \
         [--client client] [--type type] [--tags t1,t2] [--description "desc"]

# Update
jump update <key> [--path path] [--brand brand] [--tags tags] ...

# Remove
jump remove <key>
jump remove <key> --force
```

### Validation

```bash
# Validate all paths exist
jump validate

# Validate specific key
jump validate <key>
```

**Behavior**: Report only - shows valid/invalid/missing paths. Does NOT auto-prompt for removal. User decides what to do.

### Reports (View Data by Dimension)

```bash
# List all categories and their values
jump report categories

# List all brands with location counts
jump report brands

# List all clients with location counts
jump report clients

# List all types with location counts
jump report types

# List all tags with location counts
jump report tags

# List locations grouped by brand
jump report by-brand
jump report by-brand appydave

# List locations grouped by client
jump report by-client

# List locations grouped by type
jump report by-type

# List locations grouped by tag
jump report by-tag ruby

# Summary overview
jump report summary
```

### Generation

```bash
# Generate shell aliases (stdout by default)
jump generate aliases
jump generate aliases --output ~/.oh-my-zsh/custom/aliases-jump.zsh

# Generate help content for ah/fzf
jump generate help
jump generate help --output ~/.oh-my-zsh/custom/data/jump-help.txt

# Generate both
jump generate all
jump generate all --output-dir ~/.oh-my-zsh/custom/
```

**Behavior**:
- Stdout by default
- Use `--output <file>` to write to file
- **Important**: Before first use, manually backup existing `aliases-jump.zsh` once

### Info

```bash
# Show config path, location count, last validated
jump info
```

---

## Output Formats

| Format | Flag | Use Case |
|--------|------|----------|
| table | `--format table` (default) | Human terminal reading - **pretty with colors** |
| json | `--format json` | Claude skill, programmatic access |
| paths | `--format paths` | Scripting, piping |

### JSON Response Structure

**Success**:
```json
{
  "success": true,
  "count": 2,
  "results": [
    {
      "index": 1,
      "key": "ad-tools",
      "path": "/Users/davidcruwys/dev/ad/appydave-tools",
      "jump": "jad-tools",
      "brand": "appydave",
      "type": "tool",
      "tags": ["ruby", "cli"],
      "description": "AppyDave CLI tools",
      "score": 85
    }
  ]
}
```

**Error**:
```json
{
  "success": false,
  "error": "Location not found",
  "code": "NOT_FOUND",
  "suggestion": "Did you mean: ad-tools, ad-brand?"
}
```

---

## Search Algorithm

### Fields Searched

All fields concatenated for matching:
- key, path, brand (+ aliases), client (+ aliases), type, tags, description

### Scoring

| Match Type | Points |
|------------|--------|
| Exact key match | 100 |
| Key contains term | 50 |
| Brand/client alias match | 40 |
| Tag match | 30 |
| Type match | 20 |
| Description contains | 10 |
| Path contains | 5 |

Multiple search terms: sum scores for each matching term.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Not found |
| 2 | Invalid input |
| 3 | Config error |
| 4 | Path not found |

---

## Defensive Coding Requirements

### Input Validation

- **Keys**: alphanumeric + hyphens only, lowercase
- **Paths**: must start with `~` or `/`, no shell metacharacters
- **Tags**: lowercase, alphanumeric + hyphens
- **All strings**: strip whitespace, reasonable length limits

### Error Handling

- Never crash on bad input
- Always return structured response (success/error)
- Include suggestions on NOT_FOUND (fuzzy match alternatives)

### Config Safety

- Backup before writes (timestamped backup files)
- Atomic writes (temp file then rename)
- Handle missing/corrupt config (create defaults)
- Validate JSON structure on load

---

## Claude Skill Specification

**File**: `~/.claude/skills/jump-locations.md`

```markdown
# Jump - Location Finder

Find and manage development folder locations. Use when user asks
"where is", "find folder", "path to", "jump to", or needs to
locate project/brand/client directories.

## Prerequisites

Tool must be installed at ~/dev/ad/appydave-tools

## Commands

### Search for locations
jump search <terms> --format json

Returns ranked matches. Terms are fuzzy matched against all fields.

### Get specific location
jump get <key> --format json

Returns single location by exact key.

### List all locations
jump list --format json

### Add new location
jump add --key <key> --path <path> [options] --format json

Options:
  --jump <alias>       Jump alias (default: j + key)
  --brand <brand>      Associated brand
  --client <client>    Associated client
  --type <type>        Location type
  --tags <t1,t2,t3>    Comma-separated tags
  --description <desc> Human description

### Remove location
jump remove <key> --force --format json

### Validate locations
jump validate --format json

### Reports
jump report brands --format json
jump report clients --format json
jump report types --format json
jump report tags --format json
jump report by-brand [brand] --format json
jump report summary --format json

## Natural Language Mappings

| User Says | Command |
|-----------|---------|
| "Where are the appydave tools?" | jump search appydave tools --format json |
| "Show me all client folders" | jump report by-client --format json |
| "What brands do I have?" | jump report brands --format json |
| "Add a location for xyz at ~/dev/xyz" | jump add --key xyz --path ~/dev/xyz --format json |
| "Is the ss folder still valid?" | jump validate ss --format json |
| "What ruby projects do I have?" | jump search ruby --format json |
| "Show me supportsignal locations" | jump search supportsignal --format json |
| "Remove old-project" | jump remove old-project --force --format json |
| "What types of locations exist?" | jump report types --format json |
| "Show all locations grouped by brand" | jump report by-brand --format json |

## Response Handling

All JSON responses have:
- success: boolean
- For lists: count + results array
- For single: result object
- On error: error message + code + suggestion

## Error Recovery

1. NOT_FOUND: Check suggestion field for alternatives
2. INVALID_INPUT: Report validation issue to user
3. PATH_NOT_FOUND: Ask user to verify path exists
```

---

## Testing Architecture

### The Problem

The `locations.json` config contains real filesystem paths (e.g., `~/dev/ad/appydave-tools`) that:
- Exist on David's development machine
- Won't exist in CI environment
- Are unique to each developer's system

We need to test search, validation, reports, and generation without depending on real filesystem paths.

### Solution: Dependency Injection

Use dependency injection for filesystem operations, following the existing codebase pattern where `spec_helper.rb` uses `Dir.mktmpdir` for config paths.

#### Config Path Injection (Existing Pattern)

```ruby
# spec_helper.rb - already established pattern
Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
end
```

The Jump tool's config (`~/.config/appydave/locations.json`) follows this same pattern - config path is injectable.

#### Path Validator Injection (New for Jump)

Inject a `PathValidator` dependency that can be swapped for testing:

**Production implementation**:
```ruby
# lib/appydave/tools/jump/path_validator.rb
module Appydave
  module Tools
    module Jump
      class PathValidator
        def exists?(path)
          File.directory?(File.expand_path(path))
        end

        def expand(path)
          File.expand_path(path)
        end
      end
    end
  end
end
```

**Test implementation**:
```ruby
# spec/support/jump_test_helpers.rb
class TestPathValidator
  def initialize(valid_paths: [])
    @valid_paths = valid_paths.map { |p| File.expand_path(p) }
  end

  def exists?(path)
    expanded = File.expand_path(path)
    @valid_paths.include?(expanded)
  end

  def expand(path)
    File.expand_path(path)
  end
end
```

#### Usage in Classes

Classes that need filesystem access accept validator as dependency:

```ruby
# lib/appydave/tools/jump/commands/validate.rb
module Appydave
  module Tools
    module Jump
      module Commands
        class Validate
          def initialize(config, path_validator: PathValidator.new)
            @config = config
            @path_validator = path_validator
          end

          def run
            @config.locations.map do |location|
              {
                key: location.key,
                path: location.path,
                valid: @path_validator.exists?(location.path)
              }
            end
          end
        end
      end
    end
  end
end
```

#### Test Example

```ruby
# spec/appydave/tools/jump/commands/validate_spec.rb
RSpec.describe Appydave::Tools::Jump::Commands::Validate do
  let(:config) { build_test_config(locations: test_locations) }
  let(:path_validator) { TestPathValidator.new(valid_paths: ['~/real-path']) }

  subject { described_class.new(config, path_validator: path_validator) }

  let(:test_locations) do
    [
      { key: 'valid-loc', path: '~/real-path' },
      { key: 'invalid-loc', path: '~/does-not-exist' }
    ]
  end

  it 'identifies valid and invalid paths' do
    results = subject.run

    expect(results.find { |r| r[:key] == 'valid-loc' }[:valid]).to be true
    expect(results.find { |r| r[:key] == 'invalid-loc' }[:valid]).to be false
  end
end
```

### What Gets Injected

| Dependency | Production | Test |
|------------|------------|------|
| Config path | `~/.config/appydave/` | `Dir.mktmpdir` |
| Path validator | `PathValidator` (real filesystem) | `TestPathValidator` (mock valid paths) |
| Output stream | `$stdout` | `StringIO` (capture output) |

### What Doesn't Need Injection

These can be tested directly without mocking:
- **Search algorithm** - operates on in-memory data
- **Scoring logic** - pure functions
- **JSON formatting** - string transformation
- **Config parsing** - uses test fixture files
- **Report aggregation** - operates on config data

### Test Fixture Strategy

```
spec/fixtures/jump/
├── locations_basic.json       # Simple config for unit tests
├── locations_full.json        # Complete config with all fields
├── locations_empty.json       # Edge case: no locations
├── locations_invalid.json     # Malformed JSON for error handling
└── examples.yml               # Data-driven test cases
```

### CI Compatibility

With this approach:
- No real filesystem dependencies in tests
- All paths validated against mock validator
- Config loaded from temp directories with fixture data
- Tests run identically on dev machines and CI

---

## Test Strategy

### Data-Driven Testing

Tests use YAML fixtures for easy maintenance. See `spec/fixtures/jump/examples.yml`.

**Test categories**:
- Search examples (by brand, alias, tag, multiple terms, no matches)
- Get examples (exact key, non-existent, suggestions)
- Add examples (minimal, all fields, invalid input, duplicate)
- Validate examples (existing paths, missing paths, mixed)
- Report examples (brands, clients, tags, by-brand filtered)
- Generate examples (alias lines, help lines, default jump)
- Edge cases (empty query, special characters, paths with spaces, unicode)

### Test Runner Pattern

```ruby
# spec/appydave/tools/jump/search_spec.rb
RSpec.describe Appydave::Tools::Jump::Search do
  examples = YAML.load_file('spec/fixtures/jump_examples.yml')

  examples['search_examples'].each do |example|
    it example['name'] do
      config = build_test_config(example['given'])
      searcher = described_class.new(config)
      result = searcher.search(example['given']['query'])

      expect(result[:success]).to eq(example['expect']['success'])
      # ... additional assertions
    end
  end
end
```

---

## Seed Data Task

Before the tool is useful, `locations.json` needs initial data.

### Source

Current `~/.oh-my-zsh/custom/aliases-jump.zsh`

### Process

1. Parse existing alias lines: `alias jfoo="cd ~/path"`
2. Extract key (remove `j` prefix), path, jump alias
3. Infer brand from path (`/ad/` → appydave, `/clients/supportsignal` → supportsignal)
4. Infer type from path patterns
5. Validate all paths exist
6. Generate initial `locations.json`

### Implementation

Could be:
- One-time migration script
- `jump import <file>` command (preferred - reusable)

---

## Phase 2 (Future, Not MVP)

Design should accommodate but NOT implement:

- **DAM integration**: Dynamic video project folders
- **FliHub integration**: Active/pinned project status
- **Watch mode**: Auto-regenerate on config change
- **Computed filters**: `--active` flag from external sources

---

## Acceptance Criteria

### Core Functionality

- [ ] `jump search <terms>` returns fuzzy-matched results with scores
- [ ] `jump get <key>` returns single location or error with suggestion
- [ ] `jump list` shows all locations
- [ ] `jump add` creates new location with validation
- [ ] `jump update` modifies existing location
- [ ] `jump remove` deletes location (with `--force` for no prompt)
- [ ] `jump validate` checks all paths exist, reports results

### Reports

- [ ] `jump report brands/clients/types/tags` shows counts
- [ ] `jump report by-brand/by-client/by-type/by-tag` groups locations
- [ ] `jump report summary` shows overview

### Generation

- [ ] `jump generate aliases` outputs shell alias format
- [ ] `jump generate help` outputs fzf-friendly help format
- [ ] `--output <file>` writes to file instead of stdout

### Output Formats

- [ ] `--format table` shows colored, pretty output (default)
- [ ] `--format json` returns structured JSON
- [ ] `--format paths` returns one path per line

### Error Handling

- [ ] Invalid input returns structured error with code
- [ ] NOT_FOUND includes fuzzy suggestions
- [ ] Config errors handled gracefully (create defaults if missing)
- [ ] Exit codes match specification

### Claude Skill

- [ ] Skill file generated and installable
- [ ] All commands work with `--format json`
- [ ] Error responses include recovery suggestions

---

## Deliverables Checklist

| Deliverable | Description |
|-------------|-------------|
| Data model | `locations.json` with meta, categories, brands, clients, locations |
| CLI commands | search, get, list, add, update, remove, validate, generate, report, info |
| Output formats | table (colored), json, paths |
| Search algorithm | Fuzzy match with weighted scoring |
| Reports | By brand, client, type, tag, summary |
| Generation | aliases-jump.zsh, help content (stdout default) |
| Claude skill | Skill file with command mappings and examples |
| Test fixtures | YAML-driven test cases |
| Seed data | Import from existing aliases-jump.zsh |
| Defensive coding | Input validation, error handling, config safety |

---

## Implementation Notes

### CLI Pattern

This is a **Pattern 4: Method Dispatch (Full)** tool per the CLI patterns guide:
- 10+ commands
- Hierarchical help system (`jump help search`, `jump help report`)
- Complex argument parsing per command

### Module Structure

```
lib/appydave/tools/jump/
├── cli.rb              # Command routing and help
├── config.rb           # Load/save locations.json
├── search.rb           # Search algorithm
├── location.rb         # Location model/validation
├── commands/
│   ├── add.rb
│   ├── update.rb
│   ├── remove.rb
│   ├── validate.rb
│   ├── generate.rb
│   └── report.rb
├── formatters/
│   ├── table.rb        # Colored table output
│   ├── json.rb
│   └── paths.rb
└── importers/
    └── alias_file.rb   # Import from aliases-jump.zsh
```

---

**Last updated**: 2025-12-13
