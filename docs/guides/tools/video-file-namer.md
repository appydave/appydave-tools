# VideoFileNamer - Filename Generation Tool

> **Web-based utility for generating structured video segment filenames** following the FliVideo naming convention.

---

## 📋 Overview

**App Name**: VideoFileNamer
**Type**: Web Application (Replit)
**Purpose**: Generate structured filenames for video recording segments with clipboard management
**Target Users**: Content creators, video producers, YouTubers
**Database**: ReplDB

### Important Clarification

⚠️ **This application does NOT rename or modify actual files on your system.** It is purely a filename generator that:
- Creates structured filenames following conventions
- Copies filenames to your clipboard
- You manually rename files in your file manager

---

## 🎯 Core Features

### 1. Automatic Filename Generation

Generates filenames using a standardized format compatible with **FliVideo naming conventions**:

```
[chapter]-[part]-[label]-[metadata?].mov
```

**Format Components:**
- **Chapter**: Sequential number (1, 2, 3, etc.) - auto-incremented
- **Part**: Part number within chapter (1, 2, 3, etc.) - resets on new chapter
- **Label**: Chapter name/description (intro, content, outro, etc.)
- **Metadata** (Optional): Additional tags (cta, endcards, etc.)

### 2. Real-Time Filename Preview

- Read-only column shows generated filename as you type
- Updates instantly when you modify chapter, part, label, or metadata
- Visual feedback for filename generation

### 3. Clipboard Integration

- Copy individual filenames to clipboard with one click
- Auto-clipboard option: Automatically copy filenames to clipboard after you finish typing
- Clipboard actions are logged for debugging

### 4. Smart Row Management

- **Next Chapter**: Adds new row with chapter incremented, part reset to 1
- **Next Part**: Adds new row with same chapter, part incremented
- Preserves labels when adding new parts in same chapter
- Prevents manual data entry redundancy

### 5. Data Persistence

- Stores generated filenames and metadata in ReplDB
- Retrieve history of previously generated names
- Track transcript text alongside filenames

---

## 🎬 Filename Format & Examples

### Default Structure

```
[chapter number]-[part number]-[label].mov
```

### With Metadata

```
[chapter number]-[part number]-[label]-[metadata].mov
```

### Examples

| Input | Output |
|-------|--------|
| Chapter: 1, Part: 1, Label: intro | `1-1-intro.mov` |
| Chapter: 1, Part: 2, Label: intro | `1-2-intro.mov` |
| Chapter: 2, Part: 1, Label: content | `2-1-content.mov` |
| Chapter: 2, Part: 1, Label: content, Metadata: cta | `2-1-content-cta.mov` |
| Chapter: 3, Part: 2, Label: outro, Metadata: endcards | `3-2-outro-endcards.mov` |

---

## 🖥️ User Interface & Workflow

### Initial Load

- Empty table displayed on startup
- One pre-filled row created automatically:
  - Chapter: 1
  - Part: 1
  - Label: (empty - user fills in)

### Typical Workflow

1. **View default row**: Table shows one empty row (1-1)
2. **Enter label**: Type label name (e.g., "intro")
3. **See filename update**: Read-only column shows `1-1-intro.mov`
4. **Copy filename**: Click copy button or enable auto-clipboard
5. **Add more segments**: Use "Next Part" to add 1-2, "Next Chapter" to add 2-1
6. **Continue workflow**: Repeat for each segment

### UI Elements

#### Input Fields (Per Row)
- **Chapter**: Numeric input (auto-incremented via buttons)
- **Part**: Numeric input (auto-incremented via buttons)
- **Label**: Text input (chapter name/description)
- **Metadata**: Text input (optional tags)

#### Output Column
- **Filename**: Read-only display of generated name
- **Copy Button**: One-click clipboard copy

#### Control Buttons
- **Next Chapter**: Increment chapter, reset part to 1, add new row
- **Next Part**: Increment part, keep chapter, add new row
- **Auto-Clipboard Checkbox**: Toggle auto-copy functionality

#### Additional Controls
- **Delete Row**: Remove row from table
- **Clear All**: Start fresh

---

## ⚙️ Technical Specifications

### Filename Generation Algorithm

```
1. Validate inputs (chapter, part, label not empty)
2. Format chapter as integer (1, 2, 3... not 01, 02, 03)
3. Format part as integer (1, 2, 3... not 01, 02, 03)
4. Combine: "{chapter}-{part}-{label}"
5. Append metadata if provided: "{chapter}-{part}-{label}-{metadata}"
6. Append extension: "{chapter}-{part}-{label}-{metadata}.mov"
```

### Auto-Increment Logic

**Next Chapter Button:**
- Chapter: current_chapter + 1
- Part: reset to 1
- Label: prompt user for new chapter name
- Create new row with these values

**Next Part Button:**
- Chapter: keep same
- Part: current_part + 1
- Label: preserve from previous row
- Create new row with these values

### Debouncing

- API calls debounced to 1 second after user stops typing
- Prevents excessive database operations
- Smooth typing experience without lag

### Auto-Clipboard

- Triggered 1 second after user finishes editing
- Only copies when auto-clipboard is enabled
- Shows toast notification: "Filename copied to clipboard"
- Logged for debugging

---

## 📊 Data Structure

### File Entry

```json
{
  "id": "unique-identifier",
  "chapter": 1,
  "part": 1,
  "label": "intro",
  "metadata": ["cta"],
  "filename": "1-1-intro-cta.mov",
  "transcript": "Optional transcript text...",
  "createdAt": "2024-11-25T10:30:00Z",
  "updatedAt": "2024-11-25T10:30:00Z"
}
```

### Database Storage (ReplDB)

- **Filenames Table**: Stores all generated filename entries
- **Metadata Table**: Optional - stores transcript and additional context
- **History**: Full edit history maintained for reference

---

## 🔍 Input Validation

### Required Fields
- ✅ **Chapter**: Must be numeric, > 0
- ✅ **Part**: Must be numeric, > 0
- ✅ **Label**: Must not be empty

### Optional Fields
- ⭕ **Metadata**: Optional, can contain multiple comma-separated tags

### Error Handling

**Display descriptive errors:**
- "Chapter must be a number greater than 0"
- "Label cannot be empty"
- "Database connection error - please try again"
- "Clipboard copy failed - try again manually"

---

## 📝 Logging & Debugging

### Logged Events

**Input Changes:**
```
[LOG] Chapter changed: 1 → 2
[LOG] Part changed: 1 → 2
[LOG] Label changed: "" → "intro"
[LOG] Metadata changed: "" → "cta"
```

**Filename Generation:**
```
[LOG] Filename generated: 1-1-intro.mov
[LOG] Filename updated: 1-1-intro.mov → 1-1-intro-cta.mov
```

**Clipboard Actions:**
```
[LOG] Filename copied to clipboard: 1-1-intro.mov
[LOG] Auto-clipboard enabled: true
[LOG] Auto-clipboard disabled: false
```

**Database Operations:**
```
[LOG] Saving filename to database: 1-1-intro.mov
[LOG] Retrieved 12 filenames from history
[LOG] Database error: Connection timeout
```

### Browser Console

- All events logged to browser console (F12 → Console tab)
- Timestamps included for debugging
- Debug information easily searchable for troubleshooting

---

## 🎬 Integration with FliVideo

VideoFileNamer is a companion tool to **FliVideo** that generates segment filenames following FliVideo naming conventions:

### FliVideo Naming Standards

| Element | Format | Example |
|---------|--------|---------|
| Project Folder | `[sequence]-[project-name]` | `a27-my-video-project` |
| Episode Folder | `[sequence]-[episode-name]` | `01-introduction` |
| **Video Segment** | **`[chapter]-[part]-[label].mov`** | **`1-1-intro.mov`** ✅ |
| Project Structure | `/project/recordings/` | `/a27-my-video/recordings/` |

### Workflow Integration

```
Ecamm Live Recording
      ↓
[automatic save with date/time name]
      ↓
VideoFileNamer
[generate: 1-1-intro.mov]
      ↓
Manual Rename
[1-1-intro.mov on file system]
      ↓
FliVideo Project
[organized in recordings/ folder]
      ↓
Transcription & Processing
[FliVideo handles this automatically]
```

---

## 🚀 Quick Start

### Access the App

1. Open Replit project: **VideoFileNamer (4)**
2. Start development server: `npm run dev`
3. Navigate to: `http://localhost:5000`

### Basic Usage

1. **First segment**:
   - Label field shows empty, type "intro"
   - Filename generates: `1-1-intro.mov`
   - Click copy or enable auto-clipboard

2. **Second attempt at intro**:
   - Click "Next Part"
   - Filename generates: `1-2-intro.mov`
   - Label preserved automatically

3. **Move to next chapter**:
   - Click "Next Chapter"
   - System prompts for new chapter name: "content"
   - Filename generates: `2-1-content.mov`

### Common Actions

| Action | Steps |
|--------|-------|
| Copy filename | Click copy button OR enable auto-clipboard |
| Add video segment | Click "Next Part" (same chapter) |
| Start new chapter | Click "Next Chapter" (reset part) |
| Undo/Delete row | Click delete button on row |
| Clear everything | Click "Clear All" button |

---

## 🔧 Troubleshooting

### Application Won't Start

```bash
# Check if port is in use
lsof -i :5000

# Kill existing process
pkill -f "node|tsx"

# Start fresh
npm run dev
```

### Typing Lag

- Debouncing is set to 1 second
- Short delay is normal while API processes
- Should feel responsive after debouncing implementation
- Check browser console (F12) for errors

### Filenames Not Saving

- Check ReplDB connection status
- Verify metadata fields are not empty
- Check browser console for database errors
- Try refreshing page and re-entering data

### Clipboard Copy Failed

- Some browsers restrict clipboard access
- Try using the copy button instead of auto-clipboard
- Or manually select and copy the filename text
- Check browser console for permission errors

---

## 📦 Feature Checklist

- ✅ Automatic filename generation
- ✅ Real-time filename preview
- ✅ Chapter/part smart increment buttons
- ✅ Label preservation on next part
- ✅ Optional metadata support
- ✅ Clipboard copy (manual)
- ✅ Auto-clipboard option with debouncing
- ✅ ReplDB persistence
- ✅ Comprehensive logging
- ✅ Error handling and validation
- ✅ User-friendly UI with table layout
- ✅ Responsive design

---

## 📖 Related Documentation

- **[FliVideo Naming Conventions](../../../architecture/dam/dam-vision.md)** - Project/episode/segment naming standards
- **[FliVideo Overview](../../../../../../flivideo/docs/fli-video.md)** - Complete VAM system
- **[DAM (Digital Asset Management)](./dam/)** - Video project organization

---

**Last Updated**: 2025-11-25
**Status**: Active
**Platform**: Replit (Web-based)
