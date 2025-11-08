# Subtitle Processor

Clean, normalize, and merge SRT subtitle files with configurable formatting and timeline adjustments.

## What It Does

**Subtitle Processor** handles video subtitle (SRT) file operations:

- Cleans and normalizes SRT formatting (removes HTML tags, fixes encoding)
- Joins multiple SRT files into one with timeline offset
- Handles timing synchronization across segments
- Supports various sort orders (ascending, descending, inferred)
- Flexible buffer/gap control between segments
- UTF-8 encoding handling

## How to Use

### Clean Subtitles

Remove formatting issues, HTML tags, and normalize SRT structure:

```bash
# Clean a subtitle file
subtitle_processor clean -f input.srt -o output.srt

# Clean and review
subtitle_processor clean -f subtitles.srt -o cleaned.srt
```

**What it fixes**:
- Removes HTML tags (`<u>`, `<b>`, `<i>`, etc.)
- Fixes character encoding issues
- Normalizes line breaks and spacing
- Ensures proper SRT format (number, timestamp, text, blank line)

### Join Subtitles

Merge multiple SRT files with proper timeline management:

```bash
# Join all SRT files in a directory
subtitle_processor join -d ./ -f "*.srt" -o merged.srt

# Join specific files with custom buffer
subtitle_processor join -d ./subtitles -f "part1.srt,part2.srt,part3.srt" -b 500 -o final.srt

# Join with specific sort order
subtitle_processor join -d ./ -f "*.srt" -s "asc" -o merged.srt
```

**Key options**:
- `-d` / `--directory`: Folder containing SRT files (default: current)
- `-f` / `--files`: Pattern (`*.srt`) or comma-separated list
- `-s` / `--sort`: Order (`asc`, `desc`, `inferred`) - inferred uses numeric filename order
- `-b` / `--buffer`: Gap between segments in milliseconds (default: 100ms)
- `-o` / `--output`: Output filename (default: `merged.srt`)

## Use Cases for AI Agents

### 1. Subtitle Quality Assurance
```bash
# Clean subtitles before publishing
subtitle_processor clean -f extracted-subs.srt -o published.srt
```
**AI discovers**: Formatting issues, encoding problems, HTML artifacts. Can identify and fix subtitle quality problems systematically.

### 2. Multi-Part Video Subtitle Handling
```bash
# Combine subtitles from video segments
subtitle_processor join -d ./segments -f "*.srt" -s "inferred" -o complete.srt
```
**AI discovers**: How multiple video segments need proper timing. Can orchestrate subtitle merging for multi-part content.

### 3. Subtitle Synchronization
```bash
# Adjust timing between merged segments
subtitle_processor join -d ./ -f "part1.srt,part2.srt" -b 200 -o sync.srt
```
**AI discovers**: Timing requirements between segments. Can calculate and apply correct timing offsets.

### 4. Batch Subtitle Processing
```bash
# Process all subtitles in project
# AI orchestrates:
# 1. Find all .srt files
# 2. Clean each one
# 3. Verify cleaned files are valid
```
**AI discovers**: How to systematically process multiple subtitle files. Can batch process and verify quality.

### 5. Subtitle Format Migration
```bash
# Convert between subtitle standards via cleanup
subtitle_processor clean -f old-format.srt -o new-format.srt
```
**AI discovers**: Original SRT issues and formatting. Can prepare for format conversion.

### 6. Damage Repair
```bash
# Fix corrupted or poorly extracted subtitles
subtitle_processor clean -f corrupted.srt -o repaired.srt
```
**AI discovers**: Encoding issues, formatting damage. Can restore usable subtitles from corrupted sources.

### 7. Merged Video Preparation
```bash
# Prepare subtitles when merging video files
subtitle_processor join -d ./ -f "intro.srt,main.srt,outro.srt" -b 100 -o merged.srt
```
**AI discovers**: How many segments, their order, timing requirements. Can prepare complete subtitle for merged video.

### 8. Archive Subtitle Cleanup
```bash
# Clean up subtitle library
# AI processes all subtitles, removes HTML, normalizes encoding
for file in *.srt; do
  subtitle_processor clean -f "$file" -o "cleaned/$file"
done
```
**AI discovers**: Quality issues across library. Can systematically improve archive.

### 9. Subtitle Editing Preparation
```bash
# Clean before human editing
subtitle_processor clean -f raw.srt -o edit-ready.srt
```
**AI discovers**: What needs fixing before human review. Can prepare clean files for editing.

### 10. Workflow Automation
```bash
# Full subtitle workflow in script
# Extract subtitles from video
# Clean extracted subtitles
# Join with other segments if needed
# Verify output is valid SRT
```
**AI discovers**: Complete workflow from extraction to publishing. Can automate multi-step subtitle processes.

## Command Reference

### Clean Command
```bash
subtitle_processor clean [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| File | `-f` | `--file FILE` | SRT file to process (required) |
| Output | `-o` | `--output FILE` | Output file (required) |
| Help | `-h` | `--help` | Show help |

**Input**: Any SRT file (even malformed)
**Output**: Cleaned, valid SRT format

### Join Command
```bash
subtitle_processor join [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Directory | `-d` | `--directory DIR` | Folder with SRT files (default: current) |
| Files | `-f` | `--files PATTERN` | Pattern `*.srt` or list `part1.srt,part2.srt` |
| Sort | `-s` | `--sort ORDER` | `asc`, `desc`, or `inferred` (default: inferred) |
| Buffer | `-b` | `--buffer MS` | Gap between segments in ms (default: 100) |
| Output | `-o` | `--output FILE` | Output filename (default: merged.srt) |
| Log Level | `-L` | `--log-level LEVEL` | `none`, `info`, `detail` |
| Help | `-h` | `--help` | Show help |

## SRT Format Reference

Valid SRT file structure:

```
1
00:00:00,000 --> 00:00:03,000
First subtitle

2
00:00:03,500 --> 00:00:07,000
Second subtitle

3
00:00:07,500 --> 00:00:10,000
Third subtitle
```

**Important**:
- Sequence numbers must be sequential (1, 2, 3...)
- Timestamps use comma for milliseconds (00:00:00,000)
- Blank line required between entries
- Text can be multiple lines
- No HTML tags (Processor removes these)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Missing required options" | Provide both `-f` (file) and `-o` (output) for clean command |
| "File not found" | Check file path and permissions |
| "Encoding error" | Try cleaning first to fix encoding: `clean -f file.srt -o temp.srt` |
| "Invalid sort order" | Use `asc`, `desc`, or `inferred` |
| "Timestamp overlap" | Reduce or remove buffer with `-b 0` |

## Tips & Tricks

1. **Always clean extracted subtitles**: Video tools often create messy SRT with HTML tags
2. **Test join first**: Review timing with small file set before processing 100+ files
3. **Use inferred sort**: Helps when files are numbered (part1.srt, part2.srt)
4. **Buffer for safety**: Small buffer (100-200ms) prevents timing overlaps between segments
5. **Backup originals**: Always keep original .srt files before processing

## Examples

### Clean Subtitles from YouTube
```bash
# YouTube captions often have encoding issues
subtitle_processor clean -f youtube-captions.srt -o youtube-clean.srt
```

### Merge Multi-Part Educational Video
```bash
# Join chapter subtitles with 500ms gap
subtitle_processor join -d chapters/ -f "*.srt" -s "inferred" -b 500 -o course-complete.srt
```

### Fix Corrupted Archive
```bash
# Repair entire subtitle library
for file in archive/*.srt; do
  subtitle_processor clean -f "$file" -o "archive-clean/$(basename $file)"
done
```

---

**Related Tools**:
- `youtube_manager` - Manage video metadata alongside subtitles
- `gpt_context` - Gather subtitle data for analysis
- `move_images` - Part of video processing pipeline

**File Format**: [SRT Format Specification](https://en.wikipedia.org/wiki/SubRip)
