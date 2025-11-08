# YouTube Manager

Retrieve and update YouTube video metadata, descriptions, tags, and other details at scale.

## What It Does

**YouTube Manager** automates YouTube video metadata management. Instead of manually clicking through YouTube Studio, this tool:

- Retrieves video metadata (title, description, tags, category)
- Updates descriptions, titles, tags across multiple videos
- Fetches caption/subtitle information
- Handles YouTube API authentication
- Generates detailed video reports
- Supports batch operations for efficiency

## How to Use

### Authentication Setup

First time only - authenticate with Google:

```bash
youtube_manager get -v dQw4w9WgXcQ
```

This opens a browser to authorize the app with your YouTube account. The token is stored locally in `~/.config/appydave`.

### Get Video Details

```bash
# Get information about a specific video
youtube_manager get -v dQw4w9WgXcQ

# Output shows: title, description, tags, category, view count, etc.
```

### Update Video Metadata

```bash
# Update title
youtube_manager update -v dQw4w9WgXcQ -t "New Video Title"

# Update description
youtube_manager update -v dQw4w9WgXcQ -d "New description here..."

# Update tags (comma-separated)
youtube_manager update -v dQw4w9WgXcQ -g "tag1,tag2,tag3"

# Update category (use category ID)
youtube_manager update -v dQw4w9WgXcQ -c "15"

# Combine multiple updates
youtube_manager update -v dQw4w9WgXcQ -t "New Title" -d "New desc" -g "tag1,tag2"
```

### Common YouTube Category IDs

| ID | Category |
|----|----------|
| 1 | Film & Animation |
| 2 | Autos & Vehicles |
| 10 | Music |
| 15 | Pets & Animals |
| 17 | Sports |
| 18 | Shorts |
| 19 | Travel & Events |
| 20 | Gaming |
| 21 | Videoblogging |
| 22 | People & Blogs |
| 23 | Comedy |
| 24 | Entertainment |
| 25 | News & Politics |
| 26 | Howto & Style |
| 27 | Education |
| 28 | Science & Technology |
| 29 | Nonprofits & Activism |

## Use Cases for AI Agents

### 1. Post-Rebrand Updates
```bash
# Change channel name in all video descriptions (scenario)
# AI agent: Get all videos, identify descriptions containing old name
# Then update each with new branding
youtube_manager get -v VIDEO_ID_1
youtube_manager update -v VIDEO_ID_1 -d "Updated description with new brand name"
```
**AI discovers**: Current naming patterns, branding consistency. Can identify all rebranding opportunities and execute bulk updates.

### 2. Tag Standardization
```bash
# Ensure consistent tagging across catalog
youtube_manager get -v VIDEO_ID_1  # Get current tags
# AI analyzes tag patterns, suggests standardized tags
youtube_manager update -v VIDEO_ID_1 -g "correct,standardized,tags"
```
**AI discovers**: Tagging patterns, missing tags, inconsistent naming. Can standardize tags across entire catalog.

### 3. Category Auditing & Correction
```bash
# Get videos in wrong category
youtube_manager get -v VIDEO_ID_1  # Check category
# AI identifies misclassified videos
youtube_manager update -v VIDEO_ID_1 -c "15"  # Move to correct category
```
**AI discovers**: Category assignments, whether videos are properly categorized. Can suggest corrections based on content.

### 4. Metadata Extraction for Analytics
```bash
# Get video details for export
youtube_manager get -v VIDEO_ID_1
# AI collects metadata across multiple videos for analysis
```
**AI discovers**: View counts, engagement metrics, description patterns. Can generate reports, identify top performers.

### 5. Description Optimization
```bash
# Get current description
youtube_manager get -v VIDEO_ID_1
# AI analyzes description for SEO, engagement, clarity
# Suggests improvements including keywords, CTAs, timestamps
youtube_manager update -v VIDEO_ID_1 -d "Optimized description with keywords and structure"
```
**AI discovers**: Current SEO elements, call-to-actions, structure. Can improve descriptions for discoverability and engagement.

### 6. Series/Playlist Linking
```bash
# Get videos, identify series
youtube_manager get -v VIDEO_ID_1
# AI analyzes which videos belong to series
# Suggests adding series links to descriptions
youtube_manager update -v VIDEO_ID_1 -d "Optimized with series link in description"
```
**AI discovers**: Video relationships, series structure. Can add linking information to improve viewer navigation.

### 7. Bulk Correction Workflows
```bash
# Scenario: Need to update 50 videos with new info
# AI agent orchestrates:
# 1. Get all video IDs in channel
# 2. For each: get metadata, analyze, suggest updates
# 3. Batch execute updates with youtube_manager
```
**AI discovers**: What needs changing, patterns across videos. Can execute systematic bulk corrections.

### 8. Caption/Subtitle Management (Future)
```bash
# Plan AI workflow: get video captions, analyze, update
youtube_manager get -v VIDEO_ID_1
# Returns caption information when available
```
**AI discovers**: Whether videos have captions, language availability. Can plan caption addition or updates.

### 9. Content Audit & Compliance
```bash
# Get descriptions to audit for compliance
youtube_manager get -v VIDEO_ID_1
# AI reviews descriptions for brand compliance, accuracy, links
# Suggests corrections for non-compliant videos
```
**AI discovers**: Compliance issues, outdated links, inaccurate info. Can flag and correct systematically.

### 10. Performance Metadata Analysis
```bash
# Get metrics alongside descriptions
youtube_manager get -v VIDEO_ID_1
# AI correlates description length, tags, category with performance
# Suggests improvements based on high-performing patterns
```
**AI discovers**: What metadata correlates with views/engagement. Can recommend optimizations based on data patterns.

## Command Reference

### Get Command
```bash
youtube_manager get -v VIDEO_ID [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Video ID | `-v` | `--video-id ID` | YouTube Video ID (required) |
| Help | `-h` | `--help` | Show help message |

**Output includes**: Title, description, tags, category, view count, like count, upload date.

### Update Command
```bash
youtube_manager update -v VIDEO_ID [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Video ID | `-v` | `--video-id ID` | YouTube Video ID (required) |
| Title | `-t` | `--title TITLE` | New video title |
| Description | `-d` | `--description DESC` | New description |
| Tags | `-g` | `--tags TAGS` | Comma-separated tags |
| Category | `-c` | `--category-id ID` | YouTube category ID |
| Help | `-h` | `--help` | Show help message |

## Finding Video IDs

Video ID is the part after `v=` in YouTube URLs:

```
https://www.youtube.com/watch?v=dQw4w9WgXcQ
                               ^^^^^^^^^^^^^^ <- This is the video ID
```

Or after `youtu.be/`:

```
https://youtu.be/dQw4w9WgXcQ
         ^^^^^^^^^^^^^^ <- This is the video ID
```

## Configuration

YouTube Manager uses Google OAuth 2.0 for authentication:

- **Config location**: `~/.config/appydave/channels.json`
- **Token storage**: `~/.config/appydave/` (auto-created on first auth)
- **No manual setup needed**: First command triggers authentication flow

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Authentication failed" | Delete `~/.config/appydave` and run command again to re-authenticate |
| "Invalid video ID" | Verify video ID is correct (check YouTube URL) |
| "Permission denied" | Re-authenticate with account that owns the channel |
| "API quota exceeded" | Wait 24 hours or upgrade YouTube API quota in Google Cloud Console |

## Tips & Tricks

1. **Batch operations**: Create shell script to update multiple videos
2. **Descriptions with newlines**: Use proper escaping for multi-line descriptions
3. **Tag limits**: YouTube allows max 500 characters of tags total
4. **Description limits**: Max 5000 characters for descriptions
5. **Test first**: Use `get` to verify video before using `update`

---

**Related Tools**:
- `gpt_context` - Gather context before planning metadata updates
- `youtube_automation` - Automate repetitive YouTube workflows
- `configuration` - Manage multiple YouTube channels

**References**: [YouTube Data API](https://developers.google.com/youtube/v3)
