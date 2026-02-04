# Pattern 4: Delegated CLI Class

Complete guide to the Delegated CLI Class pattern for professional-grade CLI tools with 10+ commands.

## Table of Contents

- [Overview](#overview)
- [When to Use](#when-to-use)
- [Structure](#structure)
- [Implementation Guide](#implementation-guide)
- [Testing Approach](#testing-approach)
- [Pattern 3 vs Pattern 4](#pattern-3-vs-pattern-4)
- [Migration Guide](#migration-guide)
- [Real-World Example: Jump](#real-world-example-jump)

---

## Overview

**Pattern 4** separates CLI interface code into a dedicated class in `lib/`, making it fully testable and professional-grade.

### Key Characteristics

- ✅ **Full CLI in lib/** - Complete CLI implementation as a testable class
- ✅ **Ultra-thin bin/** - Just 25-40 lines (creates CLI object, calls run)
- ✅ **Testable CLI** - Unit test CLI behavior, exit codes, error handling
- ✅ **Dependency injection** - Inject config, output, validators for testing
- ✅ **10+ commands** - Scales to complex tools
- ✅ **Exit codes** - Proper Unix exit code handling
- ✅ **Professional grade** - Production-ready CLI architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                 PATTERN 4: DELEGATED CLI CLASS                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bin/tool.rb (30 lines) ──────────┐                                │
│    #!/usr/bin/env ruby            │                                 │
│    require 'appydave/tools'       │                                 │
│    cli = Tools::Tool::CLI.new     │                                 │
│    exit(cli.run(ARGV))            │                                 │
│                                   │                                 │
│  lib/tools/tool/ ◄────────────────┘                                │
│    ├── cli.rb                 (Full CLI implementation)             │
│    │   ├── def run(args)       (Entry point)                        │
│    │   ├── def run_search      (Command dispatcher)                 │
│    │   ├── def run_add         (Command dispatcher)                 │
│    │   └── def run_remove      (Command dispatcher)                 │
│    │                                                                │
│    ├── search.rb              (Business logic)                      │
│    ├── crud.rb                (Business logic)                      │
│    └── config.rb              (Configuration)                       │
│                                                                     │
│  spec/tools/tool/                                                   │
│    ├── cli_spec.rb            (Test CLI behavior!)                  │
│    ├── search_spec.rb                                               │
│    └── crud_spec.rb                                                 │
│                                                                     │
│  Characteristics:                                                   │
│  • CLI is a class (testable via RSpec)                             │
│  • Dependency injection (config, output, validators)               │
│  • Exit codes (0 success, 1-4 errors)                              │
│  • Case/when command dispatch                                      │
│                                                                     │
│  Example: jump (10 commands, 400+ lines in lib/cli.rb)             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## When to Use

### ✅ Use Pattern 4 When:

| Criteria | Threshold | Why |
|----------|-----------|-----|
| **Number of commands** | 10+ | Case/when scales better than method hash |
| **CLI complexity** | 300+ lines | Justifies separate CLI class |
| **Exit codes needed** | Yes | Professional Unix exit code handling |
| **Need CLI tests** | Yes | Test CLI behavior separately from business logic |
| **Dependency injection** | Yes | Mock config/output for testing |
| **Professional tool** | Yes | Production-ready architecture |
| **Complex help system** | Yes | Hierarchical help (main, command, topic) |

### ❌ Don't Use Pattern 4 When:

- Tool has < 10 commands → Use Pattern 2 or 3
- CLI logic is simple → Pattern 2 sufficient
- Don't need CLI testing → Pattern 2 or 3 sufficient
- Tool is internal/experimental → Simpler pattern OK

### Pattern 4 vs Pattern 3

**Use Pattern 4 over Pattern 3 when:**
- You want to **test CLI behavior** (exit codes, output, error messages)
- CLI has **complex command routing** (10+ commands)
- Need **dependency injection** for testing
- Building a **professional-grade tool** (like `jump`, `git`, `docker`)

**Use Pattern 3 over Pattern 4 when:**
- Commands **share validation patterns** (BaseAction enforces consistency)
- CLI is **simple enough** to live in bin/
- **Template method pattern** is beneficial
- **6-9 commands** (not quite 10+)

---

## Structure

### Directory Layout

```
appydave-tools/
├── bin/
│   └── tool.rb                         # Thin wrapper (30 lines)
│
├── lib/appydave/tools/
│   └── tool/
│       ├── cli.rb                      # Full CLI class (400+ lines)
│       ├── config.rb                   # Configuration
│       ├── search.rb                   # Business logic
│       ├── crud.rb                     # Business logic
│       ├── formatters/                 # Output formatting
│       │   ├── table_formatter.rb
│       │   ├── json_formatter.rb
│       │   └── paths_formatter.rb
│       └── _doc.md                     # Documentation
│
└── spec/appydave/tools/
    └── tool/
        ├── cli_spec.rb                 # Test CLI behavior!
        ├── search_spec.rb
        └── crud_spec.rb
```

### File Sizes

| File | Lines | Purpose |
|------|-------|---------|
| `bin/tool.rb` | 25-40 | Wrapper only |
| `lib/tool/cli.rb` | 300-800 | Full CLI implementation |
| `lib/tool/business.rb` | 50-300 | Business logic per module |
| `spec/tool/cli_spec.rb` | 100-300 | CLI tests |

---

## Implementation Guide

### Step 1: Create bin/ Wrapper

**bin/tool.rb** (30 lines max):

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Tool Description
#
# Usage:
#   tool search <terms>           # Fuzzy search
#   tool get <key>                # Get by key
#   tool list                     # List all
#   tool add --key <key>          # Add new
#   tool remove <key> --force     # Remove
#   tool help                     # Show help
#
# Examples:
#   tool search my project
#   tool add --key my-proj --path ~/dev/my-proj

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

cli = Appydave::Tools::Tool::CLI.new
exit_code = cli.run(ARGV)
exit(exit_code)
```

**Key points:**
- ✅ Usage documentation in comments
- ✅ Examples in comments
- ✅ Loads lib/ path
- ✅ Creates CLI instance
- ✅ Passes ARGV to run()
- ✅ Exits with proper code

### Step 2: Create CLI Class

**lib/appydave/tools/tool/cli.rb** (full implementation):

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Tool
      # CLI provides the command-line interface for the Tool
      #
      # Uses the Delegated CLI pattern for 10+ commands with
      # dependency injection and comprehensive testing.
      #
      # @example Usage
      #   cli = CLI.new
      #   cli.run(['search', 'term'])
      #   cli.run(['add', '--key', 'my-project', '--path', '~/dev/project'])
      class CLI
        # Exit codes following Unix conventions
        EXIT_SUCCESS = 0
        EXIT_NOT_FOUND = 1
        EXIT_INVALID_INPUT = 2
        EXIT_CONFIG_ERROR = 3
        EXIT_PATH_NOT_FOUND = 4

        attr_reader :config, :validator, :output

        # Initialize CLI with optional dependencies (for testing)
        #
        # @param config [Config] Configuration object (default: loads from file)
        # @param validator [PathValidator] Path validator (default: new instance)
        # @param output [IO] Output stream (default: $stdout)
        def initialize(config: nil, validator: nil, output: $stdout)
          @validator = validator || PathValidator.new
          @output = output
          @config = config
        end

        # Main entry point - dispatches to command methods
        #
        # @param args [Array<String>] Command-line arguments
        # @return [Integer] Exit code
        def run(args = ARGV)
          command = args.shift

          case command
          when nil, '', '--help', '-h'
            show_main_help
            EXIT_SUCCESS
          when '--version', '-v'
            show_version
            EXIT_SUCCESS
          when 'help'
            show_help(args)
            EXIT_SUCCESS
          when 'search'
            run_search(args)
          when 'get'
            run_get(args)
          when 'list'
            run_list(args)
          when 'add'
            run_add(args)
          when 'update'
            run_update(args)
          when 'remove'
            run_remove(args)
          when 'validate'
            run_validate(args)
          when 'report'
            run_report(args)
          when 'generate'
            run_generate(args)
          when 'info'
            run_info(args)
          else
            output.puts "Unknown command: #{command}"
            output.puts "Run 'tool help' for available commands."
            EXIT_INVALID_INPUT
          end
        rescue StandardError => e
          output.puts "Error: #{e.message}"
          output.puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
          EXIT_CONFIG_ERROR
        end

        private

        # Lazy-load configuration
        def load_config
          @config ||= Config.new
        end

        # Extract format option from args
        def format_option(args)
          format_index = args.index('--format') || args.index('-f')
          return 'table' unless format_index

          format = args[format_index + 1]
          args.delete_at(format_index + 1)
          args.delete_at(format_index)
          format || 'table'
        end

        # Format output using appropriate formatter
        def format_output(result, format)
          formatter = case format
                      when 'json'
                        Formatters::JsonFormatter.new(result)
                      when 'paths'
                        Formatters::PathsFormatter.new(result)
                      else
                        Formatters::TableFormatter.new(result)
                      end

          output.puts formatter.format
        end

        # Convert result hash to exit code
        def exit_code_for(result)
          return EXIT_SUCCESS if result[:success]

          case result[:code]
          when 'NOT_FOUND'
            EXIT_NOT_FOUND
          when 'INVALID_INPUT', 'DUPLICATE_KEY', 'CONFIRMATION_REQUIRED'
            EXIT_INVALID_INPUT
          when 'PATH_NOT_FOUND'
            EXIT_PATH_NOT_FOUND
          else
            EXIT_CONFIG_ERROR
          end
        end

        # Command implementations

        def run_search(args)
          format = format_option(args)
          query = args.join(' ')

          search = Search.new(load_config)
          result = search.search(query)

          format_output(result, format)
          exit_code_for(result)
        end

        def run_get(args)
          format = format_option(args)
          key = args.first

          unless key
            output.puts 'Usage: tool get <key>'
            return EXIT_INVALID_INPUT
          end

          search = Search.new(load_config)
          result = search.get(key)

          format_output(result, format)
          exit_code_for(result)
        end

        def run_list(args)
          format = format_option(args)

          search = Search.new(load_config)
          result = search.list

          format_output(result, format)
          exit_code_for(result)
        end

        def run_add(args)
          # Parse options with OptionParser
          options = {}
          OptionParser.new do |opts|
            opts.banner = 'Usage: tool add [options]'
            opts.on('--key KEY', 'Unique identifier') { |v| options[:key] = v }
            opts.on('--path PATH', 'Folder path') { |v| options[:path] = v }
            opts.on('--brand BRAND', 'Brand name') { |v| options[:brand] = v }
            opts.on('-h', '--help', 'Show this message') do
              output.puts opts
              return EXIT_SUCCESS
            end
          end.parse!(args)

          # Validate required options
          unless options[:key] && options[:path]
            output.puts 'Missing required options: --key and --path'
            return EXIT_INVALID_INPUT
          end

          crud = Crud.new(load_config)
          result = crud.add(options)

          if result[:success]
            output.puts "✅ Added: #{options[:key]}"
            EXIT_SUCCESS
          else
            output.puts "❌ Error: #{result[:message]}"
            exit_code_for(result)
          end
        end

        # ... more command methods ...

        # Help system

        def show_main_help
          output.puts 'Tool - Description'
          output.puts ''
          output.puts 'Usage: tool [command] [options]'
          output.puts ''
          output.puts 'Commands:'
          output.puts '  search <terms>      Search locations by fuzzy matching'
          output.puts '  get <key>           Get location by exact key'
          output.puts '  list                List all locations'
          output.puts '  add [options]       Add new location'
          output.puts '  update <key>        Update existing location'
          output.puts '  remove <key>        Remove location'
          output.puts '  validate [key]      Validate paths exist'
          output.puts '  report <type>       Generate reports'
          output.puts '  generate <target>   Generate aliases/help'
          output.puts '  info                Show configuration info'
          output.puts ''
          output.puts "Run 'tool help <command>' for more information on a command."
        end

        def show_version
          output.puts "Tool v#{Appydave::Tools::VERSION}"
          output.puts 'Part of appydave-tools gem'
        end

        def show_help(args)
          topic = args.first

          case topic
          when 'search'
            show_search_help
          when 'add'
            show_add_help
          # ... more help topics ...
          else
            show_main_help
          end
        end

        def show_search_help
          output.puts 'Usage: tool search <terms>'
          output.puts ''
          output.puts 'Search for locations using fuzzy matching.'
          output.puts ''
          output.puts 'Examples:'
          output.puts '  tool search my project'
          output.puts '  tool search appydave ruby'
        end
      end
    end
  end
end
```

### Step 3: Business Logic

**lib/appydave/tools/tool/search.rb**:

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Tool
      # Search provides fuzzy search and exact lookup
      class Search
        def initialize(config)
          @config = config
        end

        def search(query)
          # Fuzzy search implementation
          locations = @config.locations
          matches = locations.select do |loc|
            match_query?(loc, query)
          end

          {
            success: !matches.empty?,
            code: matches.empty? ? 'NOT_FOUND' : nil,
            message: matches.empty? ? 'No matches found' : nil,
            data: matches
          }
        end

        def get(key)
          # Exact key lookup
          location = @config.find_location(key)

          {
            success: !location.nil?,
            code: location.nil? ? 'NOT_FOUND' : nil,
            message: location.nil? ? "Location not found: #{key}" : nil,
            data: location
          }
        end

        def list
          # List all locations
          {
            success: true,
            data: @config.locations
          }
        end

        private

        def match_query?(location, query)
          # Fuzzy matching logic
        end
      end
    end
  end
end
```

---

## Testing Approach

### Testing the CLI Class

**spec/appydave/tools/tool/cli_spec.rb**:

```ruby
# frozen_string_literal: true

RSpec.describe Appydave::Tools::Tool::CLI do
  subject(:cli) { described_class.new(config: mock_config, output: output) }

  let(:output) { StringIO.new }
  let(:mock_config) do
    instance_double(
      Appydave::Tools::Tool::Config,
      locations: mock_locations,
      find_location: mock_location
    )
  end
  let(:mock_locations) do
    [
      { key: 'proj-1', path: '/path/to/proj-1', brand: 'appydave' },
      { key: 'proj-2', path: '/path/to/proj-2', brand: 'voz' }
    ]
  end
  let(:mock_location) { mock_locations.first }

  describe '#run' do
    context 'with no arguments' do
      it 'shows main help and returns success' do
        exit_code = cli.run([])

        expect(output.string).to include('Usage: tool [command]')
        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
      end
    end

    context 'with --help flag' do
      it 'shows main help and returns success' do
        exit_code = cli.run(['--help'])

        expect(output.string).to include('Usage: tool [command]')
        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
      end
    end

    context 'with --version flag' do
      it 'shows version and returns success' do
        exit_code = cli.run(['--version'])

        expect(output.string).to include('Tool v')
        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
      end
    end

    context 'with unknown command' do
      it 'shows error and returns invalid input code' do
        exit_code = cli.run(['unknown'])

        expect(output.string).to include('Unknown command: unknown')
        expect(exit_code).to eq(described_class::EXIT_INVALID_INPUT)
      end
    end
  end

  describe 'search command' do
    it 'searches for locations and returns success' do
      exit_code = cli.run(['search', 'proj', '1'])

      expect(output.string).to include('proj-1')
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end

    it 'returns not found code when no matches' do
      exit_code = cli.run(['search', 'nonexistent'])

      expect(output.string).to include('No matches found')
      expect(exit_code).to eq(described_class::EXIT_NOT_FOUND)
    end
  end

  describe 'get command' do
    it 'gets location by key and returns success' do
      exit_code = cli.run(['get', 'proj-1'])

      expect(output.string).to include('proj-1')
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end

    it 'shows usage when key not provided' do
      exit_code = cli.run(['get'])

      expect(output.string).to include('Usage: tool get <key>')
      expect(exit_code).to eq(described_class::EXIT_INVALID_INPUT)
    end
  end

  describe 'list command' do
    it 'lists all locations and returns success' do
      exit_code = cli.run(['list'])

      expect(output.string).to include('proj-1')
      expect(output.string).to include('proj-2')
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end
  end

  describe 'add command' do
    let(:mock_crud) { instance_double(Appydave::Tools::Tool::Crud) }

    before do
      allow(Appydave::Tools::Tool::Crud).to receive(:new).and_return(mock_crud)
    end

    it 'adds location and returns success' do
      allow(mock_crud).to receive(:add).and_return({ success: true })

      exit_code = cli.run(['add', '--key', 'new-proj', '--path', '/path/to/new'])

      expect(output.string).to include('Added: new-proj')
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end

    it 'shows error when key missing' do
      exit_code = cli.run(['add', '--path', '/path/to/new'])

      expect(output.string).to include('Missing required options')
      expect(exit_code).to eq(described_class::EXIT_INVALID_INPUT)
    end

    it 'returns error code on duplicate key' do
      allow(mock_crud).to receive(:add).and_return({
        success: false,
        code: 'DUPLICATE_KEY',
        message: 'Key already exists'
      })

      exit_code = cli.run(['add', '--key', 'proj-1', '--path', '/path'])

      expect(output.string).to include('Error: Key already exists')
      expect(exit_code).to eq(described_class::EXIT_INVALID_INPUT)
    end
  end

  describe 'error handling' do
    it 'catches exceptions and returns config error code' do
      allow(mock_config).to receive(:locations).and_raise(StandardError, 'Config error')

      exit_code = cli.run(['list'])

      expect(output.string).to include('Error: Config error')
      expect(exit_code).to eq(described_class::EXIT_CONFIG_ERROR)
    end
  end

  describe 'output formatting' do
    it 'supports table format (default)' do
      exit_code = cli.run(['list'])

      expect(output.string).to match(/proj-1.*proj-2/m)
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end

    it 'supports JSON format' do
      exit_code = cli.run(['list', '--format', 'json'])

      json_output = JSON.parse(output.string)
      expect(json_output).to be_an(Array)
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end

    it 'supports paths format' do
      exit_code = cli.run(['list', '--format', 'paths'])

      expect(output.string).to include('/path/to/proj-1')
      expect(output.string).to include('/path/to/proj-2')
      expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    end
  end
end
```

**Key testing benefits:**
- ✅ Test exit codes (success, errors)
- ✅ Test output messages
- ✅ Test error handling
- ✅ Mock dependencies (config, validators)
- ✅ Test all commands independently

---

## Pattern 3 vs Pattern 4

### Side-by-Side Comparison

| Aspect | Pattern 3 (BaseAction) | Pattern 4 (Delegated CLI) |
|--------|------------------------|---------------------------|
| **CLI location** | bin/ (not testable) | lib/ (fully testable) |
| **Command dispatch** | Method hash (`'cmd' => Action.new`) | Case/when (`when 'cmd'`) |
| **Shared validation** | ✅ Template method in BaseAction | ⚠️ Manual (extract to modules) |
| **Exit codes** | ⚠️ Manual implementation | ✅ Built-in constants |
| **Dependency injection** | ❌ No | ✅ Yes (config, output, validators) |
| **CLI testing** | ❌ Hard (bin/ scripts) | ✅ Easy (RSpec with mocks) |
| **Scalability** | ✅ Good (6-20 commands) | ✅ Excellent (10+ commands) |
| **Consistency** | ✅ Enforced by BaseAction | ⚠️ Manual (conventions) |
| **Best for** | API-style commands | Complex CLI tools |
| **Example** | youtube_manager | jump |
| **Bin/ size** | ~80 lines | ~30 lines |
| **Lib/ size** | Actions + business logic | CLI + business logic |

### When to Choose Pattern 4 Over Pattern 3

**Choose Pattern 4 if:**
1. ✅ You want to **test CLI behavior** (not just business logic)
2. ✅ Tool has **10+ commands** (case/when scales better)
3. ✅ Need **professional exit codes** (Unix conventions)
4. ✅ Want **dependency injection** for testing
5. ✅ Building a **production tool** (not internal script)
6. ✅ CLI complexity > 300 lines

**Choose Pattern 3 if:**
1. ✅ Commands **share validation patterns** (BaseAction enforces)
2. ✅ **6-9 commands** (not quite 10+)
3. ✅ Don't need CLI testing (business logic tests sufficient)
4. ✅ **Template method** is beneficial
5. ✅ Team prefers **OOP patterns** (inheritance)

---

## Migration Guide

### Migrating from Pattern 2 to Pattern 4

**Example: DAM tool (1,603 lines in bin/)**

#### Before (Pattern 2)

```
bin/dam (1,603 lines)
  ├── class VatCLI
  ├── def run
  ├── def list_command (100 lines)
  ├── def s3_up_command (150 lines)
  ├── def s3_down_command (150 lines)
  └── ... 15 more command methods
```

#### After (Pattern 4)

```
bin/dam (30 lines)
  ├── require 'appydave/tools'
  ├── cli = Appydave::Tools::Dam::CLI.new
  └── exit(cli.run(ARGV))

lib/appydave/tools/dam/
  ├── cli.rb (600 lines - testable!)
  │   ├── class CLI
  │   ├── def run(args)
  │   ├── def run_list
  │   ├── def run_s3_up
  │   └── ... command methods
  ├── s3_operations.rb (300 lines)
  ├── ssd_operations.rb (200 lines)
  └── config.rb (100 lines)

spec/appydave/tools/dam/
  ├── cli_spec.rb (NEW - test CLI!)
  ├── s3_operations_spec.rb
  └── ssd_operations_spec.rb
```

#### Migration Steps

1. **Create lib/tool/cli.rb**
   ```bash
   mkdir -p lib/appydave/tools/dam
   touch lib/appydave/tools/dam/cli.rb
   ```

2. **Move CLI class from bin/ to lib/**
   - Copy `VatCLI` class to `lib/appydave/tools/dam/cli.rb`
   - Rename class to `CLI`
   - Wrap in module: `Appydave::Tools::Dam::CLI`

3. **Add dependency injection**
   ```ruby
   def initialize(config: nil, output: $stdout)
     @output = output
     @config = config
   end
   ```

4. **Convert method hash to case/when**
   ```ruby
   # Before (Pattern 2)
   @commands = {
     'list' => method(:list_command),
     's3-up' => method(:s3_up_command)
   }

   # After (Pattern 4)
   case command
   when 'list'
     run_list(args)
   when 's3-up'
     run_s3_up(args)
   end
   ```

5. **Add exit codes**
   ```ruby
   EXIT_SUCCESS = 0
   EXIT_NOT_FOUND = 1
   EXIT_INVALID_INPUT = 2
   EXIT_CONFIG_ERROR = 3

   def run(args)
     case command
     when 'list'
       run_list(args)
     else
       output.puts "Unknown command"
       EXIT_INVALID_INPUT
     end
   end
   ```

6. **Replace bin/ with thin wrapper**
   ```ruby
   #!/usr/bin/env ruby
   # frozen_string_literal: true

   $LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
   require 'appydave/tools'

   cli = Appydave::Tools::Dam::CLI.new
   exit_code = cli.run(ARGV)
   exit(exit_code)
   ```

7. **Create CLI tests**
   ```bash
   touch spec/appydave/tools/dam/cli_spec.rb
   ```

8. **Test migration**
   ```bash
   # Run CLI tests
   rspec spec/appydave/tools/dam/cli_spec.rb

   # Test actual CLI
   bin/dam list
   bin/dam --version
   ```

---

## Real-World Example: Jump

The **Jump tool** is the reference implementation of Pattern 4 in appydave-tools.

### Stats

| Metric | Value |
|--------|-------|
| Commands | 10 |
| bin/jump.rb | 29 lines |
| lib/jump/cli.rb | 400+ lines |
| Exit codes | 5 (0-4) |
| Formatters | 3 (table, json, paths) |
| Help topics | 8+ |

### Architecture

**bin/jump.rb** (29 lines):
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Jump Location Tool - Manage development folder locations
#
# Usage:
#   jump search <terms>           # Fuzzy search locations
#   jump get <key>                # Get by exact key
#   jump list                     # List all locations
#   jump add --key <key> --path <path>  # Add new location
#
# Examples:
#   jump search appydave ruby
#   jump add --key my-proj --path ~/dev/my-proj --brand appydave

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

cli = Appydave::Tools::Jump::CLI.new
exit_code = cli.run(ARGV)
exit(exit_code)
```

**lib/appydave/tools/jump/cli.rb** (excerpt):

```ruby
module Appydave
  module Tools
    module Jump
      # CLI provides the command-line interface for the Jump tool
      class CLI
        EXIT_SUCCESS = 0
        EXIT_NOT_FOUND = 1
        EXIT_INVALID_INPUT = 2
        EXIT_CONFIG_ERROR = 3
        EXIT_PATH_NOT_FOUND = 4

        attr_reader :config, :path_validator, :output

        def initialize(config: nil, path_validator: nil, output: $stdout)
          @path_validator = path_validator || PathValidator.new
          @output = output
          @config = config
        end

        def run(args = ARGV)
          command = args.shift

          case command
          when nil, '', '--help', '-h'
            show_main_help
            EXIT_SUCCESS
          when '--version', '-v'
            show_version
            EXIT_SUCCESS
          when 'help'
            show_help(args)
            EXIT_SUCCESS
          when 'search'
            run_search(args)
          when 'get'
            run_get(args)
          when 'list'
            run_list(args)
          when 'add'
            run_add(args)
          when 'update'
            run_update(args)
          when 'remove'
            run_remove(args)
          when 'validate'
            run_validate(args)
          when 'report'
            run_report(args)
          when 'generate'
            run_generate(args)
          when 'info'
            run_info(args)
          else
            output.puts "Unknown command: #{command}"
            EXIT_INVALID_INPUT
          end
        rescue StandardError => e
          output.puts "Error: #{e.message}"
          EXIT_CONFIG_ERROR
        end

        # ... command implementations ...
      end
    end
  end
end
```

### Why Jump Uses Pattern 4

1. ✅ **10 commands** - Scales well with case/when
2. ✅ **Complex CLI** - 400+ lines would bloat bin/
3. ✅ **Testable** - Full CLI test coverage via RSpec
4. ✅ **Exit codes** - Professional Unix exit codes
5. ✅ **Dependency injection** - Mock config/validators in tests
6. ✅ **Professional tool** - Production-grade development tool

### File Structure

```
lib/appydave/tools/jump/
├── cli.rb                      # CLI class (400+ lines)
├── config.rb                   # Configuration
├── search.rb                   # Search/query logic
├── crud.rb                     # Add/update/remove
├── validators/
│   └── path_validator.rb       # Path validation
├── formatters/
│   ├── table_formatter.rb      # Table output
│   ├── json_formatter.rb       # JSON output
│   └── paths_formatter.rb      # Paths-only output
└── generators/
    └── aliases_generator.rb    # Generate shell aliases

spec/appydave/tools/jump/
├── cli_spec.rb                 # CLI tests (exit codes, output)
├── search_spec.rb              # Search logic tests
├── crud_spec.rb                # CRUD tests
└── ... more tests
```

---

## Summary

**Pattern 4: Delegated CLI Class** is the professional-grade CLI pattern for:

✅ **10+ commands** - Case/when dispatch scales well
✅ **300+ lines of CLI logic** - Justifies separate class
✅ **Testable CLI** - Full RSpec coverage of CLI behavior
✅ **Exit codes** - Professional Unix conventions
✅ **Dependency injection** - Mock dependencies for testing
✅ **Production tools** - Professional-grade architecture

**Key files:**
- `bin/tool.rb` (30 lines) - Thin wrapper
- `lib/tool/cli.rb` (400+ lines) - Full CLI implementation
- `spec/tool/cli_spec.rb` (100+ lines) - CLI tests

**Reference implementation:** Jump tool (`bin/jump.rb` → `lib/appydave/tools/jump/cli.rb`)

**When to use:**
- Building a professional CLI tool
- Need to test CLI behavior
- 10+ commands
- Complex error handling

**When not to use:**
- Simple tools (< 10 commands) → Use Pattern 2
- Don't need CLI testing → Use Pattern 2 or 3
- Commands share validation → Consider Pattern 3

---

**Last updated:** 2025-02-04
