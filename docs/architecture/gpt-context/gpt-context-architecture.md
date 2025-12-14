# GPT Context Gatherer - Architecture & Data Flow

**Overview**: A lightweight, stateless file collection system with three core components.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GPT Context System                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐   │
│  │   CLI       │───▶│  FileCollector  │───▶│  OutputHandler   │   │
│  │ (bin/gpt_   │    │                 │    │                  │   │
│  │  context.rb)│    │ - Pattern match │    │ - Clipboard      │   │
│  └─────────────┘    │ - Tree build    │    │ - File write     │   │
│         │           │ - Content read  │    └──────────────────┘   │
│         │           │ - JSON format   │             │              │
│         ▼           │ - Aider format  │             ▼              │
│  ┌─────────────┐    └─────────────────┘    ┌──────────────────┐   │
│  │   Options   │                           │     Output        │   │
│  │   (Struct)  │                           │ - Clipboard       │   │
│  └─────────────┘                           │ - Files (.txt)    │   │
│                                            │ - JSON            │   │
│                                            └──────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Options (Configuration)

**File**: `lib/appydave/tools/gpt_context/options.rb`

A `Struct` with keyword initialization that holds all configuration:

| Property | Type | Default | Purpose |
|----------|------|---------|---------|
| `include_patterns` | Array | `[]` | Glob patterns for files to include |
| `exclude_patterns` | Array | `[]` | Glob patterns for files to exclude |
| `format` | String | `'tree,content'` | Output format(s), comma-separated |
| `line_limit` | Integer | `nil` | Max lines per file (nil = unlimited) |
| `debug` | String | `'none'` | Debug level: none, info, params, debug |
| `output_target` | Array | `[]` | Output destinations (clipboard/files) |
| `working_directory` | String | `nil` | Base directory for file collection |
| `prompt` | String | `nil` | Prompt text for aider format |

**Design choice**: Using `Struct` provides:
- Lightweight data container
- Named parameters via `keyword_init: true`
- Default values in initializer
- No ActiveModel dependency

### 2. FileCollector (Core Logic)

**File**: `lib/appydave/tools/gpt_context/file_collector.rb`

The heart of the system. Responsibilities:

1. **Pattern matching** - Expand glob patterns to file lists
2. **Exclusion filtering** - Remove files matching exclude patterns
3. **Content reading** - Read file contents with optional line limits
4. **Format generation** - Build output in requested format(s)

**Key methods**:

| Method | Purpose |
|--------|---------|
| `build` | Main entry point, orchestrates format generation |
| `build_tree` | Generate ASCII tree structure |
| `build_content` | Concatenate file contents with headers |
| `build_json` | Generate JSON with tree and content |
| `build_aider` | Generate aider CLI command |
| `excluded?` | Check if file matches exclusion patterns |

### 3. OutputHandler (Delivery)

**File**: `lib/appydave/tools/gpt_context/output_handler.rb`

Handles output to multiple targets:

| Target | Behavior |
|--------|----------|
| `clipboard` | Uses `Clipboard` gem to copy content |
| File path | Writes content to specified file |

**Path resolution**: Relative paths are resolved against `working_directory`.

---

## Data Flow

### 1. Input Processing

```
CLI Arguments
     │
     ▼
OptionParser ──────▶ Options Struct
     │
     ▼
Validation (patterns required)
     │
     ▼
Default application (clipboard if no -o)
```

### 2. File Collection

```
Include Patterns ──────┐
                       ▼
                  Dir.glob()
                       │
                       ▼
            ┌──────────────────┐
            │ For each file:   │
            │  - Check exclude │
            │  - Skip if dir   │
            │  - Add to list   │
            └──────────────────┘
                       │
                       ▼
              Filtered File List
```

### 3. Format Generation

```
Format String (e.g., "tree,content")
            │
            ▼
      Split by comma
            │
            ├──▶ 'tree'    ──▶ build_tree()
            ├──▶ 'content' ──▶ build_content()
            ├──▶ 'json'    ──▶ build_json()
            └──▶ 'aider'   ──▶ build_aider()
                                    │
                                    ▼
                            Join with "\n\n"
                                    │
                                    ▼
                           Combined Output String
```

### 4. Output Delivery

```
Combined Output
      │
      ▼
OutputHandler.execute()
      │
      ├──▶ 'clipboard' ──▶ Clipboard.copy()
      │
      └──▶ file path   ──▶ File.write()
```

---

## Output Formats

### Tree Format

ASCII art directory structure:

```
├─ lib
│ ├─ appydave
│ │ └─ tools
│ │   └─ gpt_context
│ │     ├─ file_collector.rb
│ │     ├─ options.rb
│ │     └─ output_handler.rb
└─ bin
  └─ gpt_context.rb
```

**Algorithm**: Build nested hash from path parts, then render with box-drawing characters.

### Content Format

Concatenated file contents with headers:

```
# file: lib/appydave/tools/gpt_context/options.rb

# frozen_string_literal: true

module Appydave
  module Tools
    module GptContext
      Options = Struct.new(
        ...
      )
    end
  end
end

# file: lib/appydave/tools/gpt_context/file_collector.rb

# frozen_string_literal: true
...
```

### JSON Format

Structured data with both tree and content:

```json
{
  "tree": {
    "lib": {
      "appydave": {
        "tools": {
          "gpt_context": {
            "options.rb": {},
            "file_collector.rb": {}
          }
        }
      }
    }
  },
  "content": [
    {
      "file": "lib/appydave/tools/gpt_context/options.rb",
      "content": "# frozen_string_literal: true\n..."
    }
  ]
}
```

### Aider Format

Command-line for aider tool:

```
aider --message "Add logging to all methods" lib/foo.rb lib/bar.rb lib/baz.rb
```

---

## Pattern Matching

### Include Patterns

Uses Ruby's `Dir.glob` with standard glob syntax:

| Pattern | Matches |
|---------|---------|
| `*.rb` | Ruby files in current directory |
| `**/*.rb` | Ruby files in all subdirectories |
| `lib/**/*.rb` | Ruby files under lib/ |
| `{lib,spec}/**/*.rb` | Ruby files under lib/ or spec/ |

### Exclude Patterns

Uses `File.fnmatch` with `FNM_PATHNAME | FNM_DOTMATCH` flags:

| Pattern | Excludes |
|---------|----------|
| `spec/**/*` | Everything under spec/ |
| `**/node_modules/**/*` | All node_modules directories |
| `*.log` | Log files |

**Important**: Exclude patterns are checked AFTER include patterns match.

---

## State Management

GPT Context is **stateless**:

- No database
- No configuration files (beyond CLI options)
- No history tracking
- No caching

Each invocation:
1. Reads options from CLI
2. Collects files from filesystem
3. Outputs result
4. Exits

This simplicity is intentional - it's a utility, not an application.

---

## Dependencies

| Dependency | Purpose | Required? |
|------------|---------|-----------|
| `clipboard` | Clipboard operations | Yes |
| `json` | JSON formatting (stdlib) | Yes |
| `fileutils` | Directory operations (stdlib) | Yes |
| `optparse` | CLI parsing (stdlib) | Yes |

No external services. No network access. No configuration files.

---

## Error Handling

Current approach is minimal (by design):

| Scenario | Behavior |
|----------|----------|
| No patterns provided | Shows help message, exits |
| Invalid directory | `Dir.exist?` check, falls back to pwd |
| File read error | Not explicitly handled (Ruby exception) |
| Clipboard unavailable | Not explicitly handled (Clipboard gem exception) |

**Philosophy**: Fail fast, fail loudly. Users can debug from error messages.

---

**Related Documentation**:
- [Vision & Strategy](./gpt-context-vision.md)
- [Implementation Guide](./gpt-context-implementation-guide.md)
- [Usage Guide](../../guides/tools/gpt-context.md)
