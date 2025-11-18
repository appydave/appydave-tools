# Move Images

Organize and rename downloaded images for use in video projects with section-based folder structure.

## What It Does

**Move Images** organizes image assets for video production:

- Moves downloaded images from smart-downloads to project folders
- Renames images with section-based prefixes for organization
- Creates nested folder structure automatically (assets/section/)
- Indexes images sequentially for easy reference
- Maintains asset library organization for video projects

## How to Use

### Basic Usage

```bash
move_images -f <folder> <section> <prefix>
```

**Parameters**:
- `-f` / `--folder`: Video project folder (e.g., `appydave-b60`)
- `section`: Asset category (e.g., `intro`, `content`, `outro`)
- `prefix`: Image name prefix (e.g., `city`)

### Example

```bash
# Move downloaded images for AppyDave video 60, intro section
move_images -f appydave-b60 intro city

# Result:
# ~/Sync/smart-downloads/download-images/image-001.jpg →
# /Volumes/Expansion/Sync/tube-channels/video-projects/appydave-b60/assets/intro/city-intro-1.jpg
#
# ~/Sync/smart-downloads/download-images/image-002.jpg →
# /Volumes/Expansion/Sync/tube-channels/video-projects/appydave-b60/assets/intro/city-intro-2.jpg
```

### Multiple Sections

```bash
# Organize intro images
move_images -f video-project intro opening

# Later, organize content images
move_images -f video-project content landscape

# Later, organize outro images
move_images -f video-project outro closing

# Result folder structure:
# video-project/assets/
# ├── intro/
# │   ├── opening-intro-1.jpg
# │   ├── opening-intro-2.jpg
# │   └── ...
# ├── content/
# │   ├── landscape-content-1.jpg
# │   ├── landscape-content-2.jpg
# │   └── ...
# └── outro/
#     ├── closing-outro-1.jpg
#     ├── closing-outro-2.jpg
#     └── ...
```

## Directory Structure

### Source Structure
```
~/Sync/smart-downloads/download-images/
├── image-001.jpg
├── image-002.jpg
├── image-003.jpg
└── ... (downloaded from web, browser auto-saves)
```

### Destination Structure
```
/Volumes/Expansion/Sync/tube-channels/video-projects/
└── {project-name}/
    └── assets/
        ├── intro/
        │   ├── {prefix}-intro-1.jpg
        │   └── {prefix}-intro-2.jpg
        ├── content/
        │   ├── {prefix}-content-1.jpg
        │   └── {prefix}-content-2.jpg
        └── outro/
            ├── {prefix}-outro-1.jpg
            └── {prefix}-outro-2.jpg
```

## Use Cases for AI Agents

### 1. Bulk Asset Organization
```bash
# AI orchestrates: Download → Move → Organize
# For multiple images across multiple sections
for image_set in intro content outro transition; do
  move_images -f project-name "$image_set" "prefix-for-$image_set"
done
```
**AI discovers**: Asset organization workflow, section patterns. Can systematically organize image libraries.

### 2. Asset Library Maintenance
```bash
# AI reviews asset structure
# Ensures all sections are properly organized
# Identifies orphaned or misplaced images
```
**AI discovers**: Current asset state, what's organized/disorganized. Can clean up asset libraries.

### 3. Video Production Workflow
```bash
# Part of larger workflow:
# 1. Search/download images (browser smart-download)
# 2. Move images to project (move_images)
# 3. Reference in video editing (from assets folder)
# 4. FliVideo imports from assets
```
**AI discovers**: Image integration into video pipeline. Can automate asset management in video workflows.

### 4. Multi-Section Asset Management
```bash
# Complex video with many sections
# AI orchestrates moving images for each section
# Ensures proper folder structure throughout
```
**AI discovers**: Project complexity, section organization. Can manage multi-part asset structures.

### 5. Asset Inventory
```bash
# After moving images, create inventory
# Count assets per section
# Generate asset report for video editor
```
**AI discovers**: What assets are available for each section. Can provide asset inventory for planning.

### 6. Naming Convention Enforcement
```bash
# Ensure consistent naming:
# {prefix}-{section}-{number}.jpg
# AI validates moved files follow pattern
```
**AI discovers**: Naming scheme, consistency. Can enforce standard naming across projects.

### 7. Batch Project Setup
```bash
# Set up image assets for multiple projects
# Each project: multiple sections with different image sets
# AI coordinates: move_images for each section
```
**AI discovers**: Project requirements, multi-section needs. Can batch-organize multiple projects.

### 8. Asset Deduplication
```bash
# Before moving, check if images already exist
# Avoid duplicate assets in project
# AI coordinates smart deduplication
```
**AI discovers**: Existing assets, duplicates. Can prevent redundant downloads/moves.

### 9. Workflow Validation
```bash
# After moving, verify:
# - All images in correct folders
# - Naming follows convention
# - No images left in download folder
# - Asset count matches expectation
```
**AI discovers**: Workflow correctness. Can validate asset organization integrity.

### 10. Asset Tracking & Metadata
```bash
# Track which images went where
# Create manifest of assets per section
# Link images to video timeline positions
```
**AI discovers**: Asset-to-content mapping. Can create detailed asset metadata for video production.

## Command Reference

### Move Images
```bash
move_images -f <folder> <section> <prefix>
```

| Parameter | Description |
|-----------|-------------|
| `-f FOLDER` / `--folder FOLDER` | Video project folder name (required) |
| `section` | Asset category: intro, content, outro, transition, thumb, teaser, etc. |
| `prefix` | Image name prefix for organization (e.g., "city", "beach", "nature") |

### Supported Sections (Common)

- `intro` - Introduction/opening images
- `content` - Main content images
- `outro` - Closing/ending images
- `transition` - Between-section transition images
- `thumb` - Thumbnail candidate images
- `teaser` - Teaser/preview images
- Custom sections allowed (any string)

## Folder Paths

### Configuration
- **Base directory**: `/Volumes/Expansion/Sync/tube-channels/video-projects`
- **Source folder**: `~/Sync/smart-downloads/download-images/`
- **Destination**: `{base}/{project}/assets/{section}/`

## Image Naming Convention

Generated filename format:
```
{prefix}-{section}-{number}.jpg
```

Examples:
- `city-intro-1.jpg`
- `city-intro-2.jpg`
- `landscape-content-1.jpg`
- `beach-outro-1.jpg`

## Workflow Integration

Typical video production workflow:

```
1. Research & Download (Browser → smart-downloads)
2. Move & Organize (move_images tool)
3. Reference in Planning (asset folders organized by section)
4. Video Editing (editor selects from assets/{section}/)
5. FliVideo (can reference assets from organized structure)
6. Publish (video with organized asset trail)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Folder doesn't exist" | Create project folder first in video-projects/ |
| "No images found" | Verify images exist in ~/Sync/smart-downloads/download-images/ |
| "Permission denied" | Check folder permissions, verify external drive is mounted |
| "Images not moved" | Check source folder path, verify .jpg extension |

## Tips & Tricks

1. **Use descriptive prefixes**: "city-skyline" is better than "img"
2. **Process in order**: intro → content → outro
3. **Batch similar images**: Download all for one section, move them together
4. **Check results**: Verify folder structure matches expectation
5. **Multiple images**: First move, then use for reference in video editing

## Example Workflow

```bash
# Step 1: Download images (using browser, auto-saves to smart-downloads)
# Images saved as image-001.jpg, image-002.jpg, etc.

# Step 2: Organize for intro
move_images -f appydave-b60 intro "opening-scene"

# Step 3: Download more images, organize for content
move_images -f appydave-b60 content "landscape"

# Step 4: Download final images, organize for outro
move_images -f appydave-b60 outro "sunset"

# Result:
# appydave-b60/assets/
# ├── intro/
# │   ├── opening-scene-intro-1.jpg
# │   ├── opening-scene-intro-2.jpg
# │   └── opening-scene-intro-3.jpg
# ├── content/
# │   ├── landscape-content-1.jpg
# │   ├── landscape-content-2.jpg
# │   └── landscape-content-3.jpg
# └── outro/
#     ├── sunset-outro-1.jpg
#     └── sunset-outro-2.jpg
```

---

**Related Tools**:
- `configuration` - Project folder setup
- FliVideo - Uses organized assets in video production
- Video editing software - Selects images from organized assets

**Integration**: Part of AppyDave video production pipeline
