# Subtitle Master

Older Chat
- https://chatgpt.com/c/f80dfca5-8168-4561-b5c6-8efed8672a88

New Features
- https://chatgpt.com/c/670470b8-a0c4-8002-9678-d4d69c680481

## SubtitleMaster - Clean Component

The `SubtitleMaster::Clean` component is designed to process subtitle (SRT) files to improve their readability and compatibility with various platforms like YouTube. The main functionalities of this component include:

- **Removing HTML Tags**: Strips out unnecessary HTML underline tags (`<u>` and `</u>`) that may be present in the subtitle content.
- **Normalizing Subtitle Lines**: Merges fragmented subtitle lines into coherent sentences. It adjusts the timestamps to ensure that each subtitle entry spans the correct duration, combining lines that were incorrectly split by the subtitle creation software.
- **Handling Timestamps**: Updates the end timestamp of each merged subtitle to reflect the actual end time of the last occurrence of the text, ensuring accurate timing for each subtitle entry.

### Usage

The component can be initialized in two ways:

1. With a file path (typical for CLI usage):
```ruby
cleaner = SubtitleMaster::Clean.new(file_path: 'path/to/file.srt')
```

2. With direct SRT content (useful for programmatic usage):
```ruby
cleaner = SubtitleMaster::Clean.new(srt_content: srt_content_string)
```

### Command Line Usage

```bash
./bin/subtitle_manager.rb clean -f path/to/example.srt -o path/to/example_cleaned.srt

# Example using alias
ad_subtitle_manager clean -f transcript/a45-banned-from-midjourney-16-alternatives.srt -o a45-transcript.srt
```

This component reads the SRT file, processes the content to remove tags and normalize lines, and outputs a cleaned and formatted subtitle file that is easier to read and upload to platforms.
