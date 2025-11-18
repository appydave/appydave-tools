# PRD: Client Sharing with Pre-Signed URLs

**Status:** Draft
**Author:** David Cruwys
**Created:** 2025-11-10
**Priority:** Phase 5 Enhancement

---

## Overview

Content creators frequently need to share video files with clients, collaborators, and team members who don't have AWS access. Currently, this requires manual workflows through the S3 console or making files public. DAM should provide a simple, secure way to generate shareable links directly from the command line.

### Current State

**Problem:** Sharing videos with clients is cumbersome

**Current workflows:**
1. **Manual S3 Console** - Log in → Navigate → Select file → Generate pre-signed URL → Copy → Email
2. **Public S3 Files** - Make bucket/file public (security risk, permanent access)
3. **Download & Re-upload** - Download from S3 → Upload to file sharing service
4. **Email attachment** - Download → Compress → Email (limited by file size)

**Pain points:**
- Time-consuming multi-step process
- Requires AWS console access
- No expiry management
- No HTML embed support
- Manual copy-paste prone to errors

### Proposed State

**Unified DAM Interface:**
```bash
# Basic: Share single video (7-day expiry default)
dam share appydave b70 video.mp4

# Advanced: Custom expiry and HTML embed
dam share appydave b70 video.mp4 --expires 14d --html

# Multiple files: Generate shareable index page
dam share appydave b70 *.mp4 --expires 3d --index
```

**Output:**
```
📤 Shareable link (expires in 7 days):
https://appydave-video-projects.s3.ap-southeast-1.amazonaws.com/staging/v-appydave/b70/video.mp4?X-Amz-Signature=...&X-Amz-Expires=604800

📋 Copied to clipboard!

🎬 HTML embed code:
<video controls width="800">
  <source src="https://..." type="video/mp4">
</video>
```

---

## Goals

### Primary Goals

1. **One-Command Sharing** - Generate shareable URL with single command
2. **Clipboard Integration** - Automatic clipboard copy for quick pasting
3. **Secure by Default** - Time-limited pre-signed URLs (no permanent public access)
4. **Client-Friendly** - No AWS account required for recipients

### Secondary Goals

5. **HTML Embed Support** - Generate embed code for video players
6. **Multiple File Support** - Share entire project or filtered files
7. **Customizable Expiry** - Flexible time windows (hours to days)
8. **Index Generation** - Create HTML page listing multiple videos

### Non-Goals

- **CloudFront integration** - Not implementing CDN (future enhancement)
- **Upload via share** - Only sharing existing files, not upload workflows
- **Authentication** - Pre-signed URLs are authentication (no additional login)
- **Analytics tracking** - Not tracking who viewed/downloaded

---

## User Stories

### Story 1: Share Single Video with Client (Primary Use Case)

**As a content creator,**
**I want to share a video file with a client quickly,**
**So they can review it without needing AWS access.**

**Workflow:**
```bash
# From anywhere
dam share appydave b70 final-edit.mp4

# Output copied to clipboard automatically
# Paste into email/Slack and send
```

**Acceptance criteria:**
- ✅ Generates pre-signed URL with 7-day default expiry
- ✅ Copies URL to system clipboard automatically
- ✅ Shows expiry date/time clearly
- ✅ Client can view video in browser (no download required)
- ✅ Works from any directory (uses brand/project resolution)

---

### Story 2: Share with Custom Expiry Time

**As a content creator,**
**I want to control how long the shared link remains valid,**
**So I can match client review timelines.**

**Workflow:**
```bash
# Quick review (24 hours)
dam share appydave b70 draft.mp4 --expires 24h

# Extended review (2 weeks)
dam share appydave b70 final.mp4 --expires 14d
```

**Acceptance criteria:**
- ✅ Supports hours (h), days (d) suffixes
- ✅ Minimum: 1 hour
- ✅ Maximum: 7 days (S3 pre-signed URL limit)
- ✅ Shows expiry timestamp in output
- ✅ Clear error if expiry exceeds limits

---

### Story 3: Generate HTML Embed Code

**As a content creator,**
**I want to embed videos in HTML pages,**
**So clients can view them in custom review portals.**

**Workflow:**
```bash
dam share appydave b70 video.mp4 --html
```

**Output:**
```html
📤 Shareable link (expires in 7 days):
https://...

📋 Copied to clipboard!

🎬 HTML embed code:
<video controls width="800" preload="metadata">
  <source src="https://..." type="video/mp4">
  Your browser does not support the video tag.
</video>
```

**Acceptance criteria:**
- ✅ Generates complete `<video>` tag
- ✅ Includes responsive width
- ✅ Includes fallback message
- ✅ Copies HTML to clipboard when --html flag used
- ✅ Works with common video formats (mp4, mov, webm)

---

### Story 4: Share Multiple Files

**As a content creator,**
**I want to share multiple video files at once,**
**So clients can review all deliverables together.**

**Workflow:**
```bash
# Share all MP4s in project
dam share appydave b70 *.mp4 --expires 3d
```

**Output:**
```
📤 Sharing 3 files (expires in 3 days):

1. intro.mp4
   https://...

2. main-content.mp4
   https://...

3. outro.mp4
   https://...

📋 All links copied to clipboard!
```

**Acceptance criteria:**
- ✅ Supports glob patterns (*.mp4, video-*.mov)
- ✅ Generates individual URLs for each file
- ✅ Copies all URLs to clipboard (newline-separated)
- ✅ Shows count of files shared
- ✅ Consistent expiry across all files

---

### Story 5: Generate Shareable Index Page

**As a content creator,**
**I want to create an HTML page with all videos,**
**So clients have a single link to view all deliverables.**

**Workflow:**
```bash
dam share appydave b70 *.mp4 --index --expires 7d
```

**Output:**
```
📤 Generated shareable index (expires in 7 days):
/Users/davidcruwys/dev/video-projects/v-appydave/b70-project/share-index.html

🌐 Index URL:
https://appydave-video-projects.s3.ap-southeast-1.amazonaws.com/staging/v-appydave/b70/share-index.html?...

📋 Copied to clipboard!

Index includes:
  - intro.mp4 (125 MB)
  - main-content.mp4 (2.3 GB)
  - outro.mp4 (89 MB)
```

**Acceptance criteria:**
- ✅ Generates HTML file with embedded video players
- ✅ Shows file names, sizes, and thumbnails
- ✅ Includes all videos with individual pre-signed URLs
- ✅ Uploads index.html to S3 with pre-signed URL
- ✅ Mobile-responsive design
- ✅ Single link for client (just share index URL)

---

## Technical Design

### Architecture

**Command Structure:**
```ruby
# bin/dam
def share_command(args)
  options = parse_share_args(args)
  share_ops = Appydave::Tools::Dam::ShareOperations.new(options[:brand], options[:project])
  share_ops.generate_links(
    files: options[:files],
    expires: options[:expires],
    html: options[:html],
    index: options[:index]
  )
end
```

**New Module:**
```ruby
# lib/appydave/tools/dam/share_operations.rb
module Appydave::Tools::Dam
  class ShareOperations
    def initialize(brand, project)
      @brand = brand
      @project = project
      @config = load_brand_config(brand)
      @s3_client = setup_s3_client
    end

    def generate_links(files:, expires: '7d', html: false, index: false)
      # 1. Resolve file paths
      # 2. Generate pre-signed URLs (using AWS SDK)
      # 3. Copy to clipboard
      # 4. Generate HTML if requested
      # 5. Create index page if requested
    end
  end
end
```

### AWS SDK Integration

**Pre-signed URL generation:**
```ruby
def generate_presigned_url(s3_key, expires_in_seconds)
  presigner = Aws::S3::Presigner.new(client: @s3_client)
  presigner.presigned_url(
    :get_object,
    bucket: @config.aws.s3_bucket,
    key: s3_key,
    expires_in: expires_in_seconds
  )
end
```

### Clipboard Integration

**Cross-platform clipboard support:**
```ruby
require 'clipboard' # Already in gemspec

def copy_to_clipboard(text)
  Clipboard.copy(text)
  puts "📋 Copied to clipboard!"
rescue StandardError => e
  puts "⚠️  Could not copy to clipboard: #{e.message}"
  puts "   (URL shown above for manual copy)"
end
```

### Expiry Parsing

**Human-friendly time parsing:**
```ruby
def parse_expiry(expiry_string)
  # Examples: "24h", "7d", "2d", "48h"
  case expiry_string
  when /^(\d+)h$/
    hours = $1.to_i
    raise "Expiry must be at least 1 hour" if hours < 1
    raise "Expiry cannot exceed 168 hours (7 days)" if hours > 168
    hours * 3600
  when /^(\d+)d$/
    days = $1.to_i
    raise "Expiry must be at least 1 day" if days < 1
    raise "Expiry cannot exceed 7 days" if days > 7
    days * 86400
  else
    raise "Invalid expiry format. Use: 24h, 7d, etc."
  end
end
```

### HTML Generation

**Basic embed template:**
```html
<video controls width="800" preload="metadata" style="max-width: 100%;">
  <source src="{PRESIGNED_URL}" type="video/mp4">
  Your browser does not support the video tag.
</video>
```

**Index page template:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Video Review - {PROJECT_NAME}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: system-ui; max-width: 1200px; margin: 2rem auto; padding: 0 1rem; }
    video { width: 100%; max-width: 800px; display: block; margin: 1rem 0; }
    .video-item { margin: 2rem 0; padding: 1rem; border: 1px solid #ddd; border-radius: 8px; }
    .filename { font-size: 1.2rem; font-weight: bold; }
    .filesize { color: #666; }
    .expiry { color: #c00; font-style: italic; }
  </style>
</head>
<body>
  <h1>Video Review: {PROJECT_NAME}</h1>
  <p class="expiry">⚠️ Links expire: {EXPIRY_DATE}</p>

  {VIDEO_ITEMS}
</body>
</html>
```

---

## Command Reference

### Basic Usage

```bash
# Share single file (7-day default)
dam share <brand> <project> <file>

# Examples
dam share appydave b70 final-edit.mp4
dam share voz boy-baker scene-01.mov
```

### With Options

```bash
# Custom expiry
dam share appydave b70 video.mp4 --expires 24h
dam share appydave b70 video.mp4 --expires 14d

# Generate HTML embed code
dam share appydave b70 video.mp4 --html

# Multiple files
dam share appydave b70 *.mp4
dam share appydave b70 scene-*.mov --expires 3d

# Generate index page
dam share appydave b70 *.mp4 --index
dam share appydave b70 *.mp4 --index --html --expires 7d
```

### Auto-Detection

```bash
# From project directory
cd ~/dev/video-projects/v-appydave/b70-project
dam share video.mp4
dam share *.mp4 --index
```

### Help

```bash
dam help share
dam share --help
```

---

## Implementation Plan

### Phase 1: Basic Pre-Signed URLs (MVP)

**Scope:**
- Single file sharing
- 7-day default expiry
- Clipboard integration
- Basic error handling

**Commands:**
```bash
dam share appydave b70 video.mp4
```

**Estimated effort:** 4-6 hours

**Files to create:**
- `lib/appydave/tools/dam/share_operations.rb`
- `spec/appydave/tools/dam/share_operations_spec.rb`

**Files to modify:**
- `bin/dam` (add share_command)

---

### Phase 2: Advanced Options

**Scope:**
- Custom expiry (hours/days)
- HTML embed code generation
- Multiple file support
- Auto-detection from PWD

**Commands:**
```bash
dam share appydave b70 video.mp4 --expires 24h --html
dam share appydave b70 *.mp4 --expires 3d
```

**Estimated effort:** 3-4 hours

**New features:**
- Expiry parsing (`parse_expiry`)
- HTML template generation
- Glob pattern support

---

### Phase 3: Index Generation

**Scope:**
- HTML index page creation
- Multiple video embedding
- File size display
- Upload index to S3

**Commands:**
```bash
dam share appydave b70 *.mp4 --index --expires 7d
```

**Estimated effort:** 4-5 hours

**New features:**
- Index HTML template
- Upload index.html to S3
- Generate pre-signed URL for index
- Responsive design

---

## Testing Strategy

### Unit Tests

```ruby
# spec/appydave/tools/dam/share_operations_spec.rb
describe ShareOperations do
  describe '#generate_presigned_url' do
    it 'generates valid S3 pre-signed URL'
    it 'includes correct expiry time'
    it 'uses correct S3 bucket and key'
  end

  describe '#parse_expiry' do
    it 'parses hours (24h → 86400 seconds)'
    it 'parses days (7d → 604800 seconds)'
    it 'raises error for invalid format'
    it 'raises error for expiry > 7 days'
  end

  describe '#generate_html_embed' do
    it 'generates valid video tag'
    it 'includes presigned URL'
    it 'handles different video formats'
  end
end
```

### Integration Tests

```bash
# Manual testing checklist
1. Share single MP4 file (verify URL works in browser)
2. Share with 24h expiry (verify expires_in parameter)
3. Generate HTML embed (verify renders in browser)
4. Share multiple files (verify all URLs generated)
5. Generate index page (verify uploads to S3 and renders)
6. Auto-detect from project directory
7. Error handling (missing file, invalid expiry)
```

---

## Security Considerations

### Pre-Signed URL Security

**✅ Secure by default:**
- Time-limited access (1 hour to 7 days)
- URL includes cryptographic signature
- No permanent public access
- Revocable (delete S3 file = broken link)

**⚠️ Considerations:**
- Anyone with URL can access (don't share publicly)
- URLs can be forwarded (client could share with others)
- No view tracking or analytics

**Best practices:**
- Use shortest expiry needed for use case
- Share via secure channels (email, Slack, not public forums)
- Delete S3 file if early revocation needed

### S3 Bucket Permissions

**Required permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::appydave-video-projects/staging/*"
    }
  ]
}
```

---

## Documentation Updates

### Help System

**Add to `dam help`:**
```
Share Commands:
  dam share <brand> <project> <file>           Generate shareable URL
  dam share <brand> <project> <file> --html   Generate HTML embed code
  dam share <brand> <project> *.mp4 --index   Create shareable index page
```

**New help page:**
```bash
dam help share
# Shows: Full usage, examples, expiry options, HTML generation
```

### Usage Guide

**Update `docs/dam/usage.md`:**
- Add "Client Sharing" section
- Include examples for all use cases
- Document security best practices
- Explain pre-signed URL limitations

### Testing Plan

**Update `docs/dam/dam-testing-plan.md`:**
- Add Phase 5 tests for share command
- Include test cases for each story
- Manual verification steps for URLs

---

## Success Metrics

**Adoption:**
- 70% of content creators use `dam share` within 2 weeks
- Reduced time from "need to share" to "link sent" from 5 minutes to 30 seconds

**Usability:**
- Zero reported issues with clipboard integration
- Positive feedback on HTML embed generation
- Client satisfaction (no AWS access required)

**Technical:**
- 90%+ test coverage for ShareOperations
- Zero security incidents (no accidental public files)
- Expiry times respected (no premature/late expirations)

---

## Future Enhancements (Phase 6+)

### CloudFront Integration
- Faster delivery via CDN
- Custom domain (share.appydave.com)
- Longer expiry times (CloudFront signed URLs can last years)

### Analytics Tracking
- View count per video
- Geographic distribution of viewers
- Watch duration metrics

### Password Protection
- Optional password for sensitive videos
- Client enters password to unlock video

### Batch Operations
- Share entire project with one command
- Generate weekly review packages
- Scheduled expiry reminders

### Team Collaboration
- Share internally within team (different expiry rules)
- Comment/feedback integration
- Version comparison views

---

## Appendix

### Related Commands

**Existing DAM commands that share uses:**
- `dam s3-up` - Must upload file to S3 before sharing
- `dam s3-status` - Check if file exists in S3
- `dam list` - Discover available files to share

**Workflow integration:**
```bash
# Complete workflow: upload and share
dam s3-up appydave b70 final-edit.mp4
dam share appydave b70 final-edit.mp4 --expires 7d --html
```

### References

**AWS Documentation:**
- [S3 Pre-Signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html)
- [AWS SDK for Ruby - S3 Presigner](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Presigner.html)

**Similar Tools:**
- Dropbox (share links with expiry)
- Google Drive (shareable links)
- Frame.io (video review platform)

---

**Document Version:** 1.0
**Status:** Ready for Implementation
**Next Steps:** Review with team → Implement Phase 1 MVP → User testing
