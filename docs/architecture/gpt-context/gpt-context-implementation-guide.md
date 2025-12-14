# GPT Context Gatherer - Implementation Guide

**For developers** working on or extending the GPT Context module.

---

## File Structure

```
lib/appydave/tools/gpt_context/
├── _doc.md              # Legacy internal notes
├── options.rb           # Options struct definition
├── file_collector.rb    # Core file gathering logic
└── output_handler.rb    # Output delivery (clipboard/file)

bin/
└── gpt_context.rb       # CLI entry point

spec/appydave/tools/gpt_context/
├── file_collector_spec.rb
├── options_spec.rb
└── output_handler_spec.rb
```

---

## Component Details

### Options Struct

**Location**: `lib/appydave/tools/gpt_context/options.rb:7-27`

```ruby
Options = Struct.new(
  :include_patterns,
  :exclude_patterns,
  :format,
  :line_limit,
  :debug,
  :output_target,
  :working_directory,
  :prompt,
  keyword_init: true
) do
  def initialize(**args)
    super
    self.include_patterns ||= []
    self.exclude_patterns ||= []
    self.format ||= 'tree,content'
    self.debug ||= 'none'
    self.output_target ||= []
    self.prompt ||= nil
  end
end
```

**Key implementation notes**:

1. **Struct with keyword_init** - Enables `Options.new(format: 'json')` syntax
2. **Mutable defaults** - Arrays are initialized in `initialize`, not in Struct definition (avoids shared state)
3. **No validation** - Relies on CLI layer for validation

### FileCollector

**Location**: `lib/appydave/tools/gpt_context/file_collector.rb:8-146`

#### Constructor

```ruby
def initialize(options)
  @options = options
  @include_patterns = options.include_patterns
  @exclude_patterns = options.exclude_patterns
  @format = options.format
  @working_directory = File.expand_path(options.working_directory)
  @line_limit = options.line_limit
end
```

**Note**: `File.expand_path` converts relative paths to absolute.

#### Main Entry Point

```ruby
def build
  FileUtils.cd(@working_directory) if @working_directory && Dir.exist?(@working_directory)

  formats = @format.split(',')
  result = formats.map do |fmt|
    case fmt
    when 'tree'    then build_tree
    when 'content' then build_content
    when 'json'    then build_json
    when 'aider'   then build_aider
    else ''
    end
  end.join("\n\n")

  FileUtils.cd(Dir.home) if @working_directory

  result
end
```

**Key points**:
- Changes to working directory for relative pattern matching
- Supports comma-separated formats
- Returns to home directory (not original pwd) after - potential improvement opportunity

#### Tree Building Algorithm

```ruby
def build_tree
  tree_view = {}

  @include_patterns.each do |pattern|
    Dir.glob(pattern).each do |file_path|
      next if excluded?(file_path)

      path_parts = file_path.split('/')
      insert_into_tree(tree_view, path_parts)
    end
  end

  build_tree_pretty(tree_view).rstrip
end

def insert_into_tree(tree, path_parts)
  node = tree
  path_parts.each do |part|
    node[part] ||= {}
    node = node[part]
  end
end
```

**Algorithm**:
1. Build nested hash from file paths
2. Each path segment becomes a key
3. Empty hash `{}` represents leaf nodes (files)

#### Tree Rendering

```ruby
def build_tree_pretty(node, prefix: '', is_last: true, output: ''.dup)
  node.each_with_index do |(part, child), index|
    connector = is_last && index == node.size - 1 ? '└' : '├'
    output << "#{prefix}#{connector}─ #{part}\n"
    next_prefix = is_last && index == node.size - 1 ? '  ' : '│ '
    build_tree_pretty(child,
                      prefix: "#{prefix}#{next_prefix}",
                      is_last: child.empty? || index == node.size - 1,
                      output: output)
  end
  output
end
```

**Box-drawing characters**:
- `├` - branch with siblings below
- `└` - last branch (no siblings below)
- `│` - vertical continuation
- `─` - horizontal line

#### Content Building

```ruby
def build_content
  concatenated_content = []

  @include_patterns.each do |pattern|
    Dir.glob(pattern).each do |file_path|
      next if excluded?(file_path) || File.directory?(file_path)

      content = "# file: #{file_path}\n\n#{read_file_content(file_path)}"
      concatenated_content << content
    end
  end

  concatenated_content.join("\n\n")
end

def read_file_content(file_path)
  lines = File.readlines(file_path)
  return lines.first(@line_limit).join if @line_limit

  lines.join
end
```

**Format**: Each file gets a header `# file: path/to/file.rb` followed by content.

#### Exclusion Logic

```ruby
def excluded?(file_path)
  @exclude_patterns.any? do |pattern|
    File.fnmatch(pattern, file_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
  end
end
```

**Flags**:
- `FNM_PATHNAME` - `*` won't match `/` (so `*.rb` won't match `lib/foo.rb`)
- `FNM_DOTMATCH` - `*` will match dotfiles

### OutputHandler

**Location**: `lib/appydave/tools/gpt_context/output_handler.rb:7-36`

```ruby
class OutputHandler
  def initialize(content, options)
    @content = content
    @output_targets = options.output_target
    @working_directory = options.working_directory
  end

  def execute
    @output_targets.each do |target|
      case target
      when 'clipboard'
        Clipboard.copy(@content)
      when /^.+$/
        write_to_file(target)
      end
    end
  end

  private

  def write_to_file(target)
    resolved_path = Pathname.new(target).absolute? ? target : File.join(working_directory, target)
    File.write(resolved_path, content)
  end
end
```

**Key points**:
- Supports multiple output targets (can write to clipboard AND files)
- Relative paths resolved against working directory
- Uses `Pathname#absolute?` for path detection

---

## CLI Implementation

**Location**: `bin/gpt_context.rb`

### Option Parsing

```ruby
options = Appydave::Tools::GptContext::Options.new(working_directory: nil)

OptionParser.new do |opts|
  opts.on('-i', '--include PATTERN', 'Pattern or file to include') do |pattern|
    options.include_patterns << pattern
  end
  # ... more options
end.parse!
```

**Pattern**: Direct mutation of Options struct during parsing.

### Default Application

```ruby
if options.output_target.empty?
  puts 'No output target provided. Will default to `clipboard`.'
  options.output_target << 'clipboard'
end

options.working_directory ||= Dir.pwd
```

### Execution Flow

```ruby
gatherer = Appydave::Tools::GptContext::FileCollector.new(options)
content = gatherer.build

if %w[info debug].include?(options.debug)
  puts '-' * 80
  puts content
  puts '-' * 80
end

output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute
```

---

## Testing Strategy

### Unit Tests

Each component should be tested in isolation:

```ruby
# Options
describe Appydave::Tools::GptContext::Options do
  it 'initializes with defaults' do
    options = described_class.new
    expect(options.include_patterns).to eq([])
    expect(options.format).to eq('tree,content')
  end
end

# FileCollector
describe Appydave::Tools::GptContext::FileCollector do
  let(:options) { Appydave::Tools::GptContext::Options.new(...) }
  let(:collector) { described_class.new(options) }

  it 'builds tree format' do
    # Test with fixture files
  end
end
```

### Integration Tests

Test full CLI flow:

```ruby
describe 'gpt_context CLI' do
  it 'gathers files and outputs to clipboard' do
    # Shell out to bin/gpt_context.rb
    # Verify clipboard contents
  end
end
```

### Fixture Files

Use `spec/fixtures/gpt-content-gatherer/` for test files.

---

## Extension Points

### Adding a New Format

1. Add format name to Options validation (if any)
2. Add case in `FileCollector#build`:

```ruby
when 'my_format'
  build_my_format
```

3. Implement `build_my_format` method:

```ruby
def build_my_format
  # Return string
end
```

### Adding a New Output Target

1. Add case in `OutputHandler#execute`:

```ruby
when 'my_target'
  handle_my_target
```

2. Implement handler method:

```ruby
def handle_my_target
  # Do something with @content
end
```

### Adding CLI Options

1. Add property to Options struct
2. Add `opts.on` in CLI
3. Use property in appropriate component

---

## Known Limitations

### Current Issues

1. **Working directory handling** - Returns to `Dir.home` instead of original pwd
2. **No error handling** - File read errors propagate as exceptions
3. **Memory usage** - All content loaded into memory (no streaming)
4. **Debug output** - `puts` statements in production code

### Improvement Opportunities

1. **Token counting** - Add estimated token count for LLM context limits
2. **Caching** - Cache file listings for repeated runs
3. **Parallel reading** - Read files in parallel for large codebases
4. **Streaming output** - Stream to file instead of building in memory

---

## Code Quality Checklist

When modifying GPT Context code:

- [ ] All files start with `# frozen_string_literal: true`
- [ ] RuboCop passes with no offenses
- [ ] Specs pass for all components
- [ ] No `puts` or `pp` in library code (only CLI)
- [ ] Options struct remains backward-compatible
- [ ] Documentation updated if API changes

---

**Related Documentation**:
- [Vision & Strategy](./gpt-context-vision.md)
- [Architecture & Data Flow](./gpt-context-architecture.md)
- [Usage Guide](../../guides/tools/gpt-context.md)
