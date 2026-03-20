# AGENTS.md — AppyDave Tools / batch-a-features campaign

> Self-contained operational knowledge. You receive only this file + your work unit prompt.
> Inherited from: env-dead-code-cleanup (2026-03-20)

---

## Project Overview

**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Baseline:** 860 examples, 0 failures, 86.44% line coverage, v0.76.13
**Commits:** `kfeat "message"` for new features (minor bump), `kfix "message"` for fixes (patch bump). Never `git commit` directly.

---

## ⚠️ kfix/kfeat Staging Behaviour

`kfix` and `kfeat` run `git add .` internally — they stage EVERYTHING in the working tree.

**Before calling kfix/kfeat:**
```bash
git status    # confirm ONLY your intended files are modified
git diff      # review the actual changes
```

If unintended files appear:
```bash
git stash -- path/to/unintended/file    # stash specific file
git checkout -- path/to/file            # discard unintended change
```

Then call kfix/kfeat once the tree is clean.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                    # Full suite (860 examples baseline)
bundle exec rspec spec/path/to/file_spec.rb        # Single file
bundle exec rubocop --format clang                 # Lint (must be 0 offenses)

kfeat "add feature description"    # new feature — minor version bump
kfix "fix description"             # fix/improvement — patch version bump
```

---

## Directory Structure

```
bin/
  gpt_context.rb              GPT context CLI — target of B001
  dam                         DAM CLI (VatCLI) — target of B009
lib/appydave/tools/
  gpt_context/
    options.rb                Options struct — add show_tokens field (B001)
    file_collector.rb         Builds content string from glob patterns
    output_handler.rb         Writes content to clipboard/file
  dam/
    project_listing.rb        Table display for dam list — target of B010
    brand_resolver.rb         Brand name transforms (appydave ↔ v-appydave)
    config.rb                 Brand path resolution
    project_resolver.rb       Project name resolution
spec/
  appydave/tools/dam/
    brand_resolution_integration_spec.rb   NEW — target of B012
  support/
    dam_filesystem_helpers.rb              Shared context for DAM specs
```

---

## B001 — gpt-context-token-counting

**Files:** `lib/appydave/tools/gpt_context/options.rb`, `bin/gpt_context.rb`

### What to build

Add a `--tokens` / `-t` flag. When set, after collecting content, print an estimated token count to `$stderr` (so it doesn't pollute the content going to clipboard/file).

**Token estimation:** `(content.length / 4.0).ceil` — industry-standard approximation for English/code (4 chars ≈ 1 token).

### Step 1 — options.rb

Add `show_tokens` to the Struct:
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
  :show_tokens,         # ADD THIS
  keyword_init: true
) do
  def initialize(**args)
    super
    # existing defaults...
    self.show_tokens ||= false    # ADD THIS
  end
end
```

### Step 2 — bin/gpt_context.rb

Add the CLI flag (after the `-p` option block, before the separator):
```ruby
opts.on('-t', '--tokens', 'Show estimated token count after collecting context') do
  options.show_tokens = true
end
```

After `content = gatherer.build` and before `output_handler = ...`, add:
```ruby
if options.show_tokens
  token_estimate = (content.length / 4.0).ceil
  char_count = content.length
  $stderr.puts ''
  $stderr.puts '── Token Estimate ──────────────────────────'
  $stderr.puts "  Characters : #{char_count.to_s.rjust(10)}"
  $stderr.puts "  Tokens (~4c): #{token_estimate.to_s.rjust(10)}"
  $stderr.puts ''
  if token_estimate > 200_000
    $stderr.puts '  ⚠️  WARNING: Exceeds 200k tokens — may not fit most LLM context windows'
  elsif token_estimate > 100_000
    $stderr.puts '  ⚠️  NOTICE: Exceeds 100k tokens — check your LLM context limit'
  end
  $stderr.puts '────────────────────────────────────────────'
  $stderr.puts ''
end
```

### Done when B001 is complete
- `bundle exec rspec spec/appydave/tools/gpt_context/` → all pass
- Check if options_spec.rb needs a new example for `show_tokens` default — add one if it tests other defaults
- `bundle exec rubocop --format clang` → 0 offenses
- `RUBYOPT="-W0" bundle exec rspec` → 860+ examples, 0 failures
- Commit: `kfeat "add --tokens flag to gpt_context for estimated token count output"`

---

## B009 — dam-progress-indicators

**File:** `bin/dam` only.

### What to build

Add human-readable progress messages before and after long-running S3 operations. These operations can take 30s–5min with no feedback currently.

### Commands to update

**s3_up_command** — wrap the upload:
```ruby
def s3_up_command(args)
  options = Appydave::Tools::Dam::S3ArgParser.parse_s3(args, 's3-up')
  s3_ops = Appydave::Tools::Dam::S3Operations.new(options[:brand], options[:project])
  verb = options[:dry_run] ? '🔍 Dry run:' : '⬆️  Uploading'
  puts "#{verb} #{options[:project]} (#{options[:brand]}) → S3..."
  s3_ops.upload(dry_run: options[:dry_run])
rescue StandardError => e
  # existing rescue
end
```

**s3_down_command:**
```ruby
puts "⬇️  Downloading #{options[:project]} (#{options[:brand]}) from S3..."
```

**s3_status_command:**
```ruby
puts "🔍 Checking S3 status for #{options[:project]} (#{options[:brand]})..."
```

**archive_command:**
```ruby
puts "📦 Archiving #{options[:project]} (#{options[:brand]}) to SSD..."
```

**sync_ssd_command** (brand-level, not project):
```ruby
puts "🔄 Syncing #{brand_arg} from SSD..."
```

Read `bin/dam` carefully to find the exact method structure and rescue blocks before making changes. Add the `puts` line immediately after the `options =` assignment and before the `s3_ops =` instantiation.

### Done when B009 is complete
- `RUBYOPT="-W0" bundle exec rspec` → 860 examples, 0 failures (no new specs — bin/dam is untested by spec)
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "add progress indicators to dam S3 commands"`

---

## B010 — dam-column-widths

**File:** `lib/appydave/tools/dam/project_listing.rb` only.

### What to build

Replace hardcoded separator line lengths with terminal-width detection. Also add path truncation for the PATH column.

### Step 1 — add terminal_width helper

Add a private class method:
```ruby
def self.terminal_width
  IO.console&.winsize&.last || 120
rescue StandardError
  120
end
```

You'll need `require 'io/console'` — add it at the top of the file (after `# frozen_string_literal: true`):
```ruby
require 'io/console'
```

### Step 2 — replace hardcoded separator lengths

Currently the file has multiple `puts '-' * N` lines with hardcoded widths (133, 122, 189, 200, etc.).

Replace each with `puts '-' * [terminal_width, N].min` where N is the original value. This prevents the separator from overflowing narrow terminals while still using the full width on wide ones.

grep for `'-'` in project_listing.rb to find all occurrences.

### Step 3 — add path truncation helper

```ruby
def self.truncate_path(path, max_width = 35)
  return path if path.nil? || path.length <= max_width
  "...#{path[-(max_width - 3)..]}"
end
```

Replace `shorten_path(data[:path])` calls with `truncate_path(shorten_path(data[:path]), 35)` where the format string uses `%-35s`.

### Done when B010 is complete
- `RUBYOPT="-W0" bundle exec rspec spec/appydave/tools/dam/project_listing_spec.rb` → all pass
- `RUBYOPT="-W0" bundle exec rspec` → 860+ examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "terminal-width-aware separator lines and path truncation in project_listing"`

---

## B012 — brand-resolution-integration-tests

**File:** `spec/appydave/tools/dam/brand_resolution_integration_spec.rb` (new file)

### What to build

Integration tests that exercise the BrandResolver → Config → ProjectResolver chain end-to-end using the shared filesystem context.

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Brand resolution integration' do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project'))
    FileUtils.mkdir_p(File.join(appydave_path, 'b66-another-project'))
    FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
  end

  describe 'BrandResolver → Config.brand_path' do
    it 'resolves appydave shortcut to correct path' do
      path = Appydave::Tools::Dam::Config.brand_path('appydave')
      expect(path).to eq(appydave_path)
    end

    it 'resolves voz shortcut to correct path' do
      path = Appydave::Tools::Dam::Config.brand_path('voz')
      expect(path).to eq(voz_path)
    end

    it 'raises BrandNotFoundError for unknown brand' do
      expect { Appydave::Tools::Dam::Config.brand_path('nonexistent') }
        .to raise_error(Appydave::Tools::Dam::BrandNotFoundError)
    end
  end

  describe 'BrandResolver.expand' do
    it 'expands appydave to v-appydave' do
      expect(Appydave::Tools::Dam::BrandResolver.expand('appydave')).to eq('v-appydave')
    end

    it 'expands voz to v-voz' do
      expect(Appydave::Tools::Dam::BrandResolver.expand('voz')).to eq('v-voz')
    end
  end

  describe 'ProjectResolver.resolve' do
    it 'resolves short name b65 to full project name' do
      result = Appydave::Tools::Dam::ProjectResolver.resolve('appydave', 'b65')
      expect(result).to eq('b65-test-project')
    end

    it 'resolves exact project name' do
      result = Appydave::Tools::Dam::ProjectResolver.resolve('voz', 'boy-baker')
      expect(result).to eq('boy-baker')
    end

    it 'raises ProjectNotFoundError for missing project' do
      expect { Appydave::Tools::Dam::ProjectResolver.resolve('appydave', 'b99') }
        .to raise_error(Appydave::Tools::Dam::ProjectNotFoundError)
    end
  end

  describe 'ProjectResolver.detect_from_pwd' do
    it 'detects brand and project from a project directory' do
      Dir.chdir(File.join(appydave_path, 'b65-test-project')) do
        brand, project = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
        expect(brand).to eq('appydave')
        expect(project).to eq('b65-test-project')
      end
    end

    it 'returns nil when run outside any known brand directory' do
      Dir.chdir('/tmp') do
        brand, project = Appydave::Tools::Dam::ProjectResolver.detect_from_pwd
        expect(brand).to be_nil
        expect(project).to be_nil
      end
    end
  end
end
```

**Read `project_resolver.rb` and `brand_resolver.rb` before writing** to confirm method signatures.

**Note:** The shared context mocks `SettingsConfig#video_projects_root` to return `projects_root`, so `Config.brand_path` calls will resolve to the temp filesystem. `instance_double` is NOT needed here — use the real classes against the mocked filesystem.

### Done when B012 is complete
- `bundle exec rspec spec/appydave/tools/dam/brand_resolution_integration_spec.rb` → all pass
- `RUBYOPT="-W0" bundle exec rspec` → 866+ examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "add brand resolution integration spec covering BrandResolver, Config, ProjectResolver chain"`

---

## Success Criteria (Every Work Unit)

- [ ] `RUBYOPT="-W0" bundle exec rspec` → 860+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` → 0 offenses
- [ ] Coverage ≥ 86.44%
- [ ] Working tree clean before calling kfix/kfeat (git status check)

---

## Reference Patterns

### Shared Context for DAM Specs

```ruby
include_context 'with vat filesystem and brands', brands: %w[appydave voz]
# Provides: temp_folder, projects_root, appydave_path, voz_path
# SettingsConfig#video_projects_root mocked → projects_root
```

### instance_double — Always Full Constant

```ruby
instance_double(Appydave::Tools::Configuration::Models::BrandsConfig)  # ✅
instance_double('BrandsConfig')                                          # ❌ fails CI
```

### Typed Exceptions

```ruby
raise Appydave::Tools::Dam::BrandNotFoundError.new(brand, available, suggestions)
raise Appydave::Tools::Dam::ProjectNotFoundError, 'message'
raise Appydave::Tools::Dam::UsageError, 'message'
```

---

## Anti-Patterns to Avoid

- ❌ `exit 1` in library code — use typed exceptions
- ❌ `instance_double('StringForm')` — fails CI on Ubuntu
- ❌ Multiple `before` blocks in same context — merge them (RSpec/ScatteredSetup)
- ❌ `$?` for subprocess status — use `$CHILD_STATUS`
- ❌ `format_bytes` — use `FileHelper.format_size`
- ❌ Inline brand transforms — use BrandResolver

---

## Learnings

### From env-dead-code-cleanup (2026-03-20)

- **kfix runs `git add .` internally.** Clean the working tree before calling kfix. Check `git status` first.
- **`instance_double` string form fails CI on Ubuntu.** Always use full constant.
- **`not_to raise_error` is a weak assertion.** Prefer field-value or method-spy assertions.

### From library-boundary-cleanup (2026-03-20)

- **`exit 1` in library code → use typed exceptions.** VatCLI rescue blocks catch StandardError.
- **Config.brands needs separate mock** from shared filesystem context.
- **S3ScanCommand#scan_all rescues per-brand** — per-brand failures are isolated.
