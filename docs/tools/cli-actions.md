# CLI Actions Framework

Base framework and pattern for building command-line actions with option parsing, validation, and execution.

## What It Does

**CLI Actions** provides a template method pattern for building consistent CLI tools:

- Base class for all CLI operations
- Handles option parsing automatically
- Enforces validation before execution
- Provides consistent help messages
- Simplifies building new CLI commands

## Architecture

CLI Actions use the Template Method pattern:

```
BaseAction (abstract)
├── GetVideoAction (retrieves YouTube video details)
├── UpdateVideoAction (updates video metadata)
└── PromptCompletionAction (generates completions)
```

Each action follows this lifecycle:

```
1. Parse Options (convert command-line args to options dict)
2. Validate Options (ensure required options are present)
3. Execute (perform the actual work with validated options)
```

## How to Use

### Using Existing Actions

Actions are invoked through CLI commands:

```bash
# GetVideoAction via youtube_manager
youtube_manager get -v dQw4w9WgXcQ

# UpdateVideoAction via youtube_manager
youtube_manager update -v dQw4w9WgXcQ -t "New Title"

# PromptCompletionAction via prompt_tools (deprecated)
prompt_tools completion -p "Your prompt here"
```

### Creating New Actions

Inherit from BaseAction:

```ruby
module Appydave
  module Tools
    module CliActions
      class MyNewAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-n', '--name NAME', 'User name') { |v| options[:name] = v }
          opts.on('-e', '--email EMAIL', 'Email address') { |v| options[:email] = v }
        end

        def validate_options(options)
          raise ArgumentError, 'Name required' unless options[:name]
          raise ArgumentError, 'Email required' unless options[:email]
        end

        def execute(options)
          puts "Hello #{options[:name]}!"
          puts "Email: #{options[:email]}"
        end
      end
    end
  end
end
```

### Invoke the Action

```ruby
action = Appydave::Tools::CliActions::MyNewAction.new
action.action(['-n', 'John', '-e', 'john@example.com'])
# Output: Hello John!
#         Email: john@example.com
```

## API Reference

### BaseAction

Base class for all CLI actions:

```ruby
class BaseAction
  # Main entry point
  def action(args)
    # Parses options, validates, executes
  end

  protected

  # Override in subclasses
  def define_options(opts, options)
    # Define command-line options
    # Use opts.on() to add options
  end

  def validate_options(options)
    # Validate parsed options
    # Raise ArgumentError if invalid
  end

  def execute(options)
    # Perform the actual work
    # options contains parsed and validated options
  end

  # Generated automatically based on class name
  def command_usage
    # "myaction [options]"
  end
end
```

## Included Actions

### GetVideoAction

Retrieves YouTube video metadata:

```ruby
action = Appydave::Tools::CliActions::GetVideoAction.new
action.action(['-v', 'dQw4w9WgXcQ'])
```

**Options**:
- `-v` / `--video-id` VIDEO_ID - YouTube video ID (required)

**Output**: Video details (title, description, tags, category, metrics)

### UpdateVideoAction

Updates YouTube video metadata:

```ruby
action = Appydave::Tools::CliActions::UpdateVideoAction.new
action.action(['-v', 'dQw4w9WgXcQ', '-t', 'New Title'])
```

**Options**:
- `-v` / `--video-id` VIDEO_ID - YouTube video ID (required)
- `-t` / `--title` TITLE - New video title
- `-d` / `--description` DESC - New description
- `-g` / `--tags` TAGS - Comma-separated tags
- `-c` / `--category-id` ID - YouTube category ID

**Output**: Confirmation of updated fields

### PromptCompletionAction

⚠️ **DEPRECATED**: Uses legacy OpenAI API. See prompt-tools.md.

Generates text completions:

```ruby
action = Appydave::Tools::CliActions::PromptCompletionAction.new
action.action(['-p', 'Write a haiku about programming'])
```

**Options**:
- `-p` / `--prompt` TEXT - Prompt text (required)
- `-m` / `--model` MODEL - Model name (default: text-davinci-003)
- `-t` / `--temperature` NUM - Randomness 0-2
- `-l` / `--max-tokens` NUM - Max response length

**Note**: Uses deprecated API, plan migration to modern alternatives.

## Use Cases for AI Agents

### 1. Building Custom Actions
```ruby
# AI creates new CLI action for specific task
# Inherits from BaseAction, implements template methods
class MyAction < BaseAction
  protected
  def define_options(opts, options)
    # Define CLI options
  end
  def validate_options(options)
    # Validate inputs
  end
  def execute(options)
    # Do work
  end
end
```
**AI discovers**: Template pattern, structure. Can build new CLI tools quickly.

### 2. Action Composition
```ruby
# AI chains multiple actions
get_action = GetVideoAction.new
get_action.action(['-v', video_id])

update_action = UpdateVideoAction.new
update_action.action(['-v', video_id, '-t', 'Updated Title'])
```
**AI discovers**: How to orchestrate multiple operations. Can build workflows.

### 3. Error Handling
```ruby
# AI wraps actions with error handling
begin
  action = MyAction.new
  action.action(args)
rescue ArgumentError => e
  puts "Validation error: #{e.message}"
rescue => e
  puts "Execution error: #{e.message}"
end
```
**AI discovers**: Error handling patterns. Can build robust CLI tools.

### 4. Option Preprocessing
```ruby
# AI modifies options before execution
action = MyAction.new
options = parse_custom_format(input)
# Transform to standard format
standard_options = transform_to_action_format(options)
action.action(standard_options)
```
**AI discovers**: Option flow. Can preprocess inputs for actions.

### 5. Batch Action Execution
```ruby
# AI executes action multiple times
items.each do |item|
  action = MyAction.new
  action.action(['-i', item])
end
```
**AI discovers**: Repetition pattern. Can automate batch operations.

### 6. Action Validation
```ruby
# AI tests action definition
action = MyAction.new
test_options = ['-required', 'value']
begin
  action.action(test_options)
rescue ArgumentError => e
  puts "Validation working: #{e.message}"
end
```
**AI discovers**: Validation logic. Can test actions before deployment.

### 7. Help Message Extraction
```ruby
# AI generates documentation from actions
action = MyAction.new
usage = action.command_usage
# Generate docs from action definition
```
**AI discovers**: Command structure. Can auto-generate documentation.

### 8. Dynamic Action Creation
```ruby
# AI creates actions dynamically
action_class = Class.new(BaseAction) do
  protected
  def define_options(opts, options)
    # ...
  end
  def validate_options(options)
    # ...
  end
  def execute(options)
    # ...
  end
end

action = action_class.new
action.action(args)
```
**AI discovers**: Metaprogramming patterns. Can generate actions on-the-fly.

### 9. Action Composition Framework
```ruby
# AI builds workflow from action definitions
workflow = [
  { action: GetVideoAction, args: ['-v', video_id] },
  { action: UpdateVideoAction, args: ['-v', video_id, '-t', new_title] },
  { action: PublishAction, args: ['-v', video_id] }
]

workflow.each do |step|
  action = step[:action].new
  action.action(step[:args])
end
```
**AI discovers**: Workflow composition. Can orchestrate complex processes.

### 10. Template Enforcement
```ruby
# AI validates that all actions follow template
# Check that subclasses implement required methods
unless MyAction.instance_methods(false).include?(:execute)
  raise "Action must implement execute method"
end
```
**AI discovers**: Pattern compliance. Can enforce architecture.

## Creating Custom Actions

### Step 1: Define the Class

```ruby
module Appydave
  module Tools
    module CliActions
      class EmailAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-t', '--to EMAIL', 'Recipient email') { |v| options[:to] = v }
          opts.on('-s', '--subject TEXT', 'Email subject') { |v| options[:subject] = v }
          opts.on('-b', '--body TEXT', 'Email body') { |v| options[:body] = v }
        end

        def validate_options(options)
          raise ArgumentError, 'Recipient required' unless options[:to]
          raise ArgumentError, 'Subject required' unless options[:subject]
        end

        def execute(options)
          # Send email logic
          puts "Sending email to #{options[:to]}"
          puts "Subject: #{options[:subject]}"
        end
      end
    end
  end
end
```

### Step 2: Test the Action

```ruby
action = EmailAction.new
action.action(['-t', 'user@example.com', '-s', 'Hello'])
# Output: Sending email to user@example.com
#         Subject: Hello
```

### Step 3: Integrate with CLI

```ruby
# In your CLI script
class MyCLI
  def initialize
    @commands = {
      'email' => Appydave::Tools::CliActions::EmailAction.new
    }
  end

  def run
    command, *args = ARGV
    @commands[command].action(args) if @commands[command]
  end
end
```

## Best Practices

1. **Validate early**: Check all required options in validate_options
2. **Fail fast**: Raise ArgumentError immediately if validation fails
3. **Clear messages**: Provide specific error messages for validation failures
4. **Define all options**: Document every option in define_options
5. **Keep execute focused**: One action per class, single responsibility
6. **Test thoroughly**: Test each action independently before using
7. **Document options**: Add comments explaining what options do
8. **Handle errors gracefully**: Catch and report errors in execute

## Example: Complete Action

```ruby
module Appydave
  module Tools
    module CliActions
      class FetchDataAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-u', '--url URL', 'API endpoint') { |v| options[:url] = v }
          opts.on('-f', '--format FORMAT', 'Output format') { |v| options[:format] = v }
          opts.on('-t', '--timeout SEC', Integer, 'Request timeout') { |v| options[:timeout] = v }
        end

        def validate_options(options)
          raise ArgumentError, 'URL required' unless options[:url]
          options[:format] ||= 'json'
          options[:timeout] ||= 30
        end

        def execute(options)
          url = options[:url]
          format = options[:format]
          timeout = options[:timeout]

          puts "Fetching from #{url}"
          puts "Format: #{format}"
          puts "Timeout: #{timeout}s"

          # Actual fetch logic here
        end
      end
    end
  end
end
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Unknown option" | Define option in define_options with opts.on |
| "Validation error" | Check validate_options, ensure required options set |
| "Method not implemented" | Define execute method in subclass |
| "Wrong argument count" | Check action() is called with args array |

---

**Related Tools**:
- All CLI commands use CLI Actions framework
- `youtube_manager` - Uses GetVideoAction, UpdateVideoAction
- `prompt_tools` - Uses PromptCompletionAction (deprecated)

**Pattern**: Template Method Pattern for consistent CLI behavior
**Architecture**: Part of appydave-tools internal framework
