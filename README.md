# AppyDave Tools

> **AppyDave's YouTube productivity toolkit** - Command-line utilities that automate the boring stuff so you can focus on creating content.

## Why This Exists

As a YouTuber, I got tired of repetitive tasks eating into my creative time. So I built tools to handle them.

Instead of managing dozens of separate repositories, everything lives here - one codebase, easier maintenance, and each tool can be featured in its own video tutorial.

**Quick wins:**
- 🤖 Feed entire codebases to AI assistants in seconds
- 📹 Batch update YouTube video metadata without clicking through the UI (update 50 videos in 5 minutes)
- 📝 Process subtitle files - clean formatting, merge multi-part recordings, synchronize timelines
- 🎬 Manage video projects across local/S3/SSD storage with smart sync (collaborate on 50GB+ projects)
- 🖼️ Organize downloaded images into project folders automatically (video asset workflow)
- ⚙️ Manage multi-channel configurations from the command line (team-shareable JSON configs)

## Installation

```bash
gem install appydave-tools
```

Or add to your Gemfile:

```ruby
gem 'appydave-tools'
```

## Quick Start: Configuration

Most tools work out of the box, but some features (VAT, YouTube Manager, OpenAI tools) require configuration.

### First-Time Setup

**1. Create configuration files:**

```bash
ad_config -c
```

This creates empty configuration files at `~/.config/appydave/`:
- `settings.json` - Paths and preferences
- `channels.json` - YouTube channel definitions
- `youtube-automation.json` - Automation workflows

**2. Option A: Copy example files**

```bash
# Copy examples to your config directory
cp docs/configuration/settings.example.json ~/.config/appydave/settings.json
cp docs/configuration/channels.example.json ~/.config/appydave/channels.json

# Copy .env to project root (for API keys)
cp docs/configuration/.env.example .env
```

Then edit each file and replace placeholders with your actual values.

**2. Option B: Edit directly in VS Code**

```bash
ad_config -e
```

Opens `~/.config/appydave/` for editing.

**3. Add your values**

Update the configuration files with your specific paths and settings.

**Required for VAT (Video Asset Tools):**
```json
{
  "video-projects-root": "/path/to/your/video-projects"
}
```

**Required for OpenAI tools:**
```bash
OPENAI_ACCESS_TOKEN=sk-your-actual-api-key
```

**Full configuration guide:** [docs/configuration/README.md](./docs/configuration/README.md)

## The Tools

### 🤖 GPT Context Gatherer

**The problem:** AI assistants need context about your code, but copying files is tedious.

**The solution:** Automatically collect and format project files for AI context.

```bash
# Gather all Ruby files, skip tests, save to clipboard
gpt_context -i '**/*.rb' -e 'spec/**/*' -d

# Get project structure as a tree
gpt_context -i '**/*' -f tree -d

# Multiple file types with custom output
gpt_context -i 'apps/**/*.ts' -i 'apps/**/*.tsx' -e '**/node_modules/**/*' -o context.txt
```

**Use cases:** Working with ChatGPT, Claude, or any AI assistant on your codebase.

[Full documentation →](./docs/usage/gpt-context.md)

---

### 📹 YouTube Manager

**The problem:** Updating video metadata through YouTube Studio is slow and repetitive, especially for bulk operations.

**The solution:** Manage YouTube video metadata via API from your terminal - CRUD operations on videos.

```bash
# Get video details (title, description, tags, category, captions)
youtube_manager get --video-id YOUR_VIDEO_ID

# Update title and description
youtube_manager update --video-id YOUR_VIDEO_ID \
  --title "New Title" \
  --description "Updated description"

# Update tags (replaces existing tags)
youtube_manager update --video-id YOUR_VIDEO_ID --tags "tutorial,productivity,automation"

# Update category
youtube_manager update --video-id YOUR_VIDEO_ID --category-id 28
```

**Specific use cases:**
- **Post-rebrand updates**: Changed channel name? Update 50 video descriptions in minutes
- **Tag standardization**: Ensure consistent tagging across your entire catalog
- **Metadata retrieval**: Export video details for analysis or backup
- **Batch corrections**: Fix typos in titles across multiple videos
- **Category changes**: Recategorize videos when YouTube updates categories
- **Series updates**: Add series links to descriptions across episode batches

**What it does:**
- **Get**: Retrieves complete video metadata including captions
- **Update**: Modifies title, description, tags, or category via YouTube Data API v3
- **Authorization**: Handles OAuth2 flow with local callback server
- **Reporting**: Generates detailed reports of video metadata

**Why use this vs YouTube Studio:**
- **Speed**: Update 20 videos in 5 minutes vs 30+ minutes clicking through UI
- **Scriptable**: Integrate into automation workflows
- **Bulk operations**: Loop through video IDs from a CSV
- **Version control**: Track metadata changes in Git
- **Backup**: Export all video metadata as JSON

---

### 📝 Subtitle Processor

**The problem:** Raw subtitle files need cleanup, and multi-part recordings need merged subtitles.

**The solution:** Process and transform SRT files - clean formatting, merge duplicates, synchronize timelines.

```bash
# Clean auto-generated subtitles (removes HTML tags, merges duplicates, normalizes spacing)
subtitle_processor clean -f input.srt -o cleaned.srt

# Merge multiple subtitle files with timeline synchronization
subtitle_processor join -d ./parts -f "*.srt" -o final.srt

# Custom time buffer between merged sections (in milliseconds)
subtitle_processor join -f "part1.srt,part2.srt" -b 200 -o merged.srt
```

**What it does:**
- **Clean**: Removes `<u>` tags, merges duplicate entries, normalizes line breaks and spacing
- **Join**: Parses multiple SRT files, adjusts timestamps with buffers, merges into single timeline

**Use cases:** Cleaning messy YouTube auto-captions, merging FliVideo multi-part recording subtitles.

**Note:** CLI command is `subtitle_processor` (renamed from `subtitle_manager` for accuracy - this tool *processes* files, not manages state).

---

### 🎬 VAT (Video Asset Tools)

**The problem:** Managing large video files across local storage, cloud collaboration (S3), and archival storage (SSD) is complex and error-prone.

**The solution:** Unified CLI for multi-tenant video project management with smart sync, pattern matching, and workflow automation.

```bash
# List all brands
vat list

# List projects for AppyDave brand
vat list appydave

# Upload files to S3 for collaboration
vat s3-up appydave b65

# Download collaborator's edits from S3
vat s3-down appydave b65

# Check sync status (shows all 4 states: synced, modified, S3 only, local only)
vat s3-status appydave b65

# Archive completed project to SSD
vat archive appydave b63

# Generate project manifest (tracks all projects across local + SSD)
vat manifest appydave

# Clean up S3 after project completion
vat s3-cleanup-remote appydave b65 --force

# Clean up local s3-staging directory
vat s3-cleanup-local appydave b65 --force
```

**Configuration required:** Add `video-projects-root` to `settings.json` (see [Quick Start](#quick-start-configuration) above).

**Key Features:**
- **Multi-tenant**: Manages 6 brands (appydave, voz, aitldr, kiros, joy, ss)
- **Smart sync**: MD5-based file comparison (skip unchanged files)
- **Pattern matching**: `vat list appydave 'b6*'` (lists b60-b69)
- **Short names**: `b65` → `b65-guy-monroe-marketing-plan` (FliVideo workflow)
- **Auto-detection**: Run commands from project directory without args
- **Hybrid storage**: Local → S3 (collaboration) → SSD (archive)

**Workflows:**
- **FliVideo** (AppyDave): Sequential chapter-based recording with short name support
- **Storyline** (VOZ, AITLDR): Script-first narrative content with full project names

**Use cases:**
- Collaborate on video edits with team members via S3
- Archive completed projects to external SSD
- Manage video assets across multiple brands/clients
- Quick project discovery with pattern matching

[Full documentation →](./docs/usage/vat.md)

---

### 🎯 Prompt Tools *(Experimental - Not actively used)*

**The problem:** Running OpenAI prompts with placeholder substitution and output management.

**The solution:** Execute OpenAI completion API calls with template support.

```bash
# Run prompt from text
prompt_tools completion -p "Your prompt here" -o output.txt

# Run prompt from file with placeholders
prompt_tools completion -f prompt_template.md -k topic=Ruby,style=tutorial -c

# Options:
# -p, --prompt     Inline prompt text
# -f, --file       Prompt template file
# -k, --placeholders  Key-value pairs for {placeholder} substitution
# -o, --output     Save to file
# -c, --clipboard  Copy to clipboard
# -m, --model      OpenAI model to use
```

**What it does:**
- Sends prompts to OpenAI Completion API (older GPT-3 models)
- Supports template files with `{placeholder}` substitution
- Outputs to file, clipboard, or stdout

**Current status:** ⚠️ **Not in active use** - Uses deprecated OpenAI Completion API (`davinci-codex`). Modern alternative: Use ChatGPT or Claude directly, or migrate to Chat API.

**Potential use cases:** Template-based content generation, automated prompt workflows (if migrated to Chat API).

---

### ⚡ YouTube Automation *(Internal/Experimental)*

**The problem:** Video content creation workflows involve multiple steps: research → scripting → production.

**The solution:** Run predefined prompt sequences against OpenAI API to automate research and content generation steps.

```bash
# Run automation sequence (requires configuration)
youtube_automation -s 01-1

# With debug output
youtube_automation -s 01-1 -d
```

**What it does:**
- Loads sequence configuration from `~/.config/appydave/youtube_automation.json`
- Reads prompt templates from Dropbox (`_common/raw_prompts/`)
- Executes OpenAI API calls for each sequence step
- Saves responses to output files

**Configuration required:**
- Sequence definitions in `youtube_automation.json`
- Prompt template files in configured Dropbox path
- `OPENAI_ACCESS_TOKEN` environment variable

**Current status:** ⚠️ **Internal tool** - Hardcoded Dropbox paths, uses deprecated Completion API, not documented for external use.

**Relationship to other tools:** This is separate from **Move Images** tool (which organizes downloaded images into video project asset folders).

**Use cases:** Automated content research, script outline generation, multi-step prompt workflows.

---

### ⚙️ Configuration Manager

**The problem:** Managing settings for multiple YouTube channels, project paths, and automation sequences gets messy.

**The solution:** Centralized JSON-based configuration stored in `~/.config/appydave/`.

```bash
# List all configurations
ad_config -l

# Create missing config files (safe - won't overwrite existing files)
ad_config -c

# Edit configurations in VS Code
ad_config -e

# View specific configuration values
ad_config -p settings,channels

# View all configurations
ad_config -p
```

**What it manages:**

| File | Purpose | Safe to Version Control? |
|------|---------|-------------------------|
| `settings.json` | Paths and preferences (video-projects-root, download folders, etc.) | ✅ Yes (after removing personal paths) |
| `channels.json` | YouTube channel definitions (code, name, youtube_handle, locations) | ✅ Yes (share structure, customize paths locally) |
| `youtube_automation.json` | Automation workflow configurations | ✅ Yes (if no sensitive data) |
| `.env` | **Secrets and API keys** | ❌ **NEVER** (gitignored) |

**Key Settings:**

- **video-projects-root** - Root directory for all video projects (required for VAT)
- **ecamm-recording-folder** - Where Ecamm Live saves recordings
- **download-folder** - General downloads directory
- **download-image-folder** - Image downloads (defaults to download-folder)

**Channel Configuration:**

Each channel defines:
- **code** - Short code for project naming (e.g., "ad" for AppyDave)
- **name** - Display name
- **youtube_handle** - YouTube @ handle
- **locations** - Four project location types:
  - `content_projects` - Content planning/scripts
  - `video_projects` - Active video projects (**required**)
  - `published_projects` - Published video archives
  - `abandoned_projects` - Abandoned projects

Use `"NOT-SET"` as a placeholder for unconfigured locations.

**Use cases:**
- **Multi-channel management**: Switch between different YouTube channels
- **Team collaboration**: Share configuration structure via Git (each developer customizes paths)
- **Workflow standardization**: Consistent channel codes/names across team
- **Automation setup**: Define reusable prompt sequences

**Safety Features:**
- **Automatic backups**: Every config save creates timestamped backup (`.backup.YYYYMMDD-HHMMSS`)
- **Safe creation**: `ad_config -c` only creates missing files, never overwrites existing ones
- **Secrets separation**: API keys stored in `.env` files (gitignored), not in configs

**Full configuration guide:** [docs/configuration/README.md](./docs/configuration/README.md)

---

### 🖼️ Move Images *(Development tool)*

**The problem:** Downloaded images need organizing with proper naming.

**The solution:** Batch move and rename to project folders.

```bash
# Organize intro images for video project
bin/move_images.rb -f b40 intro b40
# Result: b40-intro-1.jpg, b40-intro-2.jpg in assets/intro/
```

**Use cases:** B-roll organization, thumbnail preparation.

---

## Philosophy

**One codebase, multiple tools.** Easier to maintain than dozens of repos.

**Single-purpose utilities.** Each tool does one thing well.

**YouTube workflow focus.** Built for content creators who code.

**Language-agnostic.** Currently Ruby, but could be rewritten if needed.

[Read the full philosophy →](./docs/purpose-and-philosophy.md)

---

## Development

```bash
# Clone the repo
git clone https://github.com/appydave/appydave-tools

# Setup
bin/setup

# Run tests
rake spec

# Auto-run tests on file changes
guard

# Interactive console
bin/console
```

### Semantic Versioning

This project uses **automated versioning** via semantic-release. Don't manually edit version files.

**Commit message format:**
```bash
feat: add new feature    # Minor version bump
fix: bug fix            # Patch version bump
chore: maintenance      # No version bump

# Breaking changes
feat!: breaking change
```

CI/CD automatically handles versioning, changelog, and RubyGems publishing.

---

## Contributing

**Welcome:**
- 🐛 Bug fixes
- 📝 Documentation improvements
- ⚡ Performance enhancements
- 🎯 New single-purpose tools that fit the workflow

**Not looking for:**
- ❌ Framework-style architectures
- ❌ Tools that create dependencies between utilities
- ❌ Enterprise complexity

[Code of Conduct →](./CODE_OF_CONDUCT.md)

---

## License

MIT License - Copyright (c) David Cruwys

See [LICENSE.txt](LICENSE.txt) for details.

---

## Connect

- 🌐 Website: [appydave.com](http://appydave.com)
- 📺 YouTube: [@AppyDave](https://youtube.com/@appydave)
- 🐙 GitHub: [appydave](https://github.com/appydave)

Built with ☕ by [David Cruwys](https://davidcruwys.com)
