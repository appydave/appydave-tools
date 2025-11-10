# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

**AppyDave Tools** is a consolidated productivity toolkit built for AppyDave's YouTube content creation workflow. All utilities live in one repository for easier maintenance than managing separate codebases.

**📖 See [docs/purpose-and-philosophy.md](./docs/purpose-and-philosophy.md) for complete philosophy and design principles.**

**Key Points:**
- **Consolidated toolkit** - One codebase for easier maintenance
- **YouTube workflow** - Built specifically for content creator productivity
- **Single-purpose tools** - Each tool solves one problem independently
- **Shareable individually** - Tools can be featured in standalone videos
- **Language flexible** - Currently Ruby, could be rewritten if needed

## Common Commands

### Development Setup

**⚠️ IMPORTANT: Bundler Setup for Claude Code**

This project requires Bundler 2.6.2. If you encounter `Could not find 'bundler' (2.6.2)` errors during Claude Code execution:

**Automatic fix (recommended):**
```bash
eval "$(rbenv init -)" && gem install bundler:2.6.2
```

**Make permanent** - Add to your `.zshrc` or `.bashrc`:
```bash
# Add rbenv to PATH and initialize
eval "$(rbenv init - zsh)"
```

**For Claude Code:** The `eval "$(rbenv init -)"` command is automatically prepended to bash commands when needed.

**Manual verification:**
```bash
which ruby          # Should show: /Users/[user]/.rbenv/shims/ruby
ruby --version      # Should show: ruby 3.4.2
bundler --version   # Should show: Bundler version 2.6.2
```

**Standard setup:**
```bash
bin/setup           # Install dependencies and setup development environment
bin/console         # Interactive Ruby console for experimentation
```

### CLI Tools Usage

**Installation Note:** When installed as a gem (`gem install appydave-tools`), these tools are available as system commands. During development, run them from `bin/` directory as `bin/script_name.rb`.

#### Quick Reference Index

| Command | Gem Command | Description | Status |
|---------|-------------|-------------|--------|
| **GPT Context** | `gpt_context` | Collect project files for AI context | ⭐ PRIMARY |
| **YouTube Manager** | `youtube_manager` | CRUD operations on YouTube video metadata | ✅ ACTIVE |
| **Subtitle Processor** | `subtitle_processor` | Transform SRT files (clean/merge) | ✅ ACTIVE |
| **DAM (Digital Asset Management)** | `vat` | Multi-tenant video project storage orchestration | ✅ ACTIVE |
| **Configuration** | `ad_config` | Manage JSON configs (channels, paths, sequences) | ✅ ACTIVE |
| **Move Images** | N/A (dev only) | Organize video asset images | ✅ ACTIVE |
| **Prompt Tools** | `prompt_tools` | OpenAI Completion API wrapper | ⚠️ DEPRECATED API |
| **YouTube Automation** | `youtube_automation` | Prompt sequence runner | ⚠️ INTERNAL USE |

---

#### 1. GPT Context Gatherer (`bin/gpt_context.rb`) ⭐ PRIMARY TOOL
Collect and organize project files for AI context:

```bash
# Basic usage - gather files with debug output and file output
bin/gpt_context.rb -i '**/*.rb' -e 'spec/**/*' -d -o context.txt

# Multiple formats and patterns
bin/gpt_context.rb -i 'lib/**/*.rb' -i 'bin/**/*.rb' -f tree,content -d

# Advanced web project filtering
bin/gpt_context.rb -i 'apps/**/*.ts' -i 'apps/**/*.tsx' -e '**/node_modules/**/*' -e '**/_generated/**/*' -d -f tree -o typescript.txt

# Tree view only for project structure
bin/gpt_context.rb -i '**/*' -e '**/node_modules/**/*' -e '.git/**/*' -f tree -d

# Line-limited content gathering
bin/gpt_context.rb -i '**/*.rb' -l 20 -f content -d

# Multiple output targets
bin/gpt_context.rb -i 'docs/**/*' -f tree,content -o clipboard -o docs-context.txt
```

See detailed usage guide: [docs/usage/gpt-context.md](./docs/usage/gpt-context.md)

#### 2. YouTube Manager (`bin/youtube_manager.rb`)
Manage YouTube video metadata via YouTube API:

```bash
# Get video details
bin/youtube_manager.rb get --video-id VIDEO_ID

# Update video metadata
bin/youtube_manager.rb update --video-id ID --title "New Title"
bin/youtube_manager.rb update --video-id ID --description "New Description"
bin/youtube_manager.rb update --video-id ID --tags "tag1,tag2,tag3"
bin/youtube_manager.rb update --video-id ID --category-id 28
```

**Features:**
- YouTube API authorization and authentication
- Retrieve video details, captions, and metadata
- Update video title, description, tags, and category
- Generate detailed reports

#### 3. Subtitle Processor (`bin/subtitle_processor.rb`)
Process and manage SRT subtitle files:

```bash
# Clean and normalize SRT files
bin/subtitle_processor.rb clean -f input.srt -o cleaned.srt

# Join multiple SRT files
bin/subtitle_processor.rb join -d ./subtitles -f "*.srt" -o merged.srt
bin/subtitle_processor.rb join -f "part1.srt,part2.srt" -s asc -b 100 -o final.srt

# Join with options
bin/subtitle_processor.rb join -d ./subs -f "*.srt" -s inferred -b 200 -o output.srt -L detail
```

**Operations:**
- **clean**: Removes HTML tags (`<u>`), merges duplicate entries, normalizes spacing
- **join**: Parses multiple SRT files, adjusts timestamps with buffer, merges timeline

**Options:**
- `-d, --directory` - Directory containing SRT files
- `-f, --files` - File pattern or comma-separated list
- `-s, --sort` - Sort order: asc, desc, or inferred (default)
- `-b, --buffer` - Buffer between files in milliseconds (default: 100)
- `-L, --log-level` - Log level: none, info, detail

**Use cases:** Cleaning YouTube auto-captions, merging FliVideo multi-part recording subtitles

**Note:** Renamed from `subtitle_manager` to `subtitle_processor` (accurate - processes files, doesn't manage state)

#### 4. DAM - Digital Asset Management (`bin/dam`)
Multi-tenant video project storage orchestration:

```bash
# List all brands
vat list

# List projects for a brand
vat list appydave
vat list appydave 'b6*'  # Pattern matching

# Upload to S3 (collaboration)
vat s3-up appydave b65
vat s3-up voz boy-baker --dry-run

# Download from S3
vat s3-down appydave b65
vat s3-down --dry-run  # Auto-detect from PWD

# Check sync status
vat s3-status appydave b65

# Clean up S3
vat s3-cleanup appydave b65 --force

# Archive to SSD
vat archive appydave b63

# Sync from SSD
vat sync-ssd appydave
```

**Core Features:**
- **Multi-tenant**: Manages 6 brands (appydave, voz, aitldr, kiros, joy, ss)
- **Smart sync**: MD5-based file comparison (skips unchanged files)
- **Pattern matching**: `'b6*'` expands to b60-b69 projects
- **Short names**: `b65` → `b65-guy-monroe-marketing-plan` (FliVideo pattern)
- **Auto-detection**: Detects brand/project from current directory
- **Hybrid storage**: Local → S3 (90-day collaboration) → SSD (archive)

**Brand Shortcuts:**
- `appydave` → `v-appydave`
- `voz` → `v-voz`
- `aitldr` → `v-aitldr`
- `kiros` → `v-kiros`
- `joy` → `v-beauty-and-joy`
- `ss` → `v-supportsignal`

**Workflows:**
- **FliVideo** (AppyDave): Sequential chapter recording, short name support (`b65`)
- **Storyline** (VOZ, AITLDR): Script-first content, full project names (`boy-baker`)

**Use cases:**
- Collaborate on video edits with team (upload → edit → download)
- Archive completed projects to external SSD
- Quick project discovery across multiple brands
- Manage 50GB+ video files with smart sync

**Configuration:**
- System: `video-projects-root` in `~/.config/appydave/settings.json` (**required**)
- Per-brand: `.video-tools.env` (AWS credentials, S3 bucket, SSD path)

**Migration note:** The old `~/.vat-config` file is deprecated. DAM now uses `settings.json`. See [Configuration Management](#configuration-management) section below.

See detailed usage guide: [docs/usage/vat.md](./docs/usage/vat.md)

#### 5. Prompt Tools (`bin/prompt_tools.rb`) ⚠️ DEPRECATED API
OpenAI Completion API wrapper with template support:

```bash
# Run prompt from text
bin/prompt_tools.rb completion -p "Your prompt" -o output.txt

# Run prompt from file with placeholders
bin/prompt_tools.rb completion -f template.md -k key1=value1,key2=value2 -c
```

**What it does:**
- Sends prompts to OpenAI **Completion API** (older GPT-3 models like `davinci-codex`)
- Supports template files with `{placeholder}` substitution
- Outputs to file, clipboard, or stdout

**Status:** ⚠️ **Not in active use** - Uses **deprecated OpenAI Completion API**

**Modern alternative:** Use ChatGPT/Claude directly or migrate to OpenAI Chat API

**Potential use cases:** Template-based content generation (if migrated to Chat API)

#### 5. YouTube Automation (`bin/youtube_automation.rb`) ⚠️ INTERNAL USE
Prompt sequence runner for content workflows:

```bash
# Run automation sequence
bin/youtube_automation.rb -s 01-1
bin/youtube_automation.rb -s 01-1 -d  # with debug output
```

**What it does:**
- Loads sequence config from `~/.config/appydave/youtube_automation.json`
- Reads prompt templates from Dropbox path (`_common/raw_prompts/`)
- Executes OpenAI Completion API calls
- Saves responses to output files

**Requirements:**
- Sequence definitions in JSON config
- Prompt template files in configured Dropbox location
- `OPENAI_ACCESS_TOKEN` environment variable

**Status:** ⚠️ **Internal tool** - Hardcoded paths, deprecated API, not documented for external use

**Relationship to Move Images:** These are separate tools - Move Images organizes downloaded images into video asset folders

**Options:**
- `-s, --sequence` - Sequence number (required, e.g., 01-1)
- `-d, --debug` - Enable debug mode

#### 6. Configuration Tool (`bin/configuration.rb`)
Manage appydave-tools configuration files:

```bash
# List all configurations
bin/configuration.rb -l

# Print specific configuration keys
bin/configuration.rb -p settings,channels

# Create missing configuration files
bin/configuration.rb -c

# Edit configurations in VS Code
bin/configuration.rb -e
```

**Configuration Types:**
- **settings** - General settings and paths (project folders: content, video, published, abandoned)
- **channels** - YouTube channel definitions (code, name, youtube_handle)
- **youtube_automation** - Automation workflow configurations (prompt sequences)

**Team Collaboration Features:**
- **Shareable configs**: JSON files can be version-controlled (no secrets included)
- **Per-developer paths**: Each team member customizes paths in their `~/.config/appydave/`
- **Consistent structure**: Same channel codes/names across team
- **Secrets separation**: API keys stored in `.env` files (gitignored), not in configs

#### 7. Move Images (`bin/move_images.rb`)
Organize and rename downloaded images into video project asset folders.

**Purpose:** Batch move and rename images from a download folder into organized video project asset directories with proper naming conventions.

```bash
# Move images to video project assets folder
bin/move_images.rb -f <project-folder> <section> <prefix>

# Example: Move images for intro section of project b40
bin/move_images.rb -f b40 intro b40
# Result: Creates files like b40-intro-1.jpg, b40-intro-2.jpg in /path/to/b40/assets/intro/

# Example: Move thumbnail images
bin/move_images.rb -f b40 thumb b40
# Result: Creates files like b40-thumb-1.jpg, b40-thumb-2.jpg in /path/to/b40/assets/thumb/
```

**Configuration:**
- **Source:** `~/Sync/smart-downloads/download-images/` (downloads folder)
- **Destination:** `/Volumes/Expansion/Sync/tube-channels/video-projects/<folder>/assets/<section>/`
- **Supported sections:** intro, outro, content, teaser, thumb (or any custom section name)
- **File format:** Processes `.jpg` files only

**Arguments:**
- `-f, --folder` - Project folder name (e.g., b40, b41, etc.)
- `<section>` - Asset section name (intro, outro, content, teaser, thumb)
- `<prefix>` - Filename prefix (typically matches project folder)

**Workflow:**
1. Download images to smart-downloads folder
2. Run move_images with project folder, section, and prefix
3. Images are renamed sequentially and moved to organized asset directory
4. Automatically creates section subdirectory if it doesn't exist

**Note:** This is a development/workflow tool specific to video project organization. Not installed as a gem command.

#### 8. Bank Reconciliation (`bin/bank_reconciliation.rb`) 🗄️ DEPRECATED
Bank transaction reconciliation tool - **DEPRECATED, DO NOT USE**

**WARNING:** This tool contains deprecated code and should not be used for new work. Code has been moved to `lib/appydave/tools/deprecated/bank_reconciliation/`

### Git Workflow with Semantic Versioning

**⚠️ IMPORTANT: Always use `kfeat` or `kfix` for commits**

This project uses automated semantic versioning with CI/CD integration. **DO NOT use manual `git commit` commands.**

**Commands:**
```bash
kfeat "Your feature description"   # Creates commit → CI runs → Minor version bump (0.14.0 → 0.15.0) → git pull
kfix "Your bug fix description"    # Creates commit → CI runs → Patch version bump (0.14.0 → 0.14.1) → git pull
```

**How it works:**
1. **You run:** `kfeat "add DAM migration"` or `kfix "resolve case-sensitivity bug"`
2. **Creates commit** with semantic commit message format
3. **Waits for CI** to complete (runs tests, linting, builds gem)
4. **Version update** happens automatically on GitHub via semantic-release:
   - `kfeat` → Minor version bump (new feature)
   - `kfix` → Patch version bump (bug fix)
5. **Auto git pull** after CI completes (repo was updated remotely)

**Why use these commands:**
- Ensures proper semantic versioning
- Waits for CI to validate changes
- Automatically syncs version updates from GitHub
- Prevents version conflicts

**Commit Message Guidelines:**
- Be descriptive but concise (1-2 sentences)
- Focus on the "why" rather than the "what"
- Use imperative mood ("add feature" not "added feature")
- Examples:
  - `kfeat "migrate VAT to DAM with full rename"`
  - `kfix "resolve case-insensitive brand resolution"`

**Note:** For breaking changes that require major version bump, see Gem Version Management section below.

### Testing & Quality
```bash
rake spec           # Run all RSpec tests
rake                # Default task: compile, spec (clobber compile spec)
RUBYOPT="-W0" guard # Watch files and auto-run tests + rubocop (suppress Ruby 3.4 warnings)
bundle exec rspec -f doc  # Run tests with detailed documentation format
```

**Note:** Ruby 3.4.2 shows platform constant warnings from Bundler. Use `RUBYOPT="-W0"` to suppress them.

### Linting & Style
```bash
rubocop             # Run RubyGem style checks
bundle exec rubocop --format clang  # Run with clang format (as used in Guard)
```

### Build & Release
```bash
rake build          # Build the gem
rake publish        # Build and publish gem to RubyGems.org
rake clean          # Remove built *.gem files
gem build           # Build gemspec into .gem file
```

## Architecture Overview

`appydave-tools` is AppyDave's consolidated productivity toolkit for YouTube content creation. Single-purpose utilities in one repository for easier maintenance than separate codebases.

**Philosophy:** See [docs/purpose-and-philosophy.md](./docs/purpose-and-philosophy.md) for project philosophy and design principles.

**Tool Categories:**
- AI & Context Management (GPT Context, Prompt Tools)
- Content & Media (Subtitles, YouTube Manager, YouTube Automation, Move Images)
- Configuration (Multi-channel config management)

### Core Structure
- **CLI Tools**: Multiple executable scripts in `bin/` for different functionalities
- **Modular Design**: Organized into focused modules under `lib/appydave/tools/`
- **Independent Operation**: Each tool solves a specific problem standalone
- **Configuration System**: Flexible config management for multi-project workflows
- **Type System**: Custom type classes for data validation and transformation

### Key Components

#### CLI Actions (`lib/appydave/tools/cli_actions/`)
- Base action pattern for command-line operations
- YouTube video management (get, update)
- AI prompt completion workflows

#### Configuration (`lib/appydave/tools/configuration/`)
- Multi-channel YouTube setup support
- Project folder management (content, video, published, abandoned)
- OpenAI integration configuration
- Channel-specific settings (code, name, youtube_handle)

#### GPT Context (`lib/appydave/tools/gpt_context/`)
- File collection for AI context gathering
- Content filtering and organization
- Output handling for various formats

#### YouTube Management (`lib/appydave/tools/youtube_manager/`)
- YouTube API authorization and authentication
- Video metadata retrieval and updates
- Caption/subtitle management
- Detailed reporting capabilities

#### Subtitle Management (`lib/appydave/tools/subtitle_processor/`)
- SRT file cleaning and normalization
- Multi-part subtitle joining
- Timeline synchronization

### Type System (`lib/appydave/tools/types/`)
- `BaseModel`: Foundation for data models with validation
- `ArrayType` & `HashType`: Collection type wrappers
- `IndifferentAccessHash`: Symbol/string key flexibility

## Development Conventions

### Ruby Style
- All Ruby files must start with `# frozen_string_literal: true`
- Follow existing code patterns and naming conventions
- Use the Guard setup for continuous testing during development

### Testing
- RSpec for all testing
- No `require` statements needed in spec files (handled by spec_helper)
- VCR for HTTP request mocking (YouTube API calls)
- SimpleCov for coverage reporting

### File Organization
- CLI executables in `bin/`
- Core library code in `lib/appydave/tools/`
- Tests mirror lib structure in `spec/`
- Configuration examples and docs in respective `_doc.md` files

## Key Dependencies
- `google-api-client`: YouTube API integration
- `ruby-openai`: OpenAI GPT integration  
- `activemodel`: Data validation and modeling
- `clipboard`: System clipboard operations
- `dotenv`: Environment variable management

## Configuration Management

### Configuration Overview
The gem uses JSON configuration files for managing YouTube channels, settings, and automation workflows. All configuration files are stored in `~/.config/appydave/`.

**Configuration Tool:** `bin/configuration.rb` (installed as `ad_config`)

**Complete configuration guide:** [docs/configuration/README.md](./docs/configuration/README.md)

### Quick Start

**First-time setup:**
```bash
# Create empty configuration files (safe - won't overwrite existing files)
bin/configuration.rb -c

# Copy example files
cp docs/configuration/settings.example.json ~/.config/appydave/settings.json
cp docs/configuration/channels.example.json ~/.config/appydave/channels.json
cp docs/configuration/.env.example .env

# Edit your values
bin/configuration.rb -e
```

### Configuration Commands

```bash
# List all configurations
bin/configuration.rb -l

# Create missing configuration files (safe - won't overwrite)
bin/configuration.rb -c

# View configuration values
bin/configuration.rb -p settings,channels,youtube_automation

# Edit configurations in VS Code
bin/configuration.rb -e
```

### Configuration Types

#### 1. Settings Config (`~/.config/appydave/settings.json`)
General application settings and paths (non-secret configuration).

**Structure:**
```json
{
  "video-projects-root": "/Users/yourname/dev/video-projects",
  "ecamm-recording-folder": "/Users/yourname/ecamm",
  "download-folder": "/Users/yourname/Downloads",
  "download-image-folder": "/Users/yourname/Downloads/images"
}
```

**Key Settings:**

| Key | Purpose | Used By | Required |
|-----|---------|---------|----------|
| `video-projects-root` | Root directory for all video projects | DAM commands | ✅ For DAM |
| `ecamm-recording-folder` | Where Ecamm Live saves recordings | Move Images | Optional |
| `download-folder` | General downloads directory | Move Images | Optional |
| `download-image-folder` | Image downloads (defaults to `download-folder`) | Move Images | Optional |

**Safe to:**
- ✅ Version control (after removing personal paths)
- ✅ Share with team (as template)
- ✅ Commit to git (as `.example` file)

#### 2. Channels Config (`~/.config/appydave/channels.json`)
YouTube channel definitions for multi-channel management.

**Structure:**
```json
{
  "channels": {
    "appydave": {
      "code": "ad",
      "name": "AppyDave",
      "youtube_handle": "@appydave",
      "locations": {
        "content_projects": "/path/to/content",
        "video_projects": "/Users/yourname/dev/video-projects/v-appydave",
        "published_projects": "/path/to/published",
        "abandoned_projects": "/path/to/abandoned"
      }
    }
  }
}
```

**Channel Properties:**

| Property | Description | Example |
|----------|-------------|---------|
| `key` | Internal identifier (object key) | `"appydave"` |
| `code` | Short code for project naming | `"ad"` |
| `name` | Display name | `"AppyDave"` |
| `youtube_handle` | YouTube @ handle | `"@appydave"` |

**Location Properties:**

| Location | Purpose | Can Use "NOT-SET" |
|----------|---------|-------------------|
| `content_projects` | Content planning/scripts | ✅ Yes |
| `video_projects` | Active video projects | ❌ No (required) |
| `published_projects` | Published video archives | ✅ Yes |
| `abandoned_projects` | Abandoned projects | ✅ Yes |

Use `"NOT-SET"` as a placeholder for unconfigured locations.

**Safe to:**
- ✅ Version control structure (remove personal paths first)
- ⚠️ Each developer customizes paths locally
- ✅ Share channel definitions (codes, names, handles)

#### 3. YouTube Automation Config (`~/.config/appydave/youtube_automation.json`)
Automation workflow configurations and sequences (internal use).

#### 4. Environment Variables (`.env` file - project root)
**⚠️ CRITICAL: Secrets and API keys stored here, NEVER commit to version control!**

```bash
# OpenAI API Configuration (required for prompt_tools and youtube_automation)
# Get your API key from: https://platform.openai.com/api-keys
OPENAI_ACCESS_TOKEN=sk-your-actual-api-key-here
OPENAI_ORGANIZATION_ID=org-your-actual-org-id

# Enable OpenAI tools (set to 'true' to enable)
TOOLS_ENABLED=false
```

**Environment Variables:**

| Variable | Purpose | Required For | Secret? |
|----------|---------|--------------|---------|
| `OPENAI_ACCESS_TOKEN` | OpenAI API key | prompt_tools, youtube_automation | ✅ SECRET |
| `OPENAI_ORGANIZATION_ID` | OpenAI org ID | prompt_tools, youtube_automation | ✅ SECRET |
| `TOOLS_ENABLED` | Enable OpenAI configuration | Optional | ❌ No |

**Safe to:**
- ❌ **NEVER** version control
- ❌ **NEVER** share
- ❌ **NEVER** commit to git
- ✅ Keep local only
- ✅ Share `.env.example` template

### Safety Features

**Automatic Backups:**
- Every config save creates timestamped backup: `filename.backup.YYYYMMDD-HHMMSS`
- Backups stored alongside config files in `~/.config/appydave/`
- Restore from backup: `cp settings.json.backup.20251109-203015 settings.json`

**Safe Configuration Creation:**
- `ad_config -c` only creates missing files, never overwrites existing ones
- Prevents accidental data loss from running setup commands

**Secrets Separation:**
- API keys stored in `.env` files (gitignored), not in JSON configs
- Configuration files can be safely version-controlled (after removing personal paths)

### Migration from Legacy Config

**From `~/.vat-config` (DEPRECATED):**

The old `~/.vat-config` file is no longer used. DAM now uses `settings.json`.

**Migration steps:**
1. Check your old config: `cat ~/.vat-config`
2. Add value to settings.json: `ad_config -e`
3. Add: `"video-projects-root": "/your/path/from/vat/config"`
4. Test DAM still works: `dam list`
5. Delete old file: `rm ~/.vat-config`

**Note:** The `dam init` command is deprecated. Use `ad_config -c` instead.

## Git Hooks & Security

### Pre-commit Hooks
This repository uses custom git hooks located in `.githooks/` directory.

**Setup:**
```bash
git config core.hookspath .githooks
```

**Current pre-commit checks:**
- ✅ Detects debug code: `binding.pry`, `byebug`, `debugger`
- ✅ Warns about: `console.log`, `console.dir`
- ✅ Excludes specific files: Gemfile, .json, .yml files
- ❌ **Does NOT check for secrets/API keys** (see Security Notes below)

**Force commit (bypass hooks):**
```bash
git commit --no-verify -m "message"
```

### Security Notes

**⚠️ IMPORTANT SECURITY CONSIDERATIONS:**

1. **No Secret Scanning:** The current pre-commit hook does NOT scan for:
   - API keys (OpenAI, Google, AWS, etc.)
   - OAuth tokens or credentials
   - Private keys or certificates
   - Credit card numbers or financial data
   - Email addresses or phone numbers

2. **Manual Vigilance Required:** Always review your commits for sensitive data before pushing.

3. **Recommended Secret Scanning Tools:**

#### Option 1: Gitleaks (Recommended for Ruby/Go projects)

**Installation (macOS):**
```bash
brew install gitleaks
```

**Setup as pre-commit hook:**
```bash
# Create .gitleaks.toml configuration
cat > .gitleaks.toml << 'EOF'
title = "Gitleaks Configuration"

[extend]
useDefault = true

[[rules]]
description = "AWS Access Key"
id = "aws-access-key"
regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''

[[rules]]
description = "OpenAI API Key"
id = "openai-api-key"
regex = '''sk-[a-zA-Z0-9]{48}'''

[[rules]]
description = "Google OAuth"
id = "google-oauth"
regex = '''[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com'''

[[rules]]
description = "Credit Card Numbers"
id = "credit-card"
regex = '''\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})\b'''

[allowlist]
paths = [
  '''\.md$''',
  '''^\.releaserc\.json$''',
  '''CHANGELOG\.md'''
]
EOF

# Add to pre-commit hook (append to existing .githooks/pre-commit)
# Add after line 89 (before final 'end'):
echo "
# Gitleaks secret scanning
echo 'Running gitleaks scan...'
gitleaks protect --staged --verbose
if [ \$? -ne 0 ]; then
  echo 'ERROR: Gitleaks found secrets in staged files'
  echo 'Use --no-verify to bypass (NOT RECOMMENDED)'
  exit 1
fi
" >> .githooks/pre-commit
```

**Manual scan:**
```bash
# Scan staged files
gitleaks protect --staged

# Scan entire repository
gitleaks detect

# Scan git history
gitleaks detect --verbose --log-opts="--all"
```

#### Option 2: git-secrets (AWS-focused)

**Installation (macOS):**
```bash
brew install git-secrets
```

**Setup:**
```bash
# Initialize git-secrets in repository
git secrets --install
git secrets --register-aws

# Add custom patterns
git secrets --add 'sk-[a-zA-Z0-9]{48}'  # OpenAI
git secrets --add '[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com'  # Google OAuth
```

#### Option 3: truffleHog (Deep history scanning)

**Installation:**
```bash
brew install trufflehog
```

**Usage:**
```bash
# Scan entire git history
trufflehog git file://. --json

# Scan from remote
trufflehog git https://github.com/user/repo
```

4. **`.gitignore` Critical Files:**
```gitignore
.env
.env.*
*.key
*.pem
credentials.json
client_secret*.json
**/bank_reconciliation/**/*.csv
```

### Gem Version Management

**Current Published Version:** `0.14.1` (on RubyGems.org)

**IMPORTANT: Automated Versioning System**

This project uses **semantic-release** for automated versioning and publishing. **DO NOT manually edit version files.**

**How it works:**
1. Commits are analyzed using conventional commit messages (feat, fix, chore, docs, etc.)
2. GitHub Actions CI/CD automatically:
   - Determines next version based on commit types
   - Updates `lib/appydave/tools/version.rb`
   - Updates `CHANGELOG.md`
   - Builds and publishes gem to RubyGems.org
   - Creates git tag
   - Pushes changes back to repository

**Commit Message Format:**
```bash
feat: add new feature      # Triggers minor version bump (0.14.0 → 0.15.0)
fix: fix bug              # Triggers patch version bump (0.14.0 → 0.14.1)
chore: update dependencies # No version bump
docs: update readme       # No version bump

# Breaking change (major version bump)
feat!: remove deprecated API
BREAKING CHANGE: removes old API

# Or with body
feat: new feature

BREAKING CHANGE: This breaks existing API
```

**Configuration:**
- **CI/CD:** `.github/workflows/main.yml`
- **Semantic Release:** `.releaserc.json`
- **Plugins:**
  - `@semantic-release/commit-analyzer` - Analyzes commits
  - `@semantic-release/release-notes-generator` - Generates changelog
  - `@klueless-js/semantic-release-rubygem` - Publishes to RubyGems
  - `@semantic-release/git` - Commits version bumps
  - `@semantic-release/github` - Creates GitHub releases

**Manual Publishing (Emergency Only):**
If you absolutely must publish manually:
1. Update version in `lib/appydave/tools/version.rb`
2. Run tests: `rake spec`
3. Build gem: `rake build`
4. Publish: `rake publish`
5. Tag release: `git tag v0.14.1 && git push --tags`

**Note:** Manual publishing will break the automated workflow. Use conventional commits and let CI/CD handle releases.