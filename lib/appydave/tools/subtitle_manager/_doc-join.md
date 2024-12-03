
# Detailed Requirements Specification

## Command-Line Tool

### Purpose
A CLI tool named `Join` for merging multiple SRT files into one cohesive subtitle file, handling timestamp adjustment and preserving subtitle integrity.

---

### Parameters

1. **`--folder <path>`**
   - **Purpose**: Specifies the folder containing SRT files.  
   - **Default**: Current working directory (`./`).  
   - **Example**: `--folder /path/to/subtitles`.

2. **`--files <pattern>`**
   - **Purpose**: Specifies specific filenames or wildcard patterns for SRT files to process.  
   - **Default**: `*.srt` (processes all SRT files in the folder).  
   - **Logic**:  
     - Explicit filenames: `file1.srt file2.srt` → Process in provided order.  
     - Wildcard patterns: `*.srt` → Resolve matching files, sort by `--sort` order.

3. **`--sort <inferred|asc|desc>`**
   - **Purpose**: Defines how files are ordered for processing.  
   - **Default**: `inferred`  
   - **Logic**:  
     - `inferred`:  
       - Explicit filenames → Preserve order.  
       - Wildcards → Sort alphabetically (ascending).  
     - `asc`: Force alphabetical order.  
     - `desc`: Force reverse alphabetical order.

4. **`--buffer <milliseconds>`**
   - **Purpose**: Adds a buffer between the last subtitle of one file and the first subtitle of the next.  
   - **Default**: `100` (100ms).  
   - **Example**: `--buffer 50` for a 50ms gap.

5. **`--output <output_file.srt>`**
   - **Purpose**: Specifies the name of the output merged SRT file.  
   - **Default**: `merged.srt` in the current folder.  
   - **Example**: `--output /path/to/final_output.srt`.

6. **`--verbose`**
   - **Purpose**: Enables detailed logging for steps like file resolution, timestamp adjustments, and warnings for skipped files.

---

## Primary Component Logic

### Design Overview
The tool should adhere to **Single Responsibility Principle (SRP)**, favor **composition**, and nest the composed components within the `Join` class for encapsulation and reusability.

### Primary Class: `Join`
The `Join` class acts as the main entry point and coordinates the workflow. It contains the following nested components:

1. **`FileResolver`**
   - **Responsibility**: Handles file resolution (folder, filenames, wildcards, sorting).
   - **Logic**:  
     - Resolve files based on `--files` or `--folder`.  
     - Apply sorting rules (`inferred`, `asc`, `desc`).  

2. **`SRTParser`**
   - **Responsibility**: Parses SRT files into structured subtitle objects.
   - **Logic**:  
     - Read and validate SRT content.  
     - Split into subtitle blocks (index, start time, end time, text).  
     - Convert timestamps into structured objects (seconds for calculations).  

3. **`SRTMerger`**
   - **Responsibility**: Combines subtitles, adjusts timestamps, and applies buffers.
   - **Logic**:  
     - Aggregate parsed subtitles from multiple files.  
     - Adjust timestamps for non-overlapping entries using the buffer.  

4. **`SRTWriter`**
   - **Responsibility**: Converts subtitle objects back to SRT format and writes to disk.
   - **Logic**:  
     - Reformat subtitles with proper numbering and timestamp formatting.  
     - Write the final merged content to the specified output file.

---

### Main Workflow

1. **Parse Arguments**
   - Validate input parameters and resolve defaults.

2. **Resolve Files**
   - Use `FileResolver` to identify files based on folder, filenames, or wildcard patterns.

3. **Parse Files**
   - Use `SRTParser` to parse each file into a list of structured subtitle objects.

4. **Merge Files**
   - Use `SRTMerger` to combine subtitles, sort by start time (per file order), and apply timestamp adjustments.

5. **Write Output**
   - Use `SRTWriter` to generate the final SRT file and save it to the specified location.

---

## Business Rules

1. **File Selection**
   - Resolve wildcards to file lists dynamically.  
   - Validate file existence and skip invalid or non-SRT files with appropriate warnings.

2. **Timestamp Handling**
   - Ensure non-overlapping subtitles across files by applying the buffer.  
   - Maintain relative timing within each file.

3. **Sorting Logic**
   - Preserve file order for explicit filenames.  
   - Apply alphabetical sorting for wildcards unless overridden by `--sort`.

4. **Error Handling**
   - Log and skip malformed SRT files.  
   - Notify users of missing files or unsupported patterns.

5. **Output Consistency**
   - Re-number subtitles sequentially in the final output.  
   - Ensure proper formatting with three decimal places for milliseconds.

---

## Tests

### Unit Tests

1. **FileResolver Tests**
   - Resolve explicit filenames.
   - Resolve wildcard patterns (`*.srt`) and sort files.
   - Handle missing or invalid files gracefully.

2. **SRTParser Tests**
   - Parse valid SRT files into structured objects.
   - Detect and handle malformed SRT files.
   - Validate timestamp formatting.

3. **SRTMerger Tests**
   - Combine subtitles from two or more files.
   - Ensure timestamps are adjusted with the buffer.
   - Handle edge cases like overlapping timestamps or missing buffer.

4. **SRTWriter Tests**
   - Convert subtitle objects to valid SRT format.
   - Ensure proper numbering and formatting (e.g., three decimal places).

---

### Integration Tests

1. Process a folder of SRT files and produce a merged output.  
2. Validate behavior with explicit filenames and wildcards.  
3. Verify handling of buffers for different values (`0ms`, `50ms`, etc.).  
4. Test edge cases like empty files, malformed SRTs, or mixed valid/invalid files.

---

### End-to-End Tests

1. Run the tool with minimal arguments and verify the output.  
2. Test all parameter combinations (`--folder`, `--files`, `--sort`, `--buffer`, etc.).  
3. Compare merged output against manually validated reference files.
