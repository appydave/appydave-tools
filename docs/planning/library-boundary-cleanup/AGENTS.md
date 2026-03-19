# AGENTS.md — AppyDave Tools / library-boundary-cleanup campaign

> Operational knowledge for every background agent. Self-contained — you receive only this file + your work unit prompt.
> Inherited from: extract-vat-cli campaign (2026-03-19)
> Updated for: library-boundary-cleanup campaign (2026-03-19)

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Active campaign:** library-boundary-cleanup — fixing two boundary violations left by extract-vat-cli:
  1. `exit 1` calls inside library code (S3ScanCommand + S3ArgParser)
  2. `ENV['BRAND_PATH']` side-effect inside library argument parser (S3ArgParser)
**Commits:** Trigger automated semantic versioning via GitHub Actions. Always use `kfeat`/`kfix` — never `git commit`.

---

## ⚠️ Pre-Commit Check (Mandatory Every Commit)

Before running `kfix`, always run:
```bash
git status
```
Confirm ONLY the files you intentionally changed are staged. If unexpected files appear, run `git diff` to investigate before proceeding. Never commit files you didn't intentionally change.

**Why:** Prior campaign accidentally staged a pre-existing uncommitted change when running `kfix`. Required a follow-up fix commit.

---

## Build & Run Commands

```bash
# Initialize rbenv (required if rbenv not in PATH)
eval "$(rbenv init -)"

# Run tests
bundle exec rspec                           # All tests
bundle exec rspec spec/path/to/file_spec.rb # Single file
RUBYOPT="-W0" bundle exec rspec             # Suppress Ruby 3.4 platform warnings

# Lint
bundle exec rubocop --format clang          # Standard lint check (matches CI)

# Commit (never use git commit directly)
kfeat "add feature description"             # Minor version bump
kfix "fix bug description"                  # Patch version bump
```

**Baseline (start of library-boundary-cleanup):** 847 examples, 0 failures, ~85.92% line coverage

---

## Directory Structure

```
bin/
  dam                           Main DAM CLI entry point (VatCLI class — 1,600 lines, being reduced)
exe/                            Thin wrappers for gem installation (no .rb extension)
lib/appydave/tools/
  dam/                          Digital Asset Management — main active area
    brand_resolver.rb           Centralizes ALL brand name transformations (appydave ↔ v-appydave)
    errors.rb                   Custom exception hierarchy — ADD UsageError here in B034
    fuzzy_matcher.rb            Levenshtein distance for "did you mean?" suggestions
    git_helper.rb               Extracted git command wrappers
    file_helper.rb              File utility methods (format_size, calculate_directory_size, format_age)
    config.rb                   Delegates brand resolution to BrandResolver; memoized Config loading
    project_resolver.rb         Project name resolution with regex pattern matching
    project_listing.rb          Table display for `dam list` command
    s3_operations.rb            S3 upload/download/status with MD5 comparison
    s3_scanner.rb               S3 bucket scanner for s3-scan command
    status.rb                   Project git/S3 status display
    manifest_generator.rb       Video project manifest
    sync_from_ssd.rb            SSD sync operations
    ssd_status.rb               SSD backup status
    share_operations.rb         Pre-signed URL generation
    config_loader.rb            Loads .video-tools.env per brand
    local_sync_status.rb        Enriches project data with local s3-staging sync status
    s3_scan_command.rb          S3 scan orchestration + display — HAS exit 1 AT LINE 55 (B034 target)
    s3_arg_parser.rb            CLI argument parsing for S3 commands — HAS exit 1 + ENV side-effects (B034/B035 targets)
lib/appydave/tools.rb           Require file — already includes s3_scan_command and s3_arg_parser
spec/
  appydave/tools/dam/           One spec file per dam/ class
  support/
    dam_filesystem_helpers.rb   Shared contexts for DAM filesystem testing
```

---

## This Campaign: What We're Fixing

### The Two Problems

**Problem 1: `exit 1` in library code** — Library classes must not terminate the process. VatCLI's `rescue StandardError` already catches and prints errors. Fix: replace `exit 1` with typed exceptions.

**Problem 2: `ENV['BRAND_PATH']` side-effect in library** — `S3ArgParser` sets a process-wide env var during argument parsing. Unsafe for parallelism. Fix: return `brand_path:` in result hash; move the `ENV[]=` call to VatCLI.

### Work Unit Dependencies

```
B034: extract-exit-calls       (no deps — do first)
B035: extract-env-side-effect  (DEPENDS ON B034 — both touch s3_arg_parser.rb)
B036: tests-s3-scan-command    (DEPENDS ON B034 — can't test exceptions until they exist)
B037: tests-local-sync-status  (no deps — but run after B035 for clean baseline)

Wave 1: B034
Wave 2: B035
Wave 3: B036 + B037 (parallel — different spec files)
```

---

## B034: extract-exit-calls

**Files touched:** `lib/appydave/tools/dam/errors.rb`, `lib/appydave/tools/dam/s3_scan_command.rb`, `lib/appydave/tools/dam/s3_arg_parser.rb`

### Step 1 — Add UsageError to errors.rb

After the existing `GitOperationError` line, add:

```ruby
# Raised when CLI arguments are invalid or missing
class UsageError < DamError; end
```

### Step 2 — Fix S3ScanCommand (line 55)

Replace:
```ruby
unless File.exist?(manifest_path)
  puts "❌ Manifest not found: #{manifest_path}"
  puts "   Run: dam manifest #{brand_key}"
  puts "   Then retry: dam s3-scan #{brand_key}"
  exit 1
end
```

With:
```ruby
unless File.exist?(manifest_path)
  raise Appydave::Tools::Dam::ConfigurationError,
        "Manifest not found: #{manifest_path}. Run: dam manifest #{brand_key}"
end
```

Remove the `puts` lines above — the exception message carries the information. VatCLI's rescue prints it.

### Step 3 — Fix S3ArgParser (4 exit locations)

**parse_s3 — PWD auto-detect fail (around line 25):**

Replace:
```ruby
if brand.nil? || project_id.nil?
  puts '❌ Could not auto-detect brand/project from current directory'
  puts "Usage: dam #{command} <brand> <project> [--dry-run]"
  exit 1
end
```

With:
```ruby
raise Appydave::Tools::Dam::UsageError,
      "Could not auto-detect brand/project from current directory. Usage: dam #{command} <brand> <project> [--dry-run]" if brand.nil? || project_id.nil?
```

**parse_s3 — invalid brand (around line 43):**

Replace:
```ruby
unless valid_brand?(brand_arg)
  puts "❌ Invalid brand: '#{brand_arg}'"
  puts ''
  puts 'Valid brands:'
  # ... puts lines ...
  puts "Usage: dam #{command} <brand> <project> [--dry-run]"
  exit 1
end
```

With:
```ruby
unless valid_brand?(brand_arg)
  raise Appydave::Tools::Dam::UsageError,
        "Invalid brand: '#{brand_arg}'. Valid brands: appydave, voz, aitldr, kiros, joy, ss. Usage: dam #{command} <brand> <project> [--dry-run]"
end
```

**parse_discover — missing args (around line 100):**

Replace:
```ruby
if brand_arg.nil? || project_arg.nil?
  puts 'Usage: dam s3-discover <brand> <project> [--shareable]'
  # ... puts lines ...
  exit 1
end
```

With:
```ruby
raise Appydave::Tools::Dam::UsageError,
      'Usage: dam s3-discover <brand> <project> [--shareable]' if brand_arg.nil? || project_arg.nil?
```

**show_share_usage_and_exit — rename and replace:**

Rename the method to `raise_share_usage_error`. Replace:
```ruby
def show_share_usage_and_exit
  puts 'Usage: dam s3-share ...'
  # ... puts lines ...
  exit 1
end
```

With:
```ruby
def raise_share_usage_error
  raise Appydave::Tools::Dam::UsageError,
        'Usage: dam s3-share <brand> <project> <file> [--expires 7d] [--download]'
end
```

Update the caller in `parse_share`:
```ruby
# Before:
show_share_usage_and_exit if brand_arg.nil? || project_arg.nil? || file_arg.nil?
# After:
raise_share_usage_error if brand_arg.nil? || project_arg.nil? || file_arg.nil?
```

### Done when B034 is complete
- `errors.rb` contains `UsageError < DamError`
- 0 occurrences of `exit 1` in `s3_scan_command.rb` or `s3_arg_parser.rb`
- `show_share_usage_and_exit` renamed to `raise_share_usage_error`
- `bundle exec rubocop --format clang` → 0 offenses
- `RUBYOPT="-W0" bundle exec rspec` → 847 examples, 0 failures (no new specs in this WU)
- `git status` clean before `kfix`

---

## B035: extract-env-side-effect

**Files touched:** `lib/appydave/tools/dam/s3_arg_parser.rb`, `bin/dam`

**Prerequisite:** B034 complete.

### Step 1 — Remove ENV side-effects from S3ArgParser

In `parse_s3` (around line 51): remove `ENV['BRAND_PATH'] = ...`. Add `brand_path:` to returned hash:

```ruby
# Before:
ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)
{ brand: brand_key, project: project_id, dry_run: dry_run, force: force }

# After (auto-detect path):
brand_path = Appydave::Tools::Dam::Config.brand_path(brand_key)
{ brand: brand_key, project: project_id, dry_run: dry_run, force: force, brand_path: brand_path }
```

Note: In the `brand_arg.nil?` branch, `brand` is set from `ProjectResolver.detect_from_pwd` — use `brand` not `brand_arg` for path resolution there.

In `parse_share` (around line 82): remove `ENV['BRAND_PATH'] = ...`. Add `brand_path:` to returned hash:

```ruby
# Before:
ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)
{ brand: brand_key, project: project_id, file: file_arg, expires: expires, download: download }

# After:
brand_path = Appydave::Tools::Dam::Config.brand_path(brand)
{ brand: brand_key, project: project_id, file: file_arg, expires: expires, download: download, brand_path: brand_path }
```

In `parse_discover` (around line 108): same pattern:

```ruby
# Before:
ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand)
{ brand_key: brand_key, project_id: project_id, shareable: shareable }

# After:
brand_path = Appydave::Tools::Dam::Config.brand_path(brand)
{ brand_key: brand_key, project_id: project_id, shareable: shareable, brand_path: brand_path }
```

### Step 2 — Update VatCLI callers in bin/dam

Search for every call to `S3ArgParser.parse_s3`, `S3ArgParser.parse_share`, `S3ArgParser.parse_discover` in `bin/dam`. After each call, add:

```ruby
options = Appydave::Tools::Dam::S3ArgParser.parse_s3(args, 's3-up')
ENV['BRAND_PATH'] = options[:brand_path]
```

Same pattern for `parse_share` and `parse_discover` callers.

**Affected VatCLI methods** (grep `S3ArgParser` in bin/dam to confirm):
- `s3_up_command` → uses `parse_s3`
- `s3_down_command` → uses `parse_s3`
- `s3_status_command` → uses `parse_s3`
- `s3_cleanup_remote_command` → uses `parse_s3`
- `s3_cleanup_local_command` → uses `parse_s3`
- `archive_command` → uses `parse_s3`
- `s3_share_command` → uses `parse_share`
- `s3_discover_command` → uses `parse_discover`

### Done when B035 is complete
- 0 occurrences of `ENV['BRAND_PATH'] =` in `s3_arg_parser.rb`
- All 3 parse methods return `brand_path:` in their result hash
- All VatCLI callers set `ENV['BRAND_PATH'] = options[:brand_path]` after parsing
- `bundle exec rubocop --format clang` → 0 offenses
- `RUBYOPT="-W0" bundle exec rspec` → 847 examples, 0 failures
- `git status` clean before `kfix`

---

## B036: tests-s3-scan-command

**File touched:** `spec/appydave/tools/dam/s3_scan_command_spec.rb`

**Prerequisite:** B034 complete (exceptions must exist before testing them).

Current state: 2 smoke tests (`respond_to` checks). Replace with real behaviour tests.

### Target: 8–10 examples covering

```ruby
RSpec.describe Appydave::Tools::Dam::S3ScanCommand do
  include_context 'with vat filesystem and brands', brands: %w[appydave]

  let(:scanner) { described_class.new }
  let(:brand_key) { 'appydave' }

  before do
    allow(Appydave::Tools::Dam::S3Scanner).to receive(:new).and_return(mock_s3_scanner)
    allow(Appydave::Tools::Configuration::Config).to receive(:configure)
    allow(Appydave::Tools::Configuration::Config).to receive(:brands).and_return(mock_brands_config)
  end

  describe '#scan_single' do
    context 'when manifest exists and S3 returns results' do
      # Write a fixture projects.json to brand_path
      # Mock scanner.scan_all_projects to return { 'b65-test' => { file_count: 3, total_bytes: 1000, last_modified: '...' } }
      # Expect: manifest updated, updated_count == 1, no error
    end

    context 'when manifest not found' do
      # Do NOT write projects.json
      # Mock scanner to return results
      # expect { scanner.scan_single(brand_key) }.to raise_error(Appydave::Tools::Dam::ConfigurationError, /Manifest not found/)
    end

    context 'when S3 returns empty results' do
      # Mock scanner.scan_all_projects to return {}
      # Expect: early return (no raise, no manifest write)
    end

    context 'when S3 has orphaned projects' do
      # projects.json has ['b65-test'], S3 returns { 'b65-test' => ..., 'b99-orphan' => ... }
      # Expect: orphaned_projects contains 'b99-orphan', matched_projects contains 'b65-test'
    end
  end

  describe '#scan_all' do
    context 'when one brand fails' do
      # brands_config.brands returns [appydave, voz]
      # scan_single raises for voz
      # Expect: results array has appydave success: true, voz success: false
      # Expect: no re-raise (scan_all rescues per-brand)
    end
  end
end
```

**Fixture pattern for projects.json:**
```ruby
manifest = {
  config: { last_updated: Time.now.utc.iso8601, note: 'test' },
  projects: [{ id: 'b65-test-project', storage: { s3: {} } }]
}
File.write(File.join(brand_path, 'projects.json'), JSON.generate(manifest))
```

### Done when B036 is complete
- `spec/appydave/tools/dam/s3_scan_command_spec.rb` has 8+ real behaviour examples
- `respond_to` smoke tests removed or replaced
- `RUBYOPT="-W0" bundle exec rspec` → 855+ examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- `git status` clean before `kfix`

---

## B037: tests-local-sync-status

**File touched:** `spec/appydave/tools/dam/local_sync_status_spec.rb`

**No prerequisites** — but run after B035 for clean baseline.

### Gaps to fill

**1. `:partial` case in `#enrich!`**

Set up `s3-staging` folder with 2 files but `file_count: 3` in S3 data:
```ruby
context 'when local s3-staging has fewer files than S3' do
  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test', 's3-staging'))
    FileUtils.touch(File.join(appydave_path, 'b65-test', 's3-staging', 'file1.mp4'))
    FileUtils.touch(File.join(appydave_path, 'b65-test', 's3-staging', 'file2.mp4'))
  end

  it 'sets status to :partial' do
    matched = { 'b65-test' => { file_count: 3 } }
    described_class.enrich!(matched, 'appydave')
    expect(matched['b65-test'][:local_status]).to eq(:partial)
  end

  it 'sets local_file_count to 2' do
    matched = { 'b65-test' => { file_count: 3 } }
    described_class.enrich!(matched, 'appydave')
    expect(matched['b65-test'][:local_file_count]).to eq(2)
  end
end
```

**2. `local_file_count` assertion in existing `:synced` test**

Find the existing synced context and add:
```ruby
it 'sets local_file_count correctly' do
  expect(data[:local_file_count]).to eq(3) # adjust to match your fixture
end
```

**3. Zone.Identifier exclusion**

Windows NTFS streams appear as `filename:Zone.Identifier` in samba mounts. These must NOT count as local files:
```ruby
context 'when s3-staging contains Zone.Identifier files' do
  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test', 's3-staging'))
    FileUtils.touch(File.join(appydave_path, 'b65-test', 's3-staging', 'file1.mp4'))
    FileUtils.touch(File.join(appydave_path, 'b65-test', 's3-staging', 'file1.mp4:Zone.Identifier'))
    FileUtils.touch(File.join(appydave_path, 'b65-test', 's3-staging', 'file2.mp4'))
  end

  it 'excludes Zone.Identifier files from local_file_count' do
    matched = { 'b65-test' => { file_count: 2 } }
    described_class.enrich!(matched, 'appydave')
    expect(matched['b65-test'][:local_file_count]).to eq(2)
    expect(matched['b65-test'][:local_status]).to eq(:synced)
  end
end
```

**4. Unknown status guard in `#format`**

```ruby
describe '.format' do
  it 'returns Unknown for unrecognised status' do
    expect(described_class.format(:unknown, nil, 0)).to eq('Unknown')
  end
end
```

Check the actual `format` implementation first — if it already has an `else` branch returning `'Unknown'`, this is a documentation test. If it has no `else`, add one to `local_sync_status.rb` before writing this spec.

### Done when B037 is complete
- `:partial` case tested with `local_file_count` assertion
- `:synced` case has `local_file_count` assertion
- `Zone.Identifier` exclusion tested
- `format(:unknown, ...)` tested
- `RUBYOPT="-W0" bundle exec rspec` → 851+ examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- `git status` clean before `kfix`

---

## Success Criteria (Every Work Unit)

Every work unit must satisfy ALL of the following before marking `[x]`:

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 847+ examples, 0 failures (rising with each WU)
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 85.92%
- [ ] Any new `.rb` files start with `# frozen_string_literal: true`
- [ ] `git status` confirmed clean before `kfix`

---

## Reference Patterns

### Shared Context for DAM Specs — THE STANDARD PATTERN

```ruby
# spec/appydave/tools/dam/some_class_spec.rb
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::SomeClass do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  before do
    FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project'))
  end

  describe '.some_method' do
    it 'does the thing' do
      expect(described_class.some_method('appydave')).to eq('expected')
    end
  end
end
```

**Available from shared context:**
- `temp_folder` — temp root (auto-cleaned after each example)
- `projects_root` — `/path/to/temp/video-projects`
- `appydave_path`, `voz_path`, etc. — brand dirs (created on demand)
- `SettingsConfig#video_projects_root` is mocked to return `projects_root`

### FileHelper — Use These, Don't Duplicate

```ruby
Appydave::Tools::Dam::FileHelper.format_size(bytes)             # "1.5 GB"
Appydave::Tools::Dam::FileHelper.calculate_directory_size(path) # Integer bytes
Appydave::Tools::Dam::FileHelper.format_age(time)               # "3d", "2w", etc.
```

### BrandResolver — All Brand Name Transformations

```ruby
BrandResolver.expand('appydave')      # => 'v-appydave'
BrandResolver.expand('ad')            # => 'v-appydave' (shortcut)
BrandResolver.normalize('v-appydave') # => 'appydave'
BrandResolver.validate('appydave')    # => 'appydave' or raises BrandNotFoundError
```

### Typed Exception Pattern

```ruby
raise Appydave::Tools::Dam::ConfigurationError, 'Manifest not found: /path'
raise Appydave::Tools::Dam::UsageError, 'Usage: dam s3-up <brand> <project>'
raise ProjectNotFoundError, 'Project name is required' if project_hint.nil?
raise BrandNotFoundError.new(brand, available_brands, fuzzy_suggestions)
```

### Config.brand_path — Correct Call

```ruby
# brand_key is the short form ('appydave'), brand is expanded ('v-appydave')
brand_path = Appydave::Tools::Dam::Config.brand_path(brand_key)
# OR:
brand_path = Appydave::Tools::Dam::Config.brand_path(brand)
# Both work — Config.brand_path resolves via BrandResolver internally
```

---

## Anti-Patterns to Avoid

- ❌ `exit 1` in library code — use typed exceptions from `errors.rb` instead
- ❌ `ENV['BRAND_PATH'] = ...` in library code — return `brand_path:` in result hash; set ENV in VatCLI
- ❌ Inline brand transformations — never write `"v-#{brand}"` outside BrandResolver
- ❌ `format_bytes` — does not exist; use `FileHelper.format_size`
- ❌ Mocking Config class methods in DAM specs — use shared filesystem context instead
- ❌ Multiple `before` blocks in same RSpec context — merge them (triggers RSpec/ScatteredSetup)
- ❌ `$?` for subprocess status — use `$CHILD_STATUS` (rubocop Style/SpecialGlobalVars)
- ❌ `raise 'string error'` in DAM module — use typed exceptions from `errors.rb`
- ❌ `include FileUtils` — use dam's `FileHelper` instead
- ❌ Hardcoded header strings for table output — always use `format()` matching data row format
- ❌ Adding new `Config.configure` calls — memoized but called redundantly; don't spread further

---

## Mock Patterns

### ENV Stubbing (if needed in specs)

```ruby
allow(ENV).to receive(:[]).and_call_original
allow(ENV).to receive(:[]).with('BRAND_PATH').and_return('/tmp/test/v-appydave')
```

**Do NOT use climate_control gem** — project doesn't have it.

### S3Scanner Mocking (for B036)

```ruby
let(:mock_s3_scanner) { instance_double(Appydave::Tools::Dam::S3Scanner) }

before do
  allow(Appydave::Tools::Dam::S3Scanner).to receive(:new).with(brand_key).and_return(mock_s3_scanner)
  allow(mock_s3_scanner).to receive(:scan_all_projects).and_return({
    'b65-test-project' => { file_count: 3, total_bytes: 1_500_000, last_modified: '2025-01-01T00:00:00Z' }
  })
end
```

### Config::Brands Mocking (for B036 scan_all)

```ruby
let(:mock_brands_config) { instance_double(Appydave::Tools::Configuration::BrandsConfig) }
let(:mock_brand_info) { instance_double(Appydave::Tools::Configuration::BrandInfo, key: 'appydave') }

before do
  allow(mock_brands_config).to receive(:brands).and_return([mock_brand_info])
end
```

---

## Quality Gates

- **Tests:** `RUBYOPT="-W0" bundle exec rspec` — 847+ examples, 0 failures
- **Lint:** `bundle exec rubocop --format clang` — 0 offenses (CI will reject)
- **Coverage:** ≥ 85.92% line coverage
- **frozen_string_literal:** Required on every new `.rb` file
- **Commit format:** `kfeat`/`kfix` only — triggers semantic versioning + CI wait
- **Pre-commit:** Always run `git status` before `kfix` — confirm staged files

---

## Learnings

### From DAM Enhancement Sprint (Jan 2025)

- **BrandResolver is the critical path.** All `dam` commands flow through it. Any change to brand resolution must be tested with all shortcuts.
- **`Regexp.last_match` is reset by `.sub()` calls.** Always capture regex groups BEFORE any string transformation.
- **`Config.configure` is memoized but called redundantly.** Don't add new calls.
- **Table format() pattern is non-obvious.** Headers misaligned 3 times in UAT. Always verify with real data.

### From micro-cleanup (2026-03-19)

- **Dirty working tree + kfix = accidental staging.** Always run `git status` before committing.
- **Pre-existing "already fixed" items:** Check B-items aren't already done before acting (B031, B033, B015, B019 were all already committed).

### From Architectural Review (2026-03-19)

- **bin/dam is the primary DAM CLI entry point.** Regressions here affect real workflows. Test every command path after extraction.
- **`ENV['BRAND_PATH']` is set in 5 places in bin/dam.** Three are in parse methods (being extracted to B035). Two remain in `generate_single_manifest` and `sync_ssd_command` — out of scope for this campaign.
- **Do NOT attempt B020 (split S3Operations) in this campaign.** Different class, different risk profile.

### From extract-vat-cli (2026-03-19)

- **valid_brand? needs Config.brands mock.** The shared filesystem context only mocks `SettingsConfig`. When testing code that calls `Config.brands`, mock it separately: `allow(Appydave::Tools::Configuration::Config).to receive(:brands).and_return(...)`.
- **rubocop-disable directives become redundant when methods move.** After extracting to a library class, check the VatCLI file for orphaned disable/enable pairs and remove them.
- **VatCLI rescue blocks already catch StandardError.** No changes to VatCLI rescue needed when replacing `exit 1` with exceptions — the existing rescue chain handles it.
- **S3ScanCommand#scan_all already rescues per-brand.** The `rescue StandardError` inside `scan_all` means per-brand failures are isolated. Once `scan_single` raises instead of calling `exit`, `scan_all` catches it correctly — no structural change needed.
