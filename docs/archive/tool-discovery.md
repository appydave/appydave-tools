# AI Agent Tool Discovery Guide

**Purpose:** Help AI agents quickly identify the right tool for user requests

---

## Quick Task Reference

| User Says... | Use This Tool | Example Command |
|--------------|---------------|-----------------|
| "Feed my codebase to ChatGPT/Claude" | **GPT Context Gatherer** | `gpt_context -i '**/*.rb' -d` |
| "Clean messy YouTube auto-captions" | **Subtitle Processor** | `subtitle_processor clean -f input.srt` |
| "Merge subtitle files from multi-part recording" | **Subtitle Processor** | `subtitle_processor join -d ./parts` |
| "Update 50 video titles" | **YouTube Manager** | `youtube_manager update --video-id ID --title "New"` |
| "Get video metadata for backup" | **YouTube Manager** | `youtube_manager get --video-id ID` |
| "Organize downloaded images into video project" | **Move Images** | `bin/move_images.rb -f b40 intro b40` |
| "Setup tool configuration" | **Configuration** | `ad_config -c` |
| "Edit channel configurations" | **Configuration** | `ad_config -e` |

---

## Problem → Tool Mapping

### "I have subtitle problems"
- **One messy SRT file** → `subtitle_processor clean`
  - Removes HTML tags, merges duplicates, normalizes spacing
- **Multiple SRT files to merge** → `subtitle_processor join`
  - Adjusts timestamps, synchronizes timeline, handles buffers
- **Upload/download YouTube captions** → `youtube_manager` (not subtitle_processor)

### "I need to work with YouTube videos"
- **Metadata operations (CRUD)** → `youtube_manager`
  - Get, update title/description/tags/category
- **Bulk updates across videos** → `youtube_manager` (loop through video IDs)
- **Automation workflows** → `youtube_automation` (internal use, deprecated API)

### "I need AI assistance"
- **Feed codebase to AI** → `gpt_context` ⭐ PRIMARY USE CASE
- **Template-based prompts** → `prompt_tools` (deprecated API, not recommended)
- **Workflow automation** → `youtube_automation` (internal use)

### "I need configuration"
- **Setup tools** → `ad_config -c` (creates templates)
- **Multi-channel management** → `ad_config -e` (edit channels.json)
- **Team collaboration** → Share JSON configs via Git/Dropbox

---

## Tool Disambiguation

### "subtitle_processor" vs "youtube_manager"
- **subtitle_processor**: Transforms local SRT files (clean/merge/process)
- **youtube_manager**: CRUD operations on YouTube video metadata via API
- **Different purposes**: One is file processor, one is API manager

### "prompt_tools" vs "youtube_automation"
- **prompt_tools**: Single OpenAI Completion API call with template support
- **youtube_automation**: Sequence runner executing multiple prompts
- **Both use deprecated API**: Neither recommended for new work

### "gpt_context" vs "prompt_tools"
- **gpt_context**: Collects project files for AI context (no API calls)
- **prompt_tools**: Executes OpenAI API calls with prompts
- **Use gpt_context for**: Feeding code to Claude/ChatGPT
- **Use prompt_tools for**: Automated API-based completions (if migrated to Chat API)

---

## Scenario-Based Discovery

### Scenario: FliVideo Multi-Part Recording Workflow
```
1. Record video in 5 parts → 5 video files + 5 SRT subtitle files
2. Generate subtitles → YouTube auto-captions (messy)
3. Clean each subtitle → subtitle_processor clean
4. Merge subtitle parts → subtitle_processor join
5. Upload video → (external tool)
6. Update metadata → youtube_manager
7. Organize B-roll images → move_images
```

### Scenario: Post-Rebrand Bulk Video Updates
```
1. Changed channel name → Need to update 50 video descriptions
2. Export video list → youtube_manager get (or YouTube Studio)
3. Loop through videos → youtube_manager update --video-id ID --description "New"
4. Verify changes → youtube_manager get
```

### Scenario: AI-Assisted Code Development
```
1. Need AI help with codebase → gpt_context
2. Gather Ruby files → gpt_context -i '**/*.rb' -e 'spec/**/*' -d
3. Feed to Claude/ChatGPT → Paste from clipboard or read file
4. Iterate with AI → Re-run gpt_context as codebase changes
```

---

## Tool Entry Points by User Type

### 👨‍💻 Developer Using AI Assistants
**Primary tool:** GPT Context Gatherer ⭐
**Workflow:** Collect codebase → Feed to AI → Get help with development

### 🎥 YouTuber with Multi-Part Recordings (FliVideo workflow)
**Primary tools:** Subtitle Processor → YouTube Manager
**Workflow:** Clean captions → Merge parts → Upload → Update metadata

### 📹 YouTuber Managing Multiple Channels
**Primary tools:** Configuration Manager → YouTube Manager
**Workflow:** Setup channels.json → Switch contexts → Bulk update videos

### ⚙️ Tool Administrator
**Primary tool:** Configuration Manager
**Workflow:** Create templates → Setup team configs → Share via Git/Dropbox

---

## Tool Relationships & Dependencies

### Independent Tools (No Dependencies)
- **gpt_context**: Standalone file collector
- **subtitle_processor**: Standalone SRT file processor
- **move_images**: Standalone image organizer

### Configuration-Dependent Tools
- **youtube_manager**: Needs channels.json (optional, for multi-channel)
- **youtube_automation**: Requires youtube_automation.json + Dropbox paths
- **prompt_tools**: No config needed (just OpenAI API key)

### Workflow Sequences
```
Configuration Setup First:
ad_config -c → Edit configs → Use other tools

FliVideo Production:
subtitle_processor clean → subtitle_processor join → youtube_manager

Context Engineering:
gpt_context → Feed to AI → Develop → Repeat
```

---

## Active vs Deprecated Tools

### ✅ ACTIVE TOOLS (Use these)
1. **GPT Context Gatherer** ⭐ - Primary use case
2. **YouTube Manager** - CRUD operations on videos
3. **Subtitle Processor** - SRT file transformation
4. **Configuration Manager** - JSON config management
5. **Move Images** - Video asset organization

### ⚠️ DEPRECATED API (Avoid for new work)
6. **Prompt Tools** - Uses deprecated OpenAI Completion API
7. **YouTube Automation** - Internal use only, deprecated API, hardcoded paths

---

## Common Pitfalls & Troubleshooting

### "I can't find subtitle_manager"
→ Renamed to `subtitle_processor` (more accurate naming)

### "Bundler version mismatch"
→ Run: `eval "$(rbenv init -)" && gem install bundler:2.6.2`

### "YouTube Manager not authenticating"
→ Check `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env`

### "Move Images not working"
→ Check hardcoded paths in bin/move_images.rb (development tool, may need customization)

### "GPT Context output too large"
→ Use `-e` to exclude node_modules, .git, spec directories

---

## Keywords for Discovery

**GPT Context Gatherer:**
- Keywords: AI, context, codebase, ChatGPT, Claude, feed code, token limit, files, patterns

**YouTube Manager:**
- Keywords: video metadata, title, description, tags, category, bulk update, YouTube API, CRUD

**Subtitle Processor:**
- Keywords: SRT, subtitle, captions, clean, merge, join, multi-part, FliVideo, timeline

**Configuration:**
- Keywords: settings, channels, multi-channel, team collaboration, JSON config, paths

**Move Images:**
- Keywords: video assets, B-roll, images, organize, download folder, project structure

---

**Last Updated:** January 2025
