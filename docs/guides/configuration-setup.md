# AppyDave Tools Configuration Guide

This guide explains how to configure AppyDave Tools for your environment.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Files](#configuration-files)
  - [settings.json](#settingsjson)
  - [channels.json](#channelsjson)
  - [.env](#env)
- [Configuration Commands](#configuration-commands)
- [Migration from Legacy Config](#migration-from-legacy-config)

---

## Quick Start

### 1. Create Default Configuration Files

```bash
ad_config -c
```

This creates empty configuration files at `~/.config/appydave/`:
- `settings.json` - Paths and preferences
- `channels.json` - YouTube channel definitions
- `youtube-automation.json` - Automation workflows

### 2. Option A: Copy Example Files

```bash
# Copy examples to your config directory
cp docs/configuration/settings.example.json ~/.config/appydave/settings.json
cp docs/configuration/channels.example.json ~/.config/appydave/channels.json

# Copy .env to project root
cp docs/configuration/.env.example .env
```

Then edit each file and replace placeholders with your actual values.

### 2. Option B: Edit Directly in VS Code

```bash
ad_config -e
```

Opens `~/.config/appydave/` in VS Code for editing.

### 3. Add Your Values

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

---

## Configuration Files

### `settings.json`

**Location:** `~/.config/appydave/settings.json`

**Purpose:** Stores paths and preferences (non-secret configuration)

**Example:**
```json
{
  "video-projects-root": "/Users/yourname/dev/video-projects",
  "ecamm-recording-folder": "/Users/yourname/ecamm",
  "download-folder": "/Users/yourname/Downloads",
  "download-image-folder": "/Users/yourname/Downloads/images"
}
```

**Settings Reference:**

| Key | Purpose | Used By | Required |
|-----|---------|---------|----------|
| `video-projects-root` | Root directory for all video projects | VAT commands | ✅ For VAT |
| `ecamm-recording-folder` | Where Ecamm Live saves recordings | Move Images | Optional |
| `download-folder` | General downloads directory | Move Images | Optional |
| `download-image-folder` | Image downloads (defaults to `download-folder`) | Move Images | Optional |

**Safe to:**
- ✅ Version control (after removing personal paths)
- ✅ Share with team (as template)
- ✅ Commit to git (as `.example` file)

---

### `channels.json`

**Location:** `~/.config/appydave/channels.json`

**Purpose:** Defines YouTube channels and their project locations

**Example:**
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

**Using "NOT-SET":**

If you don't have a location configured yet, use `"NOT-SET"` as a placeholder:

```json
"content_projects": "NOT-SET"
```

This makes it clear that the value needs to be configured later.

**Safe to:**
- ✅ Version control structure (remove personal paths first)
- ⚠️  Each developer customizes paths locally
- ✅ Share channel definitions (codes, names, handles)

---

### `.env`

**Location:** `.env` (project root directory)

**Purpose:** Stores secrets and API keys

**⚠️ CRITICAL: This file is gitignored and should NEVER be committed!**

**Example:**
```bash
# OpenAI API Configuration
OPENAI_ACCESS_TOKEN=sk-your-actual-api-key-here
OPENAI_ORGANIZATION_ID=org-your-actual-org-id

# Optional: Enable OpenAI tools
TOOLS_ENABLED=true
```

**Environment Variables:**

| Variable | Purpose | Required For | Secret? |
|----------|---------|--------------|---------|
| `OPENAI_ACCESS_TOKEN` | OpenAI API key | prompt_tools, youtube_automation | ✅ SECRET |
| `OPENAI_ORGANIZATION_ID` | OpenAI org ID | prompt_tools, youtube_automation | ✅ SECRET |
| `TOOLS_ENABLED` | Enable OpenAI configuration | Optional | ❌ No |

**Getting API Keys:**
- OpenAI: https://platform.openai.com/api-keys

**Safe to:**
- ❌ NEVER version control
- ❌ NEVER share
- ❌ NEVER commit to git
- ✅ Keep local only
- ✅ Share `.env.example` template

---

## Configuration Commands

### List All Configurations

```bash
ad_config -l
```

Shows which configuration files exist and their paths.

**Example Output:**
```
NAME               | EXISTS | PATH
-------------------|--------|------------------------------------------------------------
settings           | true   | /Users/yourname/.config/appydave/settings.json
channels           | true   | /Users/yourname/.config/appydave/channels.json
youtube_automation | true   | /Users/yourname/.config/appydave/youtube-automation.json
```

### Create Missing Configurations

```bash
ad_config -c
```

Creates any configuration files that don't exist yet.

**Safety:** This command will NOT overwrite existing files. It only creates missing ones.

### Print Configuration Values

```bash
# Print all configurations
ad_config -p

# Print specific configurations
ad_config -p settings
ad_config -p channels
ad_config -p settings,channels
```

Shows the current values in your configuration files.

### Edit in VS Code

```bash
ad_config -e
```

Opens the configuration directory (`~/.config/appydave/`) in Visual Studio Code.

---

## Migration from Legacy Config

### From `~/.vat-config` (Deprecated)

If you have an old `~/.vat-config` file, migrate to `settings.json`:

**Old format** (`~/.vat-config`):
```
VIDEO_PROJECTS_ROOT=/Users/yourname/dev/video-projects
```

**New format** (`~/.config/appydave/settings.json`):
```json
{
  "video-projects-root": "/Users/yourname/dev/video-projects"
}
```

**Migration steps:**

1. Check your current VAT config:
   ```bash
   cat ~/.vat-config
   ```

2. Add the value to settings.json:
   ```bash
   ad_config -e
   ```

3. In `settings.json`, add:
   ```json
   "video-projects-root": "/your/path/from/vat/config"
   ```

4. Test that VAT still works:
   ```bash
   vat list
   ```

5. Delete the old file:
   ```bash
   rm ~/.vat-config
   ```

**Note:** The `vat init` command is deprecated. Use `ad_config` instead.

---

## Backup & Recovery

### Automatic Backups

Every time you save a configuration, a timestamped backup is created automatically:

```
~/.config/appydave/settings.json.backup.20251109-203015
```

**Backup format:** `filename.backup.YYYYMMDD-HHMMSS`

### Restoring from Backup

```bash
# List available backups
ls -la ~/.config/appydave/*.backup.*

# Restore from backup
cp ~/.config/appydave/settings.json.backup.20251109-203015 \
   ~/.config/appydave/settings.json
```

---

## Troubleshooting

### "VIDEO_PROJECTS_ROOT not configured" Error

**Problem:** VAT commands fail with configuration error.

**Solution:**
```bash
ad_config -e
```

Add to `settings.json`:
```json
{
  "video-projects-root": "/path/to/your/video-projects"
}
```

### Configuration Files Missing

**Problem:** Configuration files don't exist.

**Solution:**
```bash
ad_config -c
```

This creates default empty configuration files.

### OpenAI API Errors

**Problem:** "OpenAI API key not configured"

**Solution:**

1. Create `.env` file in project root:
   ```bash
   cp docs/configuration/.env.example .env
   ```

2. Add your API key:
   ```bash
   OPENAI_ACCESS_TOKEN=sk-your-actual-key
   OPENAI_ORGANIZATION_ID=org-your-org-id
   TOOLS_ENABLED=true
   ```

3. Never commit `.env` to git (it's gitignored by default)

---

## Best Practices

1. **Use `ad_config -c` for initialization** - It's safe and won't overwrite existing files
2. **Use "NOT-SET" for unconfigured paths** - Makes it clear what needs to be set
3. **Keep secrets in `.env`** - Never put API keys in `settings.json`
4. **Backup before major changes** - Automatic backups are created, but you can manually backup too
5. **Use `ad_config -p` to verify** - Check your configuration values are correct
6. **Share examples, not actual configs** - Use `.example` files for team sharing

---

## Need Help?

- Check CLAUDE.md for project-specific configuration
- Run `ad_config --help` for command options
- See example files in `docs/configuration/`
