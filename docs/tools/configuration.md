# Configuration Manager

Set up and manage multi-channel YouTube, OpenAI, and workflow configurations with team-friendly file organization.

## What It Does

**Configuration Manager** centralizes setup for all appydave-tools:

- Manages multiple YouTube channel configurations
- Stores OpenAI API settings
- Organizes workflow definitions
- Supports per-developer configuration paths
- Keeps secrets separate from shared configs
- Enables team collaboration without exposing credentials

## How to Use

### Configuration Location

All configuration stored in:
```
~/.config/appydave/
├── channels.json           # YouTube channels (shared)
├── settings.json           # General settings (shared)
├── youtube_automation.json # Workflow definitions (shared)
├── tokens/                 # OAuth tokens (private, auto-created)
└── .env                    # Secrets (private, not in git)
```

### Interactive Setup

```bash
configuration create-channel

# Prompts for:
# - Channel name
# - YouTube channel ID
# - YouTube handle
# - Default folder structure
```

### Manual Configuration

Edit `~/.config/appydave/channels.json`:

```json
{
  "channels": [
    {
      "code": "appydave",
      "name": "AppyDave",
      "youtube_handle": "@appydave",
      "youtube_channel_id": "UC...",
      "folders": {
        "content": "/path/to/content",
        "video": "/path/to/videos",
        "published": "/path/to/published",
        "abandoned": "/path/to/abandoned"
      }
    },
    {
      "code": "aitldr",
      "name": "AITLDR",
      "youtube_handle": "@aitldr",
      "youtube_channel_id": "UC...",
      "folders": {...}
    }
  ]
}
```

### Environment Variables

Create `~/.config/appydave/.env` (DO NOT commit):

```bash
OPENAI_API_KEY=sk-...
YOUTUBE_API_KEY=AIz...  # If using API key auth instead of OAuth
```

### Folder Structure

Each channel uses this structure:

```
channel-folder/
├── content/          # Scripts, notes, outlines
├── video/           # Raw video files
├── published/       # Finished, uploaded videos
└── abandoned/       # Projects not finished
```

## Use Cases for AI Agents

### 1. Multi-Channel Management
```bash
# Get all configured channels
configuration list-channels

# AI discovers: How many channels, their names, folders
# Can orchestrate operations across multiple channels
```
**AI discovers**: Channel portfolio. Can coordinate operations across brands.

### 2. Team Collaboration Setup
```bash
# Configure team-friendly paths
# Shared channels.json (committed)
# Private .env (gitignored)
# Each developer has local config for their setup
```
**AI discovers**: Team structure, folder organization. Can ensure consistent setup.

### 3. Channel-Specific Workflows
```bash
# Different workflows per channel
# appydave: Full FliVideo workflow
# aitldr: Storyline app workflow
# configuration tells each tool which channel to use
```
**AI discovers**: Channel-specific requirements. Can apply correct workflows per channel.

### 4. Credential Management
```bash
# Separate shared config from secrets
# channels.json: In git, shared
# .env: Gitignored, private
# tokens/: Auto-created, gitignored
```
**AI discovers**: How to handle credentials safely. Can maintain security while enabling sharing.

### 5. Per-Developer Configuration
```bash
# Each developer might have:
# Different folder structure
# Different API keys
# Different test channels
# configuration supports all these variations
```
**AI discovers**: Developer flexibility needs. Can allow customization without conflicts.

### 6. Workflow Parameter Injection
```bash
# Configuration provides values to workflows
# Workflow: "upload to ${channel.youtube_channel_id}"
# Configuration replaces with actual channel ID
```
**AI discovers**: How configuration drives workflows. Can parameterize operations.

### 7. Setting Management
```bash
# Store tool-wide settings
settings.json:
{
  "default_channel": "appydave",
  "api_timeout": 30,
  "retry_attempts": 3,
  "log_level": "info"
}
```
**AI discovers**: Default behavior, tool preferences. Can respect user settings.

### 8. Audit Trail
```bash
# Who configured what when?
# Configuration changes are logged
# Can trace back setup decisions
configuration audit-log --since "2024-01-01"
```
**AI discovers**: Configuration history. Can understand how system evolved.

### 9. Migration & Backup
```bash
# Export configuration
configuration export > backup.json

# Restore on new machine
configuration import backup.json
```
**AI discovers**: Portability, disaster recovery. Can migrate configs safely.

### 10. Validation & Health Check
```bash
# Verify configuration is valid
configuration validate

# Check that all folders exist
configuration health-check

# Test API connections
configuration test-apis
```
**AI discovers**: Configuration correctness. Can identify setup issues early.

## Command Reference

### Channel Management
```bash
configuration create-channel          # Interactive setup wizard
configuration list-channels           # Show all configured channels
configuration get-channel [code]      # Get specific channel config
configuration update-channel [code]   # Modify channel
configuration delete-channel [code]   # Remove channel
```

### Settings Management
```bash
configuration set KEY VALUE           # Set a setting
configuration get KEY                 # Get a setting
configuration list-settings           # Show all settings
```

### Configuration Files
```bash
configuration init                    # Create default config
configuration show                    # Display current config
configuration show [file]             # Show specific file
configuration edit                    # Edit in default editor
configuration validate                # Check config validity
configuration health-check            # Verify folders exist
```

### Import/Export
```bash
configuration export [file]           # Export to JSON
configuration import [file]           # Import from JSON
configuration backup                  # Create backup
```

## Configuration Schema

### channels.json
```json
{
  "channels": [
    {
      "code": "string",                    // Unique identifier
      "name": "string",                    // Display name
      "youtube_handle": "string",          // @handle format
      "youtube_channel_id": "string",      // UC... format
      "folders": {
        "content": "string",               // Where scripts go
        "video": "string",                 // Where raw videos go
        "published": "string",             // Where finished videos go
        "abandoned": "string"              // Where unfinished go
      }
    }
  ]
}
```

### settings.json
```json
{
  "default_channel": "string",
  "api_timeout": "number",
  "retry_attempts": "number",
  "log_level": "string",
  "debug": "boolean"
}
```

### youtube_automation.json
```json
{
  "workflows": {
    "workflow_name": {
      "trigger": "manual|scheduled|event",
      "steps": [...],
      "on_error": "retry|skip|fail"
    }
  }
}
```

## Team Collaboration Pattern

### Recommended Setup

```
project/
├── .gitignore
├── config/
│   ├── channels.json      # Committed - shared channels
│   ├── settings.json      # Committed - shared settings
│   └── workflows.json     # Committed - shared workflows
└── .env                   # Gitignored - local secrets

~/.config/appydave/        # Local, not in repo
├── channels.json          # Link to project config OR local copy
├── .env                   # Local API keys (NEVER committed)
└── tokens/                # OAuth tokens (auto-created)
```

### Setup Steps for New Team Member

1. Clone repository
2. Link to shared config: `configuration link-config ../project/config/`
3. Create local `.env`: `cp .env.example .env && edit .env`
4. Verify setup: `configuration health-check`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Channel not found" | Check `channels.json`, verify channel code |
| "Folder doesn't exist" | Update paths in channels.json to actual folders |
| "API key not found" | Create `~/.config/appydave/.env` with `OPENAI_API_KEY=` |
| "Permission denied on folder" | Check folder permissions, add user to group if needed |
| "Token expired" | Delete `~/.config/appydave/tokens/` to re-authenticate |

## Tips & Tricks

1. **Use short channel codes**: `appydave` not `appydave-official`
2. **Keep folders in one parent**: Easier to back up, share
3. **Gitignore .env always**: Never commit secrets
4. **Test configuration**: Run `configuration health-check` after changes
5. **Document custom settings**: Add comments explaining non-obvious values
6. **Back up regularly**: Use `configuration backup` before major changes

---

**Related Tools**:
- All tools use configuration for setup
- `youtube_manager` - Uses channel.json
- `youtube_automation` - Uses workflows.json
- `gpt_context` - Can read config for project paths

**Security**: Never commit `.env` or tokens/ folder. Always gitignore credentials.
