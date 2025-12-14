# CLI Patterns Guide

This document analyzes the CLI patterns used across appydave-tools and provides guidance on which pattern to use for different scenarios.

## Overview

The codebase uses **4 distinct CLI patterns**, each suited to different complexity levels:

| Pattern | Example Tools | Best For |
|---------|---------------|----------|
| [Simple Procedural](#pattern-1-simple-procedural) | GPT Context, Configuration | Single-purpose tools, < 5 options |
| [Action Class Dispatch](#pattern-2-action-class-dispatch) | YouTube Manager | Medium complexity, reusable actions |
| [Method Dispatch (Light)](#pattern-3-method-dispatch-light) | Subtitle Processor | Multi-command with per-command options |
| [Method Dispatch (Full)](#pattern-4-method-dispatch-full) | DAM | Complex tools, hierarchical help, 10+ commands |

## Pattern Decision Flowchart

```
How many commands/subcommands?
│
├─ 1 (single purpose) ──────────────────────► Pattern 1: Simple Procedural
│
├─ 2-5 commands
│   │
│   ├─ Actions reusable elsewhere? ─── Yes ─► Pattern 2: Action Class Dispatch
│   │
│   └─ Self-contained tool? ─────────── Yes ─► Pattern 3: Method Dispatch (Light)
│
└─ 6+ commands
    │
    ├─ Need hierarchical help? ──────── Yes ─► Pattern 4: Method Dispatch (Full)
    │
    └─ Simple help is fine? ─────────── Yes ─► Pattern 3: Method Dispatch (Light)
```

---

## Pattern 1: Simple Procedural

**Used by:** `gpt_context.rb`, `configuration.rb`

**Characteristics:**
- Direct OptionParser usage at script level
- No wrapper class (or minimal)
- Options collected into hash or struct
- `case/when` for command dispatch (if needed)
- Delegates to library classes for business logic

**When to use:**
- Single-purpose tools
- Fewer than 5 options/flags
- No subcommands, or very few (< 3)
- Quick scripts that don't need extensibility

### Example: GPT Context (Single Purpose)

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

options = Appydave::Tools::GptContext::Options.new(
  working_directory: nil
)

OptionParser.new do |opts|
  opts.banner = 'Usage: gpt_context [options]'

  opts.on('-i', '--include PATTERN', 'Pattern to include') do |pattern|
    options.include_patterns << pattern
  end

  opts.on('-e', '--exclude PATTERN', 'Pattern to exclude') do |pattern|
    options.exclude_patterns << pattern
  end

  opts.on('-f', '--format FORMAT', 'Output format') do |format|
    options.format = format
  end

  opts.on('-d', '--debug', 'Enable debug mode') do
    options.debug = true
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

# Delegate to library classes
gatherer = Appydave::Tools::GptContext::FileCollector.new(options)
content = gatherer.build

output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute
```

### Example: Configuration (Flag-based Commands)

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

options = { keys: [] }

OptionParser.new do |opts|
  opts.banner = 'Usage: ad_config [options]'

  opts.on('-e', '--edit', 'Edit configuration') do
    options[:command] = :edit
  end

  opts.on('-l', '--list', 'List configurations') do
    options[:command] = :list
  end

  opts.on('-c', '--create', 'Create missing configs') do
    options[:command] = :create
  end

  opts.on('-p', '--print [KEYS]', Array, 'Print config values') do |keys|
    options[:command] = :print
    options[:keys] = keys
  end
end.parse!

# Simple case/when dispatch
case options[:command]
when :edit
  Appydave::Tools::Configuration::Config.edit
when :list
  # ... list logic
when :create
  # ... create logic
when :print
  Appydave::Tools::Configuration::Config.print(*options[:keys])
else
  puts 'No command provided. Use --help for usage.'
end
```

**Pros:**
- Minimal boilerplate
- Easy to understand
- Fast to implement
- Standard Ruby pattern

**Cons:**
- Doesn't scale well beyond 5 options
- No help hierarchy
- Hard to test CLI parsing separately

---

## Pattern 2: Action Class Dispatch

**Used by:** `youtube_manager.rb`

**Characteristics:**
- CLI class routes commands to Action objects
- Each Action is a separate class with `.action(args)` method
- Actions handle their own OptionParser
- Actions can be reused by other code (not just CLI)

**When to use:**
- Actions need to be callable from multiple places (CLI, tests, other code)
- Medium complexity (2-5 commands)
- Each command has distinct option sets
- Want clean separation between routing and execution

### Example: YouTube Manager

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

class YouTubeVideoManagerCLI
  def initialize
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
    puts 'Usage: youtube_manager [command] [options]'
    puts 'Commands:'
    puts '  get    Get video details'
    puts '  update Update video metadata'
  end
end

YouTubeVideoManagerCLI.new.run
```

**Action Class Structure:**

```ruby
# lib/appydave/tools/cli_actions/get_video_action.rb
module Appydave::Tools::CliActions
  class GetVideoAction
    def action(args)
      options = parse_options(args)

      video = YouTubeManager::GetVideo.new
      video.get(options[:video_id])
      # ... display results
    end

    private

    def parse_options(args)
      options = {}
      OptionParser.new do |opts|
        opts.on('-v', '--video-id ID', 'Video ID') { |v| options[:video_id] = v }
        opts.on('-h', '--help', 'Show help') { puts opts; exit }
      end.parse!(args)
      options
    end
  end
end
```

**Pros:**
- Actions are testable independently
- Clean separation of concerns
- Actions reusable outside CLI context
- Easy to add new commands

**Cons:**
- More files to manage
- Slight overhead for simple cases
- Requires Action class convention

---

## Pattern 3: Method Dispatch (Light)

**Used by:** `subtitle_processor.rb`

**Characteristics:**
- CLI class with command map to `method(:name)`
- Each command method handles its own OptionParser
- Per-command help via `-h` flag
- Self-contained in single file

**When to use:**
- 3-8 commands with distinct option sets
- Commands are tool-specific (not reusable elsewhere)
- Want subcommand-style interface: `tool command --options`
- Moderate complexity, single-file preferred

### Example: Subtitle Processor

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

class SubtitleProcessorCLI
  def initialize
    @commands = {
      'clean' => method(:clean_subtitles),
      'join' => method(:join_subtitles),
      'transcript' => method(:transcript_subtitles)
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

  def clean_subtitles(args)
    options = { file: nil, output: nil }

    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor clean [options]'
      opts.on('-f', '--file FILE', 'Input SRT file') { |v| options[:file] = v }
      opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
      opts.on('-h', '--help', 'Show help') { puts opts; exit }
    end
    parser.parse!(args)

    validate_required!(options, [:file, :output], parser)

    cleaner = Appydave::Tools::SubtitleProcessor::Clean.new(file_path: options[:file])
    cleaner.clean
    cleaner.write(options[:output])
  end

  def join_subtitles(args)
    options = { folder: './', files: '*.srt', output: 'merged.srt' }

    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: subtitle_processor join [options]'
      opts.on('-d', '--directory DIR', 'Directory') { |v| options[:folder] = v }
      opts.on('-f', '--files PATTERN', 'File pattern') { |v| options[:files] = v }
      opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
      opts.on('-h', '--help', 'Show help') { puts opts; exit }
    end
    parser.parse!(args)

    joiner = Appydave::Tools::SubtitleProcessor::Join.new(**options)
    joiner.join
  end

  def print_help
    puts 'Usage: subtitle_processor [command] [options]'
    puts 'Commands:'
    puts '  clean      Clean SRT files'
    puts '  join       Join multiple SRT files'
    puts '  transcript Convert to plain text'
  end

  def validate_required!(options, required, parser)
    missing = required.select { |k| options[k].nil? }
    return if missing.empty?

    puts "Error: Missing required options: #{missing.join(', ')}"
    puts parser
    exit 1
  end
end

SubtitleProcessorCLI.new.run
```

**Pros:**
- Clean subcommand interface
- Per-command help works naturally
- Single file, easy to navigate
- Scales to ~10 commands comfortably

**Cons:**
- File gets long with many commands
- No hierarchical help topics
- Command methods not reusable outside CLI

---

## Pattern 4: Method Dispatch (Full)

**Used by:** `dam` (bin/dam)

**Characteristics:**
- Large CLI class (1000+ lines)
- Command map to `method(:name)`
- **Hierarchical help system**: `tool help <topic>`
- Custom argument parsing per command (not just OptionParser)
- Deprecated command aliases
- Auto-detection features (e.g., detect brand from PWD)

**When to use:**
- 10+ commands
- Complex help needs (topics, workflows, configuration)
- Advanced features (auto-detection, patterns, shortcuts)
- Tool is central to workflow, worth the investment

### Example: DAM Structure

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appydave/tools'

class VatCLI
  def initialize
    @commands = {
      'help' => method(:help_command),
      'list' => method(:list_command),
      's3-up' => method(:s3_up_command),
      's3-down' => method(:s3_down_command),
      's3-status' => method(:s3_status_command),
      # ... 15+ more commands

      # Deprecated aliases (backward compatibility)
      's3-cleanup' => method(:s3_cleanup_remote_command)
    }
  end

  def run
    command, *args = ARGV

    # Version flag handling
    if ['--version', '-v'].include?(command)
      puts "DAM v#{Appydave::Tools::VERSION}"
      exit
    end

    # No command = show quick usage
    if command.nil?
      puts 'DAM - Video Asset Tools'
      puts 'Usage: dam [command] [options]'
      puts "Run 'dam help' for more information."
      exit
    end

    # Dispatch or error with helpful message
    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      puts 'Available: list, s3-up, s3-down, s3-status, ...'
      exit 1
    end
  end

  private

  # ─────────────────────────────────────────────────────────────────
  # HIERARCHICAL HELP SYSTEM
  # ─────────────────────────────────────────────────────────────────

  def help_command(args)
    topic = args[0]

    case topic
    when 'brands'
      show_brands_help
    when 'workflows'
      show_workflows_help
    when 'config'
      show_config_help
    when 's3-up', 's3-down', 's3-status'
      show_s3_help(topic)
    when 's3-cleanup'  # Deprecated
      puts "⚠️  's3-cleanup' is deprecated. Use 's3-cleanup-remote'."
      show_s3_help('s3-cleanup-remote')
    when nil
      show_main_help
    else
      puts "Unknown help topic: #{topic}"
      show_help_topics
    end
  end

  def show_main_help
    puts <<~HELP
      DAM - Digital Asset Management for Video Projects

      Usage: dam [command] [options]

      Commands:
        list              List brands and projects
        s3-up             Upload project to S3
        s3-down           Download project from S3
        ...

      Help Topics:
        dam help brands     Brand shortcuts and configuration
        dam help workflows  FliVideo and Storyline workflows
        dam help config     Configuration setup
    HELP
  end

  def show_brands_help
    puts <<~HELP
      Available Brands

      DAM supports multi-tenant video project management:

        appydave  → v-appydave         (AppyDave brand)
        voz       → v-voz              (VOZ client)
        aitldr    → v-aitldr           (AITLDR brand)
        ...

      Examples:
        dam list appydave
        dam s3-up voz boy-baker
    HELP
  end

  # ─────────────────────────────────────────────────────────────────
  # COMMAND IMPLEMENTATIONS
  # ─────────────────────────────────────────────────────────────────

  def s3_up_command(args)
    options = parse_s3_args(args, 's3-up')
    s3_ops = Appydave::Tools::Dam::S3Operations.new(options[:brand], options[:project])
    s3_ops.upload(dry_run: options[:dry_run])
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end

  # ─────────────────────────────────────────────────────────────────
  # CUSTOM ARGUMENT PARSING
  # ─────────────────────────────────────────────────────────────────

  def parse_s3_args(args, command)
    dry_run = args.include?('--dry-run')
    force = args.include?('--force')
    args = args.reject { |arg| arg.start_with?('--') }

    brand_arg = args[0]
    project_arg = args[1]

    # Auto-detect from current directory if no args
    if brand_arg.nil?
      brand, project_id = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
      if brand.nil?
        puts "Could not auto-detect. Usage: dam #{command} <brand> <project>"
        exit 1
      end
    else
      # Validate and resolve
      validate_brand!(brand_arg)
      project_id = Appydave::Tools::Dam::ProjectResolver.resolve(brand_arg, project_arg)
    end

    { brand: brand_arg, project: project_id, dry_run: dry_run, force: force }
  end
end

VatCLI.new.run
```

**Pros:**
- Scales to 20+ commands
- Rich, hierarchical help system
- Supports deprecated aliases gracefully
- Advanced features (auto-detection, patterns)
- Professional CLI experience

**Cons:**
- Large file (1000+ lines)
- Complex to maintain
- Significant upfront investment
- Custom parsing logic to test

---

## Pattern Comparison Summary

| Aspect | Pattern 1 | Pattern 2 | Pattern 3 | Pattern 4 |
|--------|-----------|-----------|-----------|-----------|
| **Commands** | 1 | 2-5 | 3-10 | 10+ |
| **File Count** | 1 | Multiple | 1 | 1 (large) |
| **Help System** | `-h` flag | Per-command `-h` | Per-command `-h` | Hierarchical topics |
| **Reusability** | Low | High (Actions) | Medium | Low |
| **Testability** | Medium | High | Medium | Medium |
| **Boilerplate** | Minimal | Medium | Medium | High |
| **Learning Curve** | Low | Medium | Low | Medium |

---

## Recommendations by Scenario

### New single-purpose tool
→ **Pattern 1: Simple Procedural**

Example: A tool to format JSON files
```bash
json_formatter -i input.json -o output.json --pretty
```

### Tool with actions used elsewhere
→ **Pattern 2: Action Class Dispatch**

Example: A build tool where actions are also called by CI scripts
```bash
build_tool compile    # Also called by BuildAction.new.action([])
build_tool test
build_tool deploy
```

### Medium complexity, self-contained
→ **Pattern 3: Method Dispatch (Light)**

Example: A subtitle/media processing tool
```bash
media_tool convert -i video.mp4 -o video.webm
media_tool thumbnail -i video.mp4 -t 5
media_tool info -i video.mp4
```

### Complex workflow tool
→ **Pattern 4: Method Dispatch (Full)**

Example: A project management CLI
```bash
project help topics
project init --template react
project deploy staging --dry-run
project status --all
```

---

## Migration Path

If a tool outgrows its pattern:

1. **Pattern 1 → Pattern 3**: Extract command logic into methods, add command dispatch
2. **Pattern 3 → Pattern 4**: Add hierarchical help, enhance argument parsing
3. **Pattern 3 → Pattern 2**: Extract methods into Action classes if reuse needed

The patterns are designed to be progressive - start simple, add complexity only when needed.
