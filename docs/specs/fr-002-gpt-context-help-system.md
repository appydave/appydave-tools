# FR-002: GPT Context AI-Friendly Help System

**Status**: Ready for Development
**Priority**: High
**Created**: 2025-12-07

---

## Summary

Enhance GPT Context's help system to provide structured, comprehensive documentation suitable for AI agent consumption. Model after DAM's multi-level help architecture.

---

## User Story

As an AI agent using GPT Context via skills, I want structured, comprehensive help output so I can understand all options and use the tool correctly without guessing.

---

## Current State

**GPT Context help** (`gpt_context --help`):
- Basic OptionParser output
- Lists flags with brief descriptions
- No examples, no detailed explanations
- No `--version` flag

**DAM help** (`dam help`):
- Multi-level: `dam help`, `dam help [topic]`
- Structured sections with examples
- Topic-specific deep dives
- Machine-parseable format

---

## Requirements

### Must Have

1. **Enhanced `--help` output** with structured sections:
   - Synopsis (command signature)
   - Description (what the tool does)
   - Options (all flags with details)
   - Output Formats (tree, content, json, aider, files)
   - Examples (real-world usage)

2. **Each option must include**:
   - Flag(s): `-i, --include`
   - Description: What it does
   - Default: Default value if any
   - Valid values: For constrained options like `-f`

3. **Add `--version` flag**
   - Output: `gpt_context version X.Y.Z`

4. **Real-world examples** in help output:
   ```
   Examples:
     # Gather Ruby library code
     gpt_context -i 'lib/**/*.rb' -e 'spec/**/*' -d

     # Project structure overview
     gpt_context -i '**/*' -f tree -e 'node_modules/**/*'

     # Generate aider command
     gpt_context -i 'lib/**/*.rb' -f aider -p "Add logging"
   ```

### Nice to Have

- `gpt_context help formats` - detailed format documentation
- `gpt_context help examples` - extended examples collection
- Markdown-formatted output option (`--help --format md`)

---

## Technical Implementation

### File Locations

- **CLI**: `bin/gpt_context.rb`
- **Options**: `lib/appydave/tools/gpt_context/options.rb`
- **Version**: `lib/appydave/tools/version.rb` (already exists)

### Approach

**Option A: Enhanced OptionParser** (Recommended)
- Keep single `--help` flag
- Add custom `banner` and `separator` calls for structure
- Add `--version` flag
- Simpler, maintains current architecture

**Option B: Subcommand Pattern** (Like DAM)
- Add `help` subcommand with topics
- More complex, requires CLI restructure
- Overkill for single-purpose tool

### Recommended: Option A

Enhance the existing OptionParser in `bin/gpt_context.rb`:

```ruby
# Current structure (simplified)
OptionParser.new do |opts|
  opts.banner = "Usage: gpt_context [options]"
  opts.on('-i', '--include PATTERN', 'Include pattern') { ... }
  # etc
end

# Enhanced structure
OptionParser.new do |opts|
  opts.banner = <<~BANNER
    GPT Context Gatherer - Collect project files for AI context

    SYNOPSIS
        gpt_context [options]

    DESCRIPTION
        Collects and packages codebase files for AI assistant context.
        Outputs to clipboard (default), file, or stdout.

  BANNER

  opts.separator ""
  opts.separator "OPTIONS"
  opts.separator ""

  opts.on('-i', '--include PATTERN',
          'Glob pattern for files to include (repeatable)',
          'Example: -i "lib/**/*.rb" -i "bin/**/*.rb"') do |pattern|
    # ...
  end

  opts.on('-e', '--exclude PATTERN',
          'Glob pattern for files to exclude (repeatable)',
          'Example: -e "spec/**/*" -e "node_modules/**/*"') do |pattern|
    # ...
  end

  opts.on('-f', '--format FORMATS',
          'Output format(s): tree, content, json, aider, files',
          'Comma-separated. Default: content',
          'Example: -f tree,content') do |formats|
    # ...
  end

  opts.on('-o', '--output TARGET',
          'Output target: clipboard, filename, or stdout',
          'Default: clipboard') do |target|
    # ...
  end

  opts.on('-d', '--debug', 'Enable debug output') do
    # ...
  end

  opts.on('-l', '--line-limit N', Integer,
          'Limit lines per file (default: unlimited)') do |n|
    # ...
  end

  opts.on('-p', '--prompt TEXT',
          'Prompt text for aider format') do |text|
    # ...
  end

  opts.separator ""
  opts.separator "OUTPUT FORMATS"
  opts.separator "    tree     - Directory tree structure"
  opts.separator "    content  - File contents with headers"
  opts.separator "    json     - Structured JSON output"
  opts.separator "    aider    - Aider CLI command format"
  opts.separator "    files    - File paths only"
  opts.separator ""

  opts.separator "EXAMPLES"
  opts.separator "    # Gather Ruby library code for AI context"
  opts.separator "    gpt_context -i 'lib/**/*.rb' -e 'spec/**/*' -d"
  opts.separator ""
  opts.separator "    # Project structure overview"
  opts.separator "    gpt_context -i '**/*' -f tree -e 'node_modules/**/*'"
  opts.separator ""
  opts.separator "    # Save to file with tree and content"
  opts.separator "    gpt_context -i 'src/**/*.ts' -f tree,content -o context.txt"
  opts.separator ""
  opts.separator "    # Generate aider command"
  opts.separator "    gpt_context -i 'lib/**/*.rb' -f aider -p 'Add logging'"
  opts.separator ""

  opts.on('-v', '--version', 'Show version') do
    puts "gpt_context version #{Appydave::Tools::VERSION}"
    exit
  end

  opts.on('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end
```

---

## Acceptance Criteria

- [ ] `gpt_context --help` shows structured output with sections
- [ ] All options include description, default (if any), and examples
- [ ] Examples section shows 3-4 real-world use cases
- [ ] Output formats section explains each format
- [ ] `gpt_context --version` outputs version number
- [ ] Help output is easily parseable by AI agents (clear sections, consistent formatting)

---

## Testing

```bash
# Manual verification
gpt_context --help        # Should show enhanced help
gpt_context --version     # Should show version
gpt_context -v            # Short version flag

# Verify help includes all required sections
gpt_context --help | grep -E "^(SYNOPSIS|DESCRIPTION|OPTIONS|OUTPUT FORMATS|EXAMPLES)"
```

Add spec:
```ruby
# spec/appydave/tools/gpt_context/cli_spec.rb
describe 'CLI help' do
  it 'includes synopsis section' do
    output = `bin/gpt_context.rb --help`
    expect(output).to include('SYNOPSIS')
  end

  it 'includes examples section' do
    output = `bin/gpt_context.rb --help`
    expect(output).to include('EXAMPLES')
  end

  it 'shows version' do
    output = `bin/gpt_context.rb --version`
    expect(output).to match(/gpt_context version \d+\.\d+\.\d+/)
  end
end
```

---

## Definition of Done

1. Enhanced `--help` output with all sections
2. `--version` flag working
3. Specs pass
4. Manual verification complete
5. Commit with `kfeat "add AI-friendly help system to GPT Context"`

---

## Reference

- **DAM help implementation**: `bin/dam` lines 1-200 (help system)
- **Current GPT Context CLI**: `bin/gpt_context.rb`
- **GPT Context architecture**: `docs/architecture/gpt-context/`
