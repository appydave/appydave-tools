# exe/ vs bin/ Directory Convention

This document explains the convention for organizing CLI executables in appydave-tools, following standard RubyGems practices.

## Table of Contents

- [Overview](#overview)
- [Directory Purposes](#directory-purposes)
- [How It Works](#how-it-works)
- [File Structure Examples](#file-structure-examples)
- [Creating New CLI Tools](#creating-new-cli-tools)
- [Gemspec Configuration](#gemspec-configuration)
- [Development vs Installation](#development-vs-installation)
- [Why This Pattern?](#why-this-pattern)

---

## Overview

The project uses two directories for executables:

| Directory | Purpose | File Extension | When Used |
|-----------|---------|----------------|-----------|
| `bin/` | Full CLI implementation | `.rb` | Development |
| `exe/` | Thin wrapper for gem installation | None | Gem users |

This follows the standard RubyGems convention where:
- **`bin/`** contains development scripts and the full CLI implementation
- **`exe/`** contains the executables that get installed when users run `gem install`

---

## Directory Purposes

### bin/ Directory

**Purpose:** Contains the actual CLI implementation code.

**Contents:**
- Full Ruby scripts with CLI classes
- OptionParser configuration
- Command routing logic
- All CLI-specific code

**File naming:** `tool_name.rb` (with `.rb` extension)

**Example:**
```
bin/
├── subtitle_processor.rb    # Full 200-line CLI implementation
├── gpt_context.rb           # Full CLI implementation
├── youtube_manager.rb       # Full CLI implementation
└── console                  # IRB console for development
```

### exe/ Directory

**Purpose:** Contains thin wrapper scripts that get installed as system commands.

**Contents:**
- Minimal Ruby scripts (typically 3-7 lines)
- Just loads the corresponding `bin/` file
- No business logic

**File naming:** `tool_name` (NO `.rb` extension)

**Example:**
```
exe/
├── subtitle_processor       # Wrapper → loads bin/subtitle_processor.rb
├── gpt_context              # Wrapper → loads bin/gpt_context.rb
├── youtube_manager          # Wrapper → loads bin/youtube_manager.rb
└── ad_config                # Wrapper → loads bin/configuration.rb
```

---

## How It Works

### The Wrapper Pattern

Each `exe/` file is a thin wrapper that loads its corresponding `bin/` implementation:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

load File.expand_path('../bin/subtitle_processor.rb', __dir__)
```

### Flow Diagram

```
User runs: subtitle_processor clean -f input.srt -o output.srt
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  exe/subtitle_processor (installed in PATH)             │
│  ├── require 'appydave/tools'                          │
│  └── load '../bin/subtitle_processor.rb'               │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  bin/subtitle_processor.rb (full implementation)        │
│  ├── class SubtitleProcessorCLI                        │
│  ├── def clean_subtitles(args)                         │
│  ├── def join_subtitles(args)                          │
│  └── SubtitleProcessorCLI.new.run                      │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  lib/appydave/tools/subtitle_processor/clean.rb        │
│  (business logic)                                       │
└─────────────────────────────────────────────────────────┘
```

---

## File Structure Examples

### Complete Example: subtitle_processor

**exe/subtitle_processor** (7 lines - wrapper):
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

load File.expand_path('../bin/subtitle_processor.rb', __dir__)
```

**bin/subtitle_processor.rb** (200+ lines - full implementation):
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

class SubtitleProcessorCLI
  def initialize
    @commands = {
      'clean' => method(:clean_subtitles),
      'join' => method(:join_subtitles),
      'transcript' => method(:transcript_subtitles)
    }
  end

  def run
    command, *args = ARGV
    # ... command routing
  end

  private

  def clean_subtitles(args)
    # ... 50 lines of option parsing and execution
  end

  def join_subtitles(args)
    # ... 50 lines of option parsing and execution
  end

  # ... more methods
end

SubtitleProcessorCLI.new.run
```

### Example: gpt_context

**exe/gpt_context**:
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

load File.expand_path('../bin/gpt_context.rb', __dir__)
```

### Example: ad_config (different naming)

Sometimes the exe/ name differs from bin/ name:

**exe/ad_config** → **bin/configuration.rb**:
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

load File.expand_path('../bin/configuration.rb', __dir__)
```

---

## Creating New CLI Tools

### Step 1: Create the bin/ Implementation

```bash
touch bin/my_tool.rb
chmod +x bin/my_tool.rb
```

**bin/my_tool.rb:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

class MyToolCLI
  def run
    # Full CLI implementation here
  end
end

MyToolCLI.new.run
```

### Step 2: Create the exe/ Wrapper

```bash
touch exe/my_tool
chmod +x exe/my_tool
```

**exe/my_tool:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

load File.expand_path('../bin/my_tool.rb', __dir__)
```

### Step 3: Verify in Gemspec

The gemspec automatically includes all `exe/` files:

```ruby
# appydave-tools.gemspec
spec.bindir        = 'exe'
spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
```

### Step 4: Test Both Ways

**Development (from project directory):**
```bash
bin/my_tool.rb --help
```

**After gem install:**
```bash
my_tool --help
```

---

## Gemspec Configuration

The gemspec defines how executables are installed:

```ruby
# appydave-tools.gemspec

Gem::Specification.new do |spec|
  # ...

  # The directory containing executables
  spec.bindir        = 'exe'

  # Automatically find all files in exe/ directory
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  # ...
end
```

### What This Means

1. **`spec.bindir = 'exe'`** - Tells RubyGems to look in `exe/` for executables
2. **`spec.executables = ...`** - Lists all files in `exe/` as installable commands
3. **No `.rb` extension** - Files in `exe/` don't have extensions, so `exe/gpt_context` becomes the `gpt_context` command

### Verification

```bash
# List what will be installed as executables
ruby -e "puts Gem::Specification.load('appydave-tools.gemspec').executables"
```

Expected output:
```
gpt_context
youtube_manager
prompt_tools
youtube_automation
ad_config
dam
subtitle_processor
zsh_history
```

---

## Development vs Installation

### During Development

Run tools directly from `bin/` with the `.rb` extension:

```bash
# From project root
bin/subtitle_processor.rb clean -f input.srt -o output.srt

# Or make it executable and run directly
chmod +x bin/subtitle_processor.rb
./bin/subtitle_processor.rb clean -f input.srt -o output.srt
```

**Why use bin/ during development:**
- No gem installation needed
- Changes take effect immediately
- `$LOAD_PATH` is set to use local `lib/`

### After Gem Installation

Users run the command without extension:

```bash
# After: gem install appydave-tools
subtitle_processor clean -f input.srt -o output.srt
```

**What happens:**
1. Shell finds `subtitle_processor` in PATH (installed by gem)
2. That's actually `exe/subtitle_processor`
3. Which loads `bin/subtitle_processor.rb` from the installed gem
4. Which uses `lib/appydave/tools/` from the installed gem

---

## Why This Pattern?

### 1. Separation of Concerns

| Directory | Responsibility |
|-----------|----------------|
| `exe/` | Entry point (what gets installed) |
| `bin/` | CLI implementation |
| `lib/` | Business logic |

### 2. Standard RubyGems Convention

This follows how most Ruby gems organize executables:
- Rails uses `exe/rails` → internal implementation
- Bundler uses `exe/bundler` → internal implementation
- RuboCop uses `exe/rubocop` → internal implementation

### 3. Clean Installation

Users get clean command names without `.rb` extension:
```bash
# Clean
subtitle_processor clean -f input.srt

# Not
subtitle_processor.rb clean -f input.srt
```

### 4. Development Flexibility

Developers can:
- Run `bin/*.rb` directly during development
- Test changes without reinstalling gem
- Keep development scripts (like `bin/console`) separate from installed commands

### 5. Single Source of Truth

The `exe/` wrappers just load `bin/` files, so:
- Only one place to edit CLI code (`bin/`)
- No duplication between development and installed versions
- Easy to maintain

---

## Current exe/ Files

| exe/ file | Loads | Command |
|-----------|-------|---------|
| `exe/gpt_context` | `bin/gpt_context.rb` | `gpt_context` |
| `exe/youtube_manager` | `bin/youtube_manager.rb` | `youtube_manager` |
| `exe/prompt_tools` | `bin/prompt_tools.rb` | `prompt_tools` |
| `exe/youtube_automation` | `bin/youtube_automation.rb` | `youtube_automation` |
| `exe/ad_config` | `bin/configuration.rb` | `ad_config` |
| `exe/dam` | `bin/dam` | `dam` |
| `exe/subtitle_processor` | `bin/subtitle_processor.rb` | `subtitle_processor` |
| `exe/zsh_history` | `bin/zsh_history.rb` | `zsh_history` |

---

## Summary

| Aspect | bin/ | exe/ |
|--------|------|------|
| **Purpose** | Full CLI implementation | Thin wrapper for installation |
| **Extension** | `.rb` | None |
| **Size** | 50-500+ lines | 3-7 lines |
| **Contains** | OptionParser, routing, CLI classes | Just `require` and `load` |
| **Used during** | Development | After gem install |
| **Edited** | Frequently | Rarely (only when adding new tools) |

**Key takeaway:** Edit `bin/`, don't touch `exe/` unless adding a new tool.

---

**Last updated:** 2025-12-13
