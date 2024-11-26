**Use Cases for Subtitle Management Tool (SRT-manage)**

### Table of Contents
1. [Join Multiple SRT Files](#1-join-multiple-srt-files)
2. [Insert SRT at the Beginning of a Video](#2-insert-srt-at-the-beginning-of-a-video)
3. [Insert SRT in the Middle of a Video](#3-insert-srt-in-the-middle-of-a-video)
4. [Shift Timestamps](#4-shift-timestamps)
5. [Find Timestamp by Text](#5-find-timestamp-by-text)
6. [Find Timestamp by Approximate Time](#6-find-timestamp-by-approximate-time)
7. [Extract Video Length](#7-extract-video-length)
8. [Dry-Run (Optional)](#8-dry-run-optional)

---

### 1. Join Multiple SRT Files
**Use case:** This action joins multiple subtitle files (SRT files), where each subsequent file is appended to the end of the previous one. The timestamps of each additional file are adjusted to start after the previous files finish.

**Command:**
```
SRT-manage join -srt movie_part1.srt movie_part2.srt movie_part3.srt -output combined.srt -source-folder ./
```
**Arguments:**
- **-srt** `<file1> <file2> ... <fileN>`: List of SRT files to join, provided in sequence.
- **-output** `<file>`: Path for the output combined SRT file.
- **-source-folder** `<folder>`: (Optional) Path to the folder containing SRT files. Defaults to `./` (current directory).

### 2. Insert SRT at the Beginning of a Video
**Use case:** Insert an SRT file at the very beginning of another video’s subtitle timeline. For example, if you want to add an intro/teaser subtitles before the main video.

**Command:**
```
SRT-manage insert-beginning -srt main_video.srt -insert intro.srt -output final.srt
```
**Arguments:**
- **-srt** `<file>`: Path to the main video SRT file.
- **-insert** `<file>`: Path to the SRT file to be inserted at the beginning.
- **-output** `<file>`: Path for the final output file.

### 3. Insert SRT in the Middle of a Video
**Use case:** Insert one SRT file at a specific point in another video’s timeline. For example, adding a call-to-action or an advertisement’s subtitles in the middle of a main video.

**Command:**
```
SRT-manage insert-middle -srt main_video.srt -insert ad.srt -timecode 00:10:00 -output final.srt
```
**Arguments:**
- **-srt** `<file>`: Path to the main video SRT file.
- **-insert** `<file>`: Path to the SRT file to be inserted in the middle.
- **-timecode** `<HH:MM:SS>`: The time in the video where the insertion should happen.
- **-output** `<file>`: Path for the final output file.

### 4. Shift Timestamps
**Use case:** Adjust the timestamps of all subtitles in an SRT file by a certain offset, useful when a video has been edited or when subtitles need to be delayed or advanced.

**Command:**
```
SRT-manage shift -srt main_video.srt -offset 30 -output shifted_video.srt
```
**Arguments:**
- **-srt** `<file>`: Path to the SRT file.
- **-offset** `<time_in_sec>`: Time in seconds to shift (positive or negative).
- **-output** `<file>`: Path for the adjusted output file.

### 5. Find Timestamp by Text
**Use case:** Search the subtitle file for a specific phrase and return the closest matching timestamp. Useful when trying to locate where a certain line is spoken in the video.

**Command:**
```
SRT-manage find-text -srt movie.srt -text "the quick brown fox"
```
**Arguments:**
- **-srt** `<file>`: Path to the SRT file.
- **-text** `"<phrase>"`: The phrase to search for in the subtitle text.

### 6. Find Timestamp by Approximate Time
**Use case:** Given a rough timecode, the system returns the closest matching subtitle timestamp. This helps find where subtitles start or stop near the provided time.

**Command:**
```
SRT-manage find-time -srt movie.srt -timecode 00:10:00
```
**Arguments:**
- **-srt** `<file>`: Path to the SRT file.
- **-timecode** `<HH:MM:SS>`: The approximate time to search for.

### 7. Extract Video Length
**Use case:** Extract the total duration of a video file, which can then be used for timing calculations when adjusting or syncing SRT files.

**Command:**
```
SRT-manage video-length -video movie.mov
```
**Arguments:**
- **-video** `<file>`: Path to the video file.

### 8. Dry-Run (Optional)
**Use case:** Preview changes without actually writing the file. This can be used with any of the above actions to test changes before committing them.

**Example (with shift action):**
```
SRT-manage shift -srt movie.srt -offset 15 -dry-run
```
**Argument:**
- **-dry-run**: Show changes without applying them.

---

### **Summary of Example Use Cases:**
1. **Join multiple SRT files:** Joining multiple parts of a movie's subtitles into one file.
2. **Insert SRT at the beginning:** Adding intro subtitles before a movie starts.
3. **Insert SRT in the middle:** Inserting an ad’s subtitles at a specific time in the video.
4. **Shift timestamps:** Delaying subtitles by 30 seconds after a video has been edited.
5. **Find timestamp by text:** Finding where the phrase “the quick brown fox” is spoken.
6. **Find timestamp by timecode:** Locating the subtitle closest to 00:10:00.
7. **Extract video length:** Getting the duration of a video for further calculations.

---

Does this structure work better for you? Each use case now has a clear description followed by a realistic command example and an explanation of the arguments. Let me know if any tweaks are needed!

