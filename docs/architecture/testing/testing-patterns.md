# Testing Patterns Guide

This guide documents the testing patterns and conventions used in appydave-tools. Follow these patterns when writing tests for new tools or maintaining existing ones.

## Table of Contents

- [Philosophy](#philosophy)
- [Directory Structure](#directory-structure)
- [RSpec Conventions](#rspec-conventions)
- [Test Business Logic, Not CLI](#test-business-logic-not-cli)
- [Spec Helper Configuration](#spec-helper-configuration)
- [Fixture Management](#fixture-management)
- [HTTP Mocking with VCR](#http-mocking-with-vcr)
- [Configuration in Tests](#configuration-in-tests)
- [Guard for Continuous Testing](#guard-for-continuous-testing)
- [Common Patterns](#common-patterns)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Philosophy

### Core Principles

1. **Test business logic, not CLI executables** - Focus on `lib/` classes, not `bin/` scripts
2. **No require statements in specs** - `spec_helper.rb` handles all loading
3. **Isolated tests** - Each test should be independent and not rely on external state
4. **Mock external services** - Use VCR for HTTP calls, WebMock for network isolation
5. **Fast feedback** - Use Guard for continuous testing during development

### Why This Matters

```
bin/                           ← CLI layer (thin wrapper, not tested directly)
  └── tool.rb

lib/appydave/tools/            ← Business logic (THIS IS WHAT WE TEST)
  └── tool_name/
      ├── processor.rb         ← Unit tests focus here
      └── validator.rb         ← And here

spec/appydave/tools/           ← Tests mirror lib/ structure
  └── tool_name/
      ├── processor_spec.rb
      └── validator_spec.rb
```

**The CLI layer is a thin wrapper.** It parses arguments and calls business logic. Testing CLI directly is:
- Fragile (depends on exact output format)
- Slow (spawns processes)
- Unnecessary (business logic tests cover the important parts)

---

## Directory Structure

### Test Files Mirror lib/ Structure

```
lib/appydave/tools/subtitle_processor/clean.rb
spec/appydave/tools/subtitle_processor/clean_spec.rb

lib/appydave/tools/dam/s3_operations.rb
spec/appydave/tools/dam/s3_operations_spec.rb
```

### Complete Test Directory Layout

```
spec/
├── spec_helper.rb              # Main configuration (loads all dependencies)
├── support/                    # Shared test helpers
│   └── dam_filesystem_helpers.rb
├── fixtures/                   # Test data files
│   ├── subtitle_processor/
│   │   ├── sample.srt
│   │   └── expected_output.srt
│   ├── zsh_history/
│   │   └── sample_history
│   └── ...
├── vcr_cassettes/              # Recorded HTTP responses
│   └── youtube_manager/
│       └── get_video.yml
└── appydave/
    └── tools/
        ├── subtitle_processor/
        │   ├── clean_spec.rb
        │   └── join_spec.rb
        ├── dam/
        │   ├── s3_operations_spec.rb
        │   └── brand_resolver_spec.rb
        └── ...
```

---

## RSpec Conventions

### No Require Statements

**All requires are handled by `spec_helper.rb`.** Never add require statements to individual spec files.

```ruby
# spec/appydave/tools/subtitle_processor/clean_spec.rb
# frozen_string_literal: true

# NO require statements needed - spec_helper handles everything

RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  # Tests
end
```

### Frozen String Literal

All spec files must start with:

```ruby
# frozen_string_literal: true
```

### Describe Block Naming

Use the full module path for the describe block:

```ruby
# Good
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do

# Bad - missing namespace
RSpec.describe Clean do
```

### Subject Definition

Define subject for the class under test:

```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  subject { described_class.new(srt_content: sample_content) }

  let(:sample_content) { "1\n00:00:00,000 --> 00:00:01,000\nHello" }

  describe '#clean' do
    it 'processes the content' do
      expect(subject.clean).to be_a(String)
    end
  end
end
```

### Let vs Instance Variables

Prefer `let` and `let!` over instance variables:

```ruby
# Good
let(:options) { { file: 'test.srt', output: 'output.srt' } }
let(:processor) { described_class.new(**options) }

# Bad - instance variables in before blocks
before do
  @options = { file: 'test.srt', output: 'output.srt' }
  @processor = described_class.new(**@options)
end
```

### Context vs Describe

- Use `describe` for methods or logical groupings
- Use `context` for different states or conditions

```ruby
RSpec.describe Appydave::Tools::Dam::BrandResolver do
  describe '.resolve' do
    context 'when brand exists' do
      it 'returns the brand directory' do
        # ...
      end
    end

    context 'when brand does not exist' do
      it 'raises an error' do
        # ...
      end
    end
  end
end
```

---

## Test Business Logic, Not CLI

### Good: Testing Business Logic

```ruby
# spec/appydave/tools/subtitle_processor/clean_spec.rb
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  subject { described_class.new(srt_content: sample_srt) }

  let(:sample_srt) do
    <<~SRT
      1
      00:00:00,000 --> 00:00:02,000
      <u>Hello world</u>
    SRT
  end

  describe '#clean' do
    it 'removes underline HTML tags' do
      result = subject.clean
      expect(result).not_to include('<u>')
      expect(result).not_to include('</u>')
    end

    it 'preserves subtitle content' do
      result = subject.clean
      expect(result).to include('Hello world')
    end
  end

  describe '#write' do
    let(:temp_file) { Tempfile.new(['test', '.srt']) }

    after { temp_file.unlink }

    it 'writes cleaned content to file' do
      subject.clean
      subject.write(temp_file.path)

      expect(File.read(temp_file.path)).to include('Hello world')
    end
  end
end
```

### Bad: Testing CLI Executables

```ruby
# DON'T DO THIS - fragile, slow, unnecessary
RSpec.describe 'bin/subtitle_processor.rb' do
  it 'runs clean command' do
    output = `bin/subtitle_processor.rb clean -f test.srt -o output.srt`
    expect(output).to include('Processed')
  end
end
```

### When CLI Testing Makes Sense

In rare cases, integration tests for CLI may be warranted:
- End-to-end smoke tests
- Verifying exit codes
- Testing CLI-specific error messages

But these should be few and clearly marked:

```ruby
# spec/integration/cli/subtitle_processor_cli_spec.rb
RSpec.describe 'Subtitle Processor CLI', :integration do
  # Integration tests here
end
```

---

## Spec Helper Configuration

### Current spec_helper.rb Setup

```ruby
# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'simplecov'

SimpleCov.start

require 'appydave/tools'
require 'webmock/rspec'
require 'vcr'

# Load shared helpers
require_relative 'support/dam_filesystem_helpers'

# Configure default test configuration
Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
  config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
  config.register(:brands, Appydave::Tools::Configuration::Models::BrandsConfig)
  config.register(:channels, Appydave::Tools::Configuration::Models::ChannelsConfig)
  config.register(:youtube_automation, Appydave::Tools::Configuration::Models::YoutubeAutomationConfig)
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus

  # Skip tools_enabled tests unless explicitly enabled
  config.filter_run_excluding :tools_enabled unless ENV['TOOLS_ENABLED'] == 'true'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    if ENV['TOOLS_ENABLED'] == 'true'
      WebMock.allow_net_connect!
    else
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end
end
```

### Key Configuration Points

| Setting | Purpose |
|---------|---------|
| `SimpleCov.start` | Code coverage reporting |
| `config_path = Dir.mktmpdir` | Isolated temp config for each test run |
| `:tools_enabled` filter | Skip external API tests in CI |
| `WebMock.disable_net_connect!` | Block real HTTP in tests |
| `.rspec_status` | Enable `--only-failures` and `--next-failure` |

---

## Fixture Management

### Location

Fixtures live in `spec/fixtures/` organized by tool:

```
spec/fixtures/
├── subtitle_processor/
│   ├── sample.srt
│   ├── sample_with_tags.srt
│   └── expected_clean_output.srt
├── zsh_history/
│   └── sample_history
└── dam/
    └── sample_manifest.json
```

### Loading Fixtures

```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  let(:fixture_path) { File.expand_path('../../fixtures/subtitle_processor', __dir__) }
  let(:sample_srt) { File.read(File.join(fixture_path, 'sample.srt')) }

  subject { described_class.new(srt_content: sample_srt) }

  # ...
end
```

### Shared Fixture Helper

For frequently accessed fixtures, create a helper in `spec/support/`:

```ruby
# spec/support/fixture_helpers.rb
module FixtureHelpers
  def fixture_path(tool, filename)
    File.expand_path("../fixtures/#{tool}/#{filename}", __dir__)
  end

  def load_fixture(tool, filename)
    File.read(fixture_path(tool, filename))
  end
end

# In spec_helper.rb
RSpec.configure do |config|
  config.include FixtureHelpers
end

# In specs
let(:sample_srt) { load_fixture('subtitle_processor', 'sample.srt') }
```

---

## HTTP Mocking with VCR

### Recording Cassettes

VCR records HTTP interactions for replay in tests:

```ruby
RSpec.describe Appydave::Tools::YouTubeManager::GetVideo do
  describe '#get', :vcr do
    it 'retrieves video metadata' do
      video = described_class.new
      video.get('dQw4w9WgXcQ')

      expect(video.data).to include('title')
    end
  end
end
```

### Cassette Storage

```
spec/vcr_cassettes/
└── Appydave_Tools_YouTubeManager_GetVideo/
    └── _get/retrieves_video_metadata.yml
```

### Custom Cassette Names

```ruby
it 'retrieves video metadata', vcr: { cassette_name: 'youtube/get_video_success' } do
  # ...
end
```

### Filtering Sensitive Data

Add to VCR configuration:

```ruby
VCR.configure do |config|
  config.filter_sensitive_data('<YOUTUBE_API_KEY>') { ENV['YOUTUBE_API_KEY'] }
  config.filter_sensitive_data('<OPENAI_TOKEN>') { ENV['OPENAI_ACCESS_TOKEN'] }
end
```

---

## Configuration in Tests

### Isolated Test Configuration

Tests use a temporary directory for configuration:

```ruby
# Set up in spec_helper.rb
Appydave::Tools::Configuration::Config.set_default do |config|
  config.config_path = Dir.mktmpdir
  # ...
end
```

This ensures:
- Tests don't modify real user configuration
- Tests are isolated from each other
- No leftover state between test runs

### Creating Test Configurations

```ruby
RSpec.describe Appydave::Tools::Dam::BrandResolver do
  let(:config_path) { Dir.mktmpdir }

  before do
    Appydave::Tools::Configuration::Config.set_default do |config|
      config.config_path = config_path
      config.register(:settings, Appydave::Tools::Configuration::Models::SettingsConfig)
    end

    # Create test settings
    File.write(
      File.join(config_path, 'settings.json'),
      { 'video-projects-root' => '/tmp/test-projects' }.to_json
    )
  end

  after do
    FileUtils.rm_rf(config_path)
  end

  # Tests...
end
```

---

## Guard for Continuous Testing

### Running Guard

```bash
# Start Guard for auto-testing
guard

# With Ruby 3.4 warning suppression
RUBYOPT="-W0" guard
```

### What Guard Does

1. **Watches file changes** in `lib/` and `spec/`
2. **Runs relevant tests** when files change
3. **Runs RuboCop** on changed files
4. **Provides fast feedback** during development

### Guardfile Configuration

The project's Guardfile configures:
- RSpec test runs on lib/spec file changes
- RuboCop linting on Ruby file changes
- Notification settings

### Focus Tags

Use `:focus` to run specific tests during development:

```ruby
it 'does something', :focus do
  # Only this test runs when you save
end
```

Guard respects the `filter_run_when_matching :focus` setting.

---

## Common Patterns

### Testing File Operations

Use `Tempfile` and `Dir.mktmpdir` for isolated file operations:

```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  let(:temp_dir) { Dir.mktmpdir }
  let(:input_file) { File.join(temp_dir, 'input.srt') }
  let(:output_file) { File.join(temp_dir, 'output.srt') }

  before do
    File.write(input_file, sample_content)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it 'writes to output file' do
    processor = described_class.new(file_path: input_file)
    processor.clean
    processor.write(output_file)

    expect(File.exist?(output_file)).to be true
  end
end
```

### Testing Error Handling

```ruby
RSpec.describe Appydave::Tools::Dam::BrandResolver do
  describe '.resolve' do
    context 'when brand does not exist' do
      it 'raises BrandNotFoundError' do
        expect {
          described_class.resolve('nonexistent')
        }.to raise_error(Appydave::Tools::Dam::Errors::BrandNotFoundError)
      end
    end
  end
end
```

### Testing with Options/Parameters

```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Join do
  subject do
    described_class.new(
      folder: fixture_dir,
      files: '*.srt',
      sort: 'asc',
      buffer: 100,
      output: output_file
    )
  end

  let(:fixture_dir) { File.expand_path('../../fixtures/subtitle_processor', __dir__) }
  let(:output_file) { File.join(Dir.mktmpdir, 'merged.srt') }

  describe '#join' do
    it 'merges files in specified order' do
      subject.join
      expect(File.exist?(output_file)).to be true
    end
  end
end
```

### Shared Examples

For common behavior across classes:

```ruby
# spec/support/shared_examples/configurable.rb
RSpec.shared_examples 'a configurable class' do
  it 'responds to configuration' do
    expect(described_class).to respond_to(:configuration)
  end
end

# In specs
RSpec.describe Appydave::Tools::Dam::S3Operations do
  it_behaves_like 'a configurable class'
end
```

---

## Anti-Patterns to Avoid

### Don't Test Private Methods Directly

```ruby
# Bad
it 'parses timestamp correctly' do
  result = subject.send(:parse_timestamp, '00:01:30,500')
  expect(result).to eq(90500)
end

# Good - test through public interface
it 'handles timestamps in content' do
  result = subject.process
  expect(result).to include_correct_timestamps
end
```

### Don't Use sleep() in Tests

```ruby
# Bad
it 'processes asynchronously' do
  subject.start_processing
  sleep(2)  # Flaky!
  expect(subject.done?).to be true
end

# Good - use proper synchronization or mock time
it 'processes asynchronously' do
  expect(subject).to receive(:notify_complete)
  subject.start_processing
end
```

### Don't Rely on Test Order

```ruby
# Bad - depends on previous test creating file
it 'reads the created file' do
  content = File.read('/tmp/test_output.txt')
  expect(content).to include('data')
end

# Good - each test creates its own fixtures
let(:test_file) do
  path = '/tmp/test_output.txt'
  File.write(path, 'test data')
  path
end

after { FileUtils.rm_f(test_file) }

it 'reads the created file' do
  content = File.read(test_file)
  expect(content).to include('data')
end
```

### Don't Test External Services Without Mocking

```ruby
# Bad - hits real YouTube API
it 'fetches video data' do
  video = YouTubeManager::GetVideo.new
  video.get('dQw4w9WgXcQ')
  expect(video.data).not_to be_nil
end

# Good - uses VCR cassette
it 'fetches video data', :vcr do
  video = YouTubeManager::GetVideo.new
  video.get('dQw4w9WgXcQ')
  expect(video.data).not_to be_nil
end
```

---

## Running Tests

### Common Commands

```bash
# Run all tests
rake spec

# Run specific test file
bundle exec rspec spec/appydave/tools/subtitle_processor/clean_spec.rb

# Run with documentation format
bundle exec rspec -f doc

# Run only failed tests from last run
bundle exec rspec --only-failures

# Run next failure (one at a time)
bundle exec rspec --next-failure

# Run with coverage report
COVERAGE=true rake spec

# Run focused tests only
bundle exec rspec --tag focus

# Enable external API tests (for development)
TOOLS_ENABLED=true bundle exec rspec
```

### CI/CD Testing

In CI, tests run with:
- `WebMock.disable_net_connect!` - No real HTTP calls
- VCR cassettes for recorded responses
- `TOOLS_ENABLED` not set - External API tests skipped

---

## Summary

| Principle | Implementation |
|-----------|----------------|
| Test business logic | Focus on `lib/` classes, not `bin/` |
| No requires | `spec_helper.rb` handles loading |
| Isolated tests | Temp directories, mocked config |
| Mock HTTP | VCR + WebMock |
| Fast feedback | Guard for continuous testing |
| Clean fixtures | `spec/fixtures/` organized by tool |

**When in doubt:**
1. Check existing specs for patterns
2. Test the class, not the CLI
3. Mock external dependencies
4. Keep tests fast and isolated

---

**Last updated:** 2025-12-13
