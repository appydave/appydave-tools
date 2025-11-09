# CLI Architecture Patterns

This guide documents the established CLI architecture patterns used in appydave-tools, providing developers with clear guidance on how to structure new tools and integrate them following existing conventions.

## Table of Contents

- [Overview](#overview)
- [Philosophy](#philosophy)
- [The Three Patterns](#the-three-patterns)
  - [Pattern 1: Single-Command Tools](#pattern-1-single-command-tools)
  - [Pattern 2: Multi-Command with Inline Routing](#pattern-2-multi-command-with-inline-routing)
  - [Pattern 3: Multi-Command with BaseAction](#pattern-3-multi-command-with-baseaction)
- [Decision Tree](#decision-tree)
- [Directory Structure](#directory-structure)
- [Best Practices](#best-practices)
- [Testing Approach](#testing-approach)
- [Migration Guide](#migration-guide)
- [Examples](#examples)

---

## Overview

AppyDave Tools follows a **consolidated toolkit philosophy** - multiple independent tools in one repository for easier maintenance than separate codebases. Each tool is designed to be:

- **Single-purpose**: Solves one specific problem independently
- **Shareable**: Can be featured in standalone videos/tutorials
- **Maintainable**: Clear separation of concerns between CLI and business logic
- **Testable**: Business logic separated from CLI interface

The architecture supports three distinct patterns, each suited for different tool complexity levels.

---

## Philosophy

### Separation of Concerns

```
bin/
├── tool_name.rb          ← CLI interface (OptionParser, argument routing)
lib/appydave/tools/
├── tool_name/
│   ├── business_logic.rb ← Core functionality (pure Ruby, no CLI dependencies)
```

**Key Principles:**
1. **CLI layer** (`bin/`) handles argument parsing, user interaction, help messages
2. **Business logic layer** (`lib/`) contains pure Ruby classes with no CLI dependencies
3. **No CLI code in lib/** - business logic should be usable programmatically
4. **No business logic in bin/** - executables should be thin wrappers

### Module Organization

All business logic lives under the `Appydave::Tools::` namespace:

```ruby
module Appydave
  module Tools
    module ToolName
      class BusinessLogic
        # Pure Ruby implementation
      end
    end
  end
end
```

---

## The Three Patterns

### Pattern 1: Single-Command Tools

**Use when:** The tool performs ONE operation with various options.

**Example:** `gpt_context.rb` - Gathers files for AI context

#### Structure

```
bin/
├── gpt_context.rb              # Executable CLI
lib/appydave/tools/
├── gpt_context/
│   ├── options.rb              # Options struct/class
│   ├── file_collector.rb       # Core business logic
│   ├── output_handler.rb       # Output processing
│   └── _doc.md                 # Documentation
```

#### Implementation Pattern

**bin/gpt_context.rb:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

# 1. Define options object
options = Appydave::Tools::GptContext::Options.new(
  working_directory: nil
)

# 2. Parse command-line arguments
OptionParser.new do |opts|
  opts.banner = 'Usage: gpt_context.rb [options]'

  opts.on('-i', '--include PATTERN', 'Pattern to include') do |pattern|
    options.include_patterns << pattern
  end

  opts.on('-e', '--exclude PATTERN', 'Pattern to exclude') do |pattern|
    options.exclude_patterns << pattern
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

# 3. Validate and set defaults
if options.include_patterns.empty?
  puts 'No options provided. Please specify patterns to include.'
  exit
end

options.working_directory ||= Dir.pwd

# 4. Execute business logic
gatherer = Appydave::Tools::GptContext::FileCollector.new(options)
content = gatherer.build

output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute
```

**lib/appydave/tools/gpt_context/options.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module GptContext
      Options = Struct.new(
        :include_patterns,
        :exclude_patterns,
        :format,
        :working_directory,
        keyword_init: true
      ) do
        def initialize(**args)
          super
          self.include_patterns ||= []
          self.exclude_patterns ||= []
          self.format ||= 'tree,content'
        end
      end
    end
  end
end
```

**lib/appydave/tools/gpt_context/file_collector.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module GptContext
      class FileCollector
        def initialize(options)
          @options = options
          @include_patterns = options.include_patterns
          @exclude_patterns = options.exclude_patterns
          @working_directory = File.expand_path(options.working_directory)
        end

        def build
          FileUtils.cd(@working_directory) if Dir.exist?(@working_directory)

          # Business logic here - no CLI dependencies
          content = build_content

          FileUtils.cd(Dir.home)
          content
        end

        private

        def build_content
          # Pure Ruby implementation
        end
      end
    end
  end
end
```

**Characteristics:**
- ✅ Simple, linear execution flow
- ✅ All options defined upfront in one OptionParser block
- ✅ Single business logic entry point
- ✅ Minimal routing logic
- ❌ Not suitable for multiple distinct operations

---

### Pattern 2: Multi-Command with Inline Routing

**Use when:** The tool has 2-5 related commands with simple routing needs.

**Example:** `subtitle_processor.rb` - Clean and join SRT files

#### Structure

```
bin/
├── subtitle_processor.rb       # Executable with command routing
lib/appydave/tools/
├── subtitle_processor/
│   ├── clean.rb                # Command implementation
│   ├── join.rb                 # Command implementation
│   ├── _doc-clean.md           # Per-command documentation
│   └── _doc-join.md
```

#### Implementation Pattern

**bin/subtitle_processor.rb:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

# CLI class with inline command routing
class SubtitleProcessorCLI
  def initialize
    # Map commands to methods (inline routing)
    @commands = {
      'clean' => method(:clean_subtitles),
      'join' => method(:join_subtitles)
    }
  end

  def run
    command, *args = ARGV

    if command.nil?
      puts 'No command provided. Use -h for help.'
      print_help
      exit
    end

    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  # Command-specific method with dedicated OptionParser
  def clean_subtitles(args)
    options = { file: nil, output: nil }

    clean_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor.rb clean [options]'

      opts.on('-f', '--file FILE', 'SRT file to process') do |v|
        options[:file] = v
      end

      opts.on('-o', '--output FILE', 'Output file') do |v|
        options[:output] = v
      end

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    begin
      clean_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}"
      puts clean_parser
      exit
    end

    # Validate required options
    if options[:file].nil? || options[:output].nil?
      puts 'Error: Missing required options.'
      puts clean_parser
      exit
    end

    # Execute business logic
    cleaner = Appydave::Tools::SubtitleProcessor::Clean.new(file_path: options[:file])
    cleaner.clean
    cleaner.write(options[:output])
  end

  def join_subtitles(args)
    options = {
      folder: './',
      files: '*.srt',
      sort: 'inferred',
      buffer: 100,
      output: 'merged.srt'
    }

    join_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor.rb join [options]'

      opts.on('-d', '--directory DIR', 'Directory containing SRT files') do |v|
        options[:folder] = v
      end

      opts.on('-f', '--files PATTERN', 'File pattern') do |v|
        options[:files] = v
      end

      opts.on('-o', '--output FILE', 'Output file') do |v|
        options[:output] = v
      end

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    begin
      join_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}"
      puts join_parser
      exit
    end

    # Execute business logic
    joiner = Appydave::Tools::SubtitleProcessor::Join.new(
      folder: options[:folder],
      files: options[:files],
      sort: options[:sort],
      buffer: options[:buffer],
      output: options[:output]
    )
    joiner.join
  end

  def print_help
    puts 'Usage: subtitle_processor.rb [command] [options]'
    puts 'Commands:'
    puts '  clean          Clean and normalize SRT files'
    puts '  join           Join multiple SRT files'
    puts "Run 'subtitle_processor.rb [command] --help' for more information."
  end
end

SubtitleProcessorCLI.new.run
```

**lib/appydave/tools/subtitle_processor/clean.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleProcessor
      # Clean and normalize subtitles
      class Clean
        attr_reader :content

        def initialize(file_path: nil, srt_content: nil)
          if file_path && srt_content
            raise ArgumentError, 'Cannot provide both file path and content.'
          elsif file_path.nil? && srt_content.nil?
            raise ArgumentError, 'Must provide either file path or content.'
          end

          @content = file_path ? File.read(file_path, encoding: 'UTF-8') : srt_content
        end

        def clean
          content = remove_underscores(@content)
          normalize_lines(content)
        end

        def write(output_file)
          File.write(output_file, content)
          puts "Processed file written to #{output_file}"
        rescue StandardError => e
          puts "Error writing file: #{e.message}"
        end

        private

        def remove_underscores(content)
          content.gsub(%r{</?u>}, '')
        end

        def normalize_lines(content)
          # Business logic - no CLI dependencies
        end
      end
    end
  end
end
```

**lib/appydave/tools/subtitle_processor/join.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module SubtitleProcessor
      # Join multiple SRT files into one
      class Join
        def initialize(folder: './', files: '*.srt', sort: 'inferred', buffer: 100, output: 'merged.srt')
          @folder = folder
          @files = files
          @sort = sort
          @buffer = buffer
          @output = output
        end

        def join
          resolved_files = resolve_files
          subtitle_groups = parse_files(resolved_files)
          merged_subtitles = merge_subtitles(subtitle_groups)
          write_output(merged_subtitles)
        end

        private

        # Business logic - pure Ruby implementation
      end
    end
  end
end
```

**Characteristics:**
- ✅ Handles 2-5 related commands efficiently
- ✅ Each command has dedicated OptionParser with command-specific options
- ✅ Inline routing keeps everything in one file (easier to understand)
- ✅ Command methods keep CLI and business logic separated
- ❌ Can become cluttered with 6+ commands
- ❌ No shared validation/execution patterns

---

### Pattern 3: Multi-Command with BaseAction

**Use when:** The tool has multiple commands that share validation/execution patterns.

**Example:** `youtube_manager.rb` - Get and update YouTube videos

#### Structure

```
bin/
├── youtube_manager.rb          # Executable with BaseAction routing
lib/appydave/tools/
├── cli_actions/
│   ├── base_action.rb          # Abstract base class
│   ├── get_video_action.rb     # Command implementation
│   └── update_video_action.rb  # Command implementation
├── youtube_manager/
│   ├── authorization.rb        # Shared business logic
│   ├── get_video.rb            # Core functionality
│   └── update_video.rb
```

#### Implementation Pattern

**lib/appydave/tools/cli_actions/base_action.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      # Base class for CLI actions
      class BaseAction
        # Entry point called by bin/ executable
        def action(args)
          options = parse_options(args)
          execute(options)
        end

        protected

        # Template method - parse with standard pattern
        def parse_options(args)
          options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage: #{command_usage}"

            define_options(opts, options)

            opts.on_tail('-h', '--help', 'Show this message') do
              puts opts
              exit
            end
          end.parse!(args)

          validate_options(options)
          options
        end

        # Hook: Define command usage string
        def command_usage
          "#{self.class.name.split('::').last.downcase} [options]"
        end

        # Hook: Subclass defines command-specific options
        def define_options(opts, options)
          # To be implemented by subclasses
        end

        # Hook: Subclass validates required options
        def validate_options(options)
          # To be implemented by subclasses
        end

        # Hook: Subclass executes business logic
        def execute(options)
          # To be implemented by subclasses
        end
      end
    end
  end
end
```

**lib/appydave/tools/cli_actions/get_video_action.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      # CLI Action to get a YouTube video details
      class GetVideoAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }
        end

        def validate_options(options)
          return if options[:video_id]

          puts 'Missing required options: --video-id. Use -h for help.'
          exit
        end

        def execute(options)
          get_video = Appydave::Tools::YouTubeManager::GetVideo.new
          get_video.get(options[:video_id])

          if get_video.video?
            report = Appydave::Tools::YouTubeManager::Reports::VideoDetailsReport.new
            report.print(get_video.data)
          else
            puts "Video not found! Maybe it's private or deleted. ID: #{options[:video_id]}"
          end
        end
      end
    end
  end
end
```

**lib/appydave/tools/cli_actions/update_video_action.rb:**
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      # Action to update a YouTube video metadata
      class UpdateVideoAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }
          opts.on('-t', '--title TITLE', 'Video Title') { |t| options[:title] = t }
          opts.on('-d', '--description DESCRIPTION', 'Video Description') { |d| options[:description] = d }
          opts.on('-g', '--tags TAGS', 'Video Tags (comma-separated)') { |g| options[:tags] = g.split(',') }
          opts.on('-c', '--category-id CATEGORY_ID', 'Video Category ID') { |c| options[:category_id] = c }
        end

        def validate_options(options)
          return if options[:video_id]

          puts 'Missing required options: --video-id. Use -h for help.'
          exit
        end

        def execute(options)
          get_video = Appydave::Tools::YouTubeManager::GetVideo.new
          get_video.get(options[:video_id])

          if get_video.video?
            update_video = Appydave::Tools::YouTubeManager::UpdateVideo.new(get_video.data)

            update_video.title(options[:title]) if options[:title]
            update_video.description(options[:description]) if options[:description]
            update_video.tags(options[:tags]) if options[:tags]
            update_video.category_id(options[:category_id]) if options[:category_id]

            update_video.save
            puts "Video updated successfully. ID: #{options[:video_id]}"
          else
            puts "Video not found! ID: #{options[:video_id]}"
          end
        end
      end
    end
  end
end
```

**bin/youtube_manager.rb:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

# CLI with BaseAction routing
class YouTubeVideoManagerCLI
  include KLog::Logging

  def initialize
    # Map commands to action classes
    @commands = {
      'get' => Appydave::Tools::CliActions::GetVideoAction.new,
      'update' => Appydave::Tools::CliActions::UpdateVideoAction.new
    }
  end

  def run
    command, *args = ARGV

    if @commands.key?(command)
      @commands[command].action(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def print_help
    puts 'Usage: youtube_manager.rb [command] [options]'
    puts 'Commands:'
    puts '  get    Get details for a YouTube video'
    puts '  update Update details for a YouTube video'
    puts "Run 'youtube_manager.rb [command] --help' for more information."
  end
end

YouTubeVideoManagerCLI.new.run
```

**Characteristics:**
- ✅ Scales well to 6+ commands
- ✅ Enforces consistent patterns across commands (template method)
- ✅ Shared validation and execution flow
- ✅ Easy to add new commands (create new Action subclass)
- ✅ Testable action classes (can test independently)
- ❌ More complex than inline routing for simple tools
- ❌ Requires understanding template method pattern

---

## Decision Tree

Use this flowchart to choose the right pattern:

```
Start: How many distinct operations does your tool perform?

├─ One operation (with various options)
│  └─ Pattern 1: Single-Command Tool
│     Examples: gpt_context, move_images
│
├─ 2-5 operations (simple, independent commands)
│  └─ Pattern 2: Multi-Command with Inline Routing
│     Examples: subtitle_processor, configuration
│
└─ 6+ operations OR commands share validation/execution patterns
   └─ Pattern 3: Multi-Command with BaseAction
      Examples: youtube_manager
```

**Additional Considerations:**

| Question | Pattern 1 | Pattern 2 | Pattern 3 |
|----------|-----------|-----------|-----------|
| Commands share business logic? | N/A | ❌ Duplicate code | ✅ Shared via base class |
| Tool might grow to 10+ commands? | ❌ Wrong pattern | ⚠️ Will need refactor | ✅ Scales well |
| Need programmatic API? | ✅ Yes | ✅ Yes | ✅ Yes |
| Commands have different option patterns? | N/A | ✅ Easy | ✅ Easy |
| Team familiar with OOP patterns? | ✅ Simple | ✅ Simple | ⚠️ Requires understanding |

---

## Directory Structure

### Pattern 1: Single-Command Tool

```
appydave-tools/
├── bin/
│   └── tool_name.rb                    # Executable
├── lib/appydave/tools/
│   └── tool_name/
│       ├── options.rb                  # Options struct/class
│       ├── main_logic.rb               # Core business logic
│       ├── supporting_class.rb         # Supporting functionality
│       └── _doc.md                     # Documentation
└── spec/appydave/tools/
    └── tool_name/
        ├── main_logic_spec.rb
        └── supporting_class_spec.rb
```

### Pattern 2: Multi-Command with Inline Routing

```
appydave-tools/
├── bin/
│   └── tool_name.rb                    # Executable with CLI class
├── lib/appydave/tools/
│   └── tool_name/
│       ├── command_one.rb              # Command implementation
│       ├── command_two.rb              # Command implementation
│       ├── _doc-command-one.md         # Per-command docs
│       └── _doc-command-two.md
└── spec/appydave/tools/
    └── tool_name/
        ├── command_one_spec.rb
        └── command_two_spec.rb
```

### Pattern 3: Multi-Command with BaseAction

```
appydave-tools/
├── bin/
│   └── tool_name.rb                    # Executable with routing
├── lib/appydave/tools/
│   ├── cli_actions/                    # Shared across tools
│   │   ├── base_action.rb              # Abstract base
│   │   ├── tool_command_one_action.rb  # Command implementation
│   │   └── tool_command_two_action.rb
│   └── tool_name/                      # Business logic
│       ├── service_one.rb
│       ├── service_two.rb
│       └── _doc.md
└── spec/appydave/tools/
    ├── cli_actions/
    │   ├── tool_command_one_action_spec.rb
    │   └── tool_command_two_action_spec.rb
    └── tool_name/
        ├── service_one_spec.rb
        └── service_two_spec.rb
```

---

## Best Practices

### Naming Conventions

#### Executables (`bin/`)
- Use **snake_case** for script names
- Match the gem command name when installed
- Examples: `gpt_context.rb`, `subtitle_processor.rb`, `youtube_manager.rb`

#### Modules (`lib/`)
- Use **PascalCase** for module/class names
- Match directory structure: `lib/appydave/tools/tool_name/` → `Appydave::Tools::ToolName`
- Examples: `GptContext`, `SubtitleProcessor`, `YouTubeManager`

#### Files
- Use **snake_case** for Ruby files
- Match class name: `file_collector.rb` → `class FileCollector`
- Prefix docs with underscore: `_doc.md`, `_doc-command.md`

### Code Organization

#### 1. Frozen String Literal
All Ruby files must start with:
```ruby
# frozen_string_literal: true
```

#### 2. Load Path Setup (bin/ only)
```ruby
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'
```

#### 3. Module Nesting
```ruby
module Appydave
  module Tools
    module ToolName
      class BusinessLogic
        # Implementation
      end
    end
  end
end
```

#### 4. Separation of Concerns

**✅ Good: Business logic independent of CLI**
```ruby
# lib/appydave/tools/tool_name/processor.rb
class Processor
  def initialize(file_path:, options: {})
    @file_path = file_path
    @options = options
  end

  def process
    # Pure Ruby - no CLI dependencies
  end
end

# bin/tool_name.rb
processor = Processor.new(file_path: options[:file], options: parsed_options)
processor.process
```

**❌ Bad: Business logic coupled to CLI**
```ruby
# lib/appydave/tools/tool_name/processor.rb
class Processor
  def process
    puts "Processing..."  # CLI output in business logic
    ARGV.each do |arg|    # Direct ARGV access
      # ...
    end
  end
end
```

#### 5. Error Handling

**In business logic:**
```ruby
def validate!
  raise ArgumentError, 'File path required' if file_path.nil?
  raise Errno::ENOENT, "File not found: #{file_path}" unless File.exist?(file_path)
end
```

**In CLI layer:**
```ruby
begin
  processor.process
rescue ArgumentError => e
  puts "Error: #{e.message}"
  exit 1
rescue Errno::ENOENT => e
  puts "File error: #{e.message}"
  exit 1
end
```

### OptionParser Patterns

#### Standard Help Option
```ruby
opts.on_tail('-h', '--help', 'Show this message') do
  puts opts
  exit
end
```

#### Required Options Validation
```ruby
def validate_options(options)
  missing = []
  missing << '--file' if options[:file].nil?
  missing << '--output' if options[:output].nil?

  return if missing.empty?

  puts "Missing required options: #{missing.join(', ')}"
  puts "Use -h for help."
  exit 1
end
```

#### Array Options (Multiple Values)
```ruby
opts.on('-i', '--include PATTERN', 'Pattern to include (can be used multiple times)') do |pattern|
  options[:include_patterns] << pattern
end
```

#### Enum Options (Fixed Choices)
```ruby
opts.on('-s', '--sort ORDER', %w[asc desc inferred], 'Sort order (asc/desc/inferred)') do |v|
  options[:sort] = v
end
```

#### Type Coercion
```ruby
opts.on('-b', '--buffer MS', Integer, 'Buffer in milliseconds') do |v|
  options[:buffer] = v
end
```

### Documentation

#### Per-Module Documentation
Create `_doc.md` files in each module directory:

```markdown
# ToolName Module

## Purpose
Brief description of what this module does.

## Classes
- `MainClass` - Primary functionality
- `SupportingClass` - Supporting functionality

## Usage
ruby
# Example code
```

#### Per-Command Documentation (Pattern 2)
For multi-command tools with inline routing:

```
lib/appydave/tools/tool_name/
├── _doc.md              # Overall module documentation
├── _doc-clean.md        # 'clean' command documentation
└── _doc-join.md         # 'join' command documentation
```

---

## Testing Approach

### Test Structure
Tests mirror the `lib/` structure under `spec/`:

```
lib/appydave/tools/tool_name/processor.rb
spec/appydave/tools/tool_name/processor_spec.rb
```

### RSpec Conventions

#### No Require Statements
All requires are handled by `spec_helper.rb`:

```ruby
# spec/appydave/tools/tool_name/processor_spec.rb
# frozen_string_literal: true

# NO require statements needed

RSpec.describe Appydave::Tools::ToolName::Processor do
  # Tests
end
```

#### Test Business Logic, Not CLI
Focus tests on business logic classes, not bin/ executables:

**✅ Good:**
```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  subject { described_class.new(srt_content: sample_srt) }

  describe '#clean' do
    it 'removes HTML tags' do
      expect(subject.clean).not_to include('<u>')
    end
  end
end
```

**❌ Avoid:**
```ruby
# Testing bin/ executables is fragile and couples tests to CLI
RSpec.describe 'bin/subtitle_processor.rb' do
  it 'runs clean command' do
    `bin/subtitle_processor.rb clean -f test.srt -o output.srt`
    # ...
  end
end
```

#### Guard for Continuous Testing
Use Guard to auto-run tests and RuboCop:

```bash
guard
# Watches file changes and runs relevant tests
```

---

## Migration Guide

### Adding a New Tool to appydave-tools

Follow these steps to integrate a new tool following established patterns:

#### Step 1: Choose Your Pattern
Use the [Decision Tree](#decision-tree) to select Pattern 1, 2, or 3.

#### Step 2: Create Directory Structure

**Pattern 1 (Single-Command):**
```bash
mkdir -p lib/appydave/tools/new_tool
touch bin/new_tool.rb
touch lib/appydave/tools/new_tool/options.rb
touch lib/appydave/tools/new_tool/main_logic.rb
touch lib/appydave/tools/new_tool/_doc.md
chmod +x bin/new_tool.rb
```

**Pattern 2 (Multi-Command Inline):**
```bash
mkdir -p lib/appydave/tools/new_tool
touch bin/new_tool.rb
touch lib/appydave/tools/new_tool/command_one.rb
touch lib/appydave/tools/new_tool/command_two.rb
touch lib/appydave/tools/new_tool/_doc.md
chmod +x bin/new_tool.rb
```

**Pattern 3 (Multi-Command BaseAction):**
```bash
mkdir -p lib/appydave/tools/new_tool
touch bin/new_tool.rb
touch lib/appydave/tools/cli_actions/new_tool_command_one_action.rb
touch lib/appydave/tools/cli_actions/new_tool_command_two_action.rb
touch lib/appydave/tools/new_tool/service.rb
touch lib/appydave/tools/new_tool/_doc.md
chmod +x bin/new_tool.rb
```

#### Step 3: Implement Using Pattern Template
Copy the appropriate pattern template from [Examples](#examples) section.

#### Step 4: Register as Gem Executable
Edit `appydave-tools.gemspec`:

```ruby
spec.executables = [
  'gpt_context',
  'subtitle_processor',
  'youtube_manager',
  'new_tool'  # Add your tool
]
```

#### Step 5: Write Tests
Create corresponding spec files:

```bash
mkdir -p spec/appydave/tools/new_tool
touch spec/appydave/tools/new_tool/main_logic_spec.rb
```

#### Step 6: Document in CLAUDE.md
Add to the "Quick Reference Index" table in `CLAUDE.md`:

```markdown
| Command | Gem Command | Description | Status |
|---------|-------------|-------------|--------|
| **New Tool** | `new_tool` | Brief description | ✅ ACTIVE |
```

Add detailed usage section:

```markdown
#### X. New Tool (`bin/new_tool.rb`)
Brief description of what the tool does:

bash
# Usage examples
bin/new_tool.rb command --option value
```

#### Step 7: Test Locally
```bash
# Install gem locally
rake build
gem install pkg/appydave-tools-X.Y.Z.gem

# Test as system command
new_tool --help

# Run tests
rake spec
```

### Migrating Existing Code

If you have existing standalone scripts to migrate:

#### 1. Identify Business Logic
Separate pure Ruby logic from CLI interface:

**Before:**
```ruby
# bin/standalone_script.rb
#!/usr/bin/env ruby

file = ARGV[0]
puts "Processing #{file}..."

content = File.read(file)
cleaned = content.gsub(/pattern/, 'replacement')

File.write('output.txt', cleaned)
puts "Done!"
```

**After:**
```ruby
# bin/new_tool.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = {}
OptionParser.new do |opts|
  opts.on('-f', '--file FILE', 'Input file') { |v| options[:file] = v }
  opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
end.parse!

processor = Appydave::Tools::NewTool::Processor.new(file: options[:file])
processor.process
processor.write(options[:output])

# lib/appydave/tools/new_tool/processor.rb
module Appydave
  module Tools
    module NewTool
      class Processor
        def initialize(file:)
          @file = file
          @content = File.read(file)
        end

        def process
          @content.gsub(/pattern/, 'replacement')
        end

        def write(output_file)
          File.write(output_file, @content)
        end
      end
    end
  end
end
```

#### 2. Extract Reusable Components
If logic is shared across tools, extract to shared modules:

```
lib/appydave/tools/
├── types/                    # Shared type system
│   ├── base_model.rb
│   └── hash_type.rb
├── configuration/            # Shared config management
│   └── config.rb
└── new_tool/                 # Tool-specific logic
    └── processor.rb
```

---

## Examples

### Complete Pattern 1 Example

**Scenario:** Create a tool that converts CSV to JSON

```ruby
# bin/csv_converter.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

options = Appydave::Tools::CsvConverter::Options.new

OptionParser.new do |opts|
  opts.banner = 'Usage: csv_converter.rb [options]'

  opts.on('-i', '--input FILE', 'Input CSV file') do |v|
    options.input_file = v
  end

  opts.on('-o', '--output FILE', 'Output JSON file') do |v|
    options.output_file = v
  end

  opts.on('-d', '--delimiter CHAR', 'CSV delimiter (default: ,)') do |v|
    options.delimiter = v
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

if options.input_file.nil? || options.output_file.nil?
  puts 'Missing required options. Use -h for help.'
  exit 1
end

converter = Appydave::Tools::CsvConverter::Converter.new(options)
converter.convert
puts "Converted #{options.input_file} to #{options.output_file}"
```

```ruby
# lib/appydave/tools/csv_converter/options.rb
# frozen_string_literal: true

module Appydave
  module Tools
    module CsvConverter
      Options = Struct.new(
        :input_file,
        :output_file,
        :delimiter,
        keyword_init: true
      ) do
        def initialize(**args)
          super
          self.delimiter ||= ','
        end
      end
    end
  end
end
```

```ruby
# lib/appydave/tools/csv_converter/converter.rb
# frozen_string_literal: true

require 'csv'
require 'json'

module Appydave
  module Tools
    module CsvConverter
      class Converter
        def initialize(options)
          @input_file = options.input_file
          @output_file = options.output_file
          @delimiter = options.delimiter
        end

        def convert
          data = parse_csv
          write_json(data)
        end

        private

        def parse_csv
          CSV.read(@input_file, col_sep: @delimiter, headers: true).map(&:to_h)
        end

        def write_json(data)
          File.write(@output_file, JSON.pretty_generate(data))
        end
      end
    end
  end
end
```

### Complete Pattern 2 Example

**Scenario:** Create a tool with `encode` and `decode` commands

```ruby
# bin/text_processor.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

class TextProcessorCLI
  def initialize
    @commands = {
      'encode' => method(:encode_text),
      'decode' => method(:decode_text)
    }
  end

  def run
    command, *args = ARGV

    if command.nil?
      print_help
      exit
    end

    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def encode_text(args)
    options = { file: nil, output: nil, algorithm: 'base64' }

    OptionParser.new do |opts|
      opts.banner = 'Usage: text_processor.rb encode [options]'

      opts.on('-f', '--file FILE', 'Input file') { |v| options[:file] = v }
      opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
      opts.on('-a', '--algorithm ALG', %w[base64 rot13], 'Encoding algorithm') { |v| options[:algorithm] = v }

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    validate_options!(options)

    encoder = Appydave::Tools::TextProcessor::Encoder.new(
      file: options[:file],
      algorithm: options[:algorithm]
    )
    encoder.encode
    encoder.write(options[:output])
  end

  def decode_text(args)
    options = { file: nil, output: nil, algorithm: 'base64' }

    OptionParser.new do |opts|
      opts.banner = 'Usage: text_processor.rb decode [options]'

      opts.on('-f', '--file FILE', 'Input file') { |v| options[:file] = v }
      opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
      opts.on('-a', '--algorithm ALG', %w[base64 rot13], 'Decoding algorithm') { |v| options[:algorithm] = v }

      opts.on('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    validate_options!(options)

    decoder = Appydave::Tools::TextProcessor::Decoder.new(
      file: options[:file],
      algorithm: options[:algorithm]
    )
    decoder.decode
    decoder.write(options[:output])
  end

  def validate_options!(options)
    if options[:file].nil? || options[:output].nil?
      puts 'Missing required options: --file and --output'
      exit 1
    end
  end

  def print_help
    puts 'Usage: text_processor.rb [command] [options]'
    puts 'Commands:'
    puts '  encode    Encode text file'
    puts '  decode    Decode text file'
    puts "Run 'text_processor.rb [command] --help' for more information."
  end
end

TextProcessorCLI.new.run
```

```ruby
# lib/appydave/tools/text_processor/encoder.rb
# frozen_string_literal: true

require 'base64'

module Appydave
  module Tools
    module TextProcessor
      class Encoder
        def initialize(file:, algorithm: 'base64')
          @file = file
          @algorithm = algorithm
          @content = File.read(file)
          @encoded = nil
        end

        def encode
          @encoded = case @algorithm
                     when 'base64'
                       Base64.strict_encode64(@content)
                     when 'rot13'
                       @content.tr('A-Za-z', 'N-ZA-Mn-za-m')
                     end
        end

        def write(output_file)
          File.write(output_file, @encoded)
        end
      end
    end
  end
end
```

### Complete Pattern 3 Example

**Scenario:** Create a tool with `list`, `create`, `delete` commands

```ruby
# lib/appydave/tools/cli_actions/base_action.rb (already exists)

# lib/appydave/tools/cli_actions/resource_list_action.rb
# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      class ResourceListAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-f', '--filter PATTERN', 'Filter pattern') { |v| options[:filter] = v }
          opts.on('-s', '--sort FIELD', 'Sort by field') { |v| options[:sort] = v }
        end

        def validate_options(options)
          # All options are optional for list
        end

        def execute(options)
          manager = Appydave::Tools::ResourceManager::Manager.new
          resources = manager.list(filter: options[:filter], sort: options[:sort])

          resources.each do |resource|
            puts "#{resource.id}: #{resource.name}"
          end
        end
      end
    end
  end
end
```

```ruby
# lib/appydave/tools/cli_actions/resource_create_action.rb
# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      class ResourceCreateAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-n', '--name NAME', 'Resource name') { |v| options[:name] = v }
          opts.on('-t', '--type TYPE', 'Resource type') { |v| options[:type] = v }
        end

        def validate_options(options)
          return if options[:name] && options[:type]

          puts 'Missing required options: --name and --type'
          exit 1
        end

        def execute(options)
          manager = Appydave::Tools::ResourceManager::Manager.new
          resource = manager.create(name: options[:name], type: options[:type])

          puts "Created resource: #{resource.id}"
        end
      end
    end
  end
end
```

```ruby
# bin/resource_manager.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

class ResourceManagerCLI
  def initialize
    @commands = {
      'list' => Appydave::Tools::CliActions::ResourceListAction.new,
      'create' => Appydave::Tools::CliActions::ResourceCreateAction.new,
      'delete' => Appydave::Tools::CliActions::ResourceDeleteAction.new
    }
  end

  def run
    command, *args = ARGV

    if @commands.key?(command)
      @commands[command].action(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def print_help
    puts 'Usage: resource_manager.rb [command] [options]'
    puts 'Commands:'
    puts '  list      List resources'
    puts '  create    Create a new resource'
    puts '  delete    Delete a resource'
    puts "Run 'resource_manager.rb [command] --help' for more information."
  end
end

ResourceManagerCLI.new.run
```

---

## Summary

This guide provides three proven patterns for CLI architecture in appydave-tools:

1. **Pattern 1**: Single-command tools - Simple, linear execution
2. **Pattern 2**: Multi-command with inline routing - 2-5 commands, simple routing
3. **Pattern 3**: Multi-command with BaseAction - 6+ commands, shared patterns

**Key Principles:**
- Separate CLI interface (`bin/`) from business logic (`lib/`)
- No CLI code in `lib/` - business logic should be usable programmatically
- Use `frozen_string_literal: true` in all Ruby files
- Follow existing naming conventions
- Test business logic, not CLI executables
- Document with `_doc.md` files

When in doubt, start with **Pattern 1** or **Pattern 2** and refactor to **Pattern 3** if the tool grows to 6+ commands.

---

**Last updated:** 2025-11-08
