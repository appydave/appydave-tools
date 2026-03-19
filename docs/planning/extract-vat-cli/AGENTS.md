# AGENTS.md — AppyDave Tools / extract-vat-cli campaign

> Operational knowledge for every background agent. Self-contained — you receive only this file + your work unit prompt.
> Last updated: 2026-03-19 (extract-vat-cli campaign)

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Active campaign:** extract-vat-cli — extracting business logic from `bin/dam` (1,600-line God class) into proper library classes.
**Commits:** Trigger automated semantic versioning via GitHub Actions. Always use `kfeat`/`kfix` — never `git commit`.

---

## ⚠️ Pre-Commit Check (Mandatory Every Commit)

Before running `kfix`, always run:
```bash
git status
```
Confirm ONLY the files you intentionally changed are staged. If unexpected files appear, run `git diff` to investigate before proceeding. Never commit files you didn't intentionally change.

**Why:** Prior campaign (micro-cleanup) accidentally staged a pre-existing uncommitted change in `lib/appydave/tools.rb` when running `kfix`. This required a follow-up fix commit.

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

**Baseline (2026-03-19):** 831 examples, 0 failures, ~85.92% line coverage

---

## Directory Structure

```
bin/                          CLI scripts (development, .rb extension)
exe/                          Thin wrappers for gem installation (no .rb extension)
lib/appydave/tools/
  dam/                        Digital Asset Management — main active area
    brand_resolver.rb         Centralizes ALL brand name transformations (appydave ↔ v-appydave)
    errors.rb                 Custom exception hierarchy (DamError, BrandNotFoundError, etc.)
    fuzzy_matcher.rb          Levenshtein distance for "did you mean?" suggestions
    git_helper.rb             Extracted git command wrappers (current_branch, commits_ahead, etc.)
    file_helper.rb            File utility methods (calculate_directory_size, format_size, format_age)
    config.rb                 Delegates brand resolution to BrandResolver; memoized Config loading
    project_resolver.rb       Project name resolution with regex pattern matching
    project_listing.rb        Table display for `dam list` command (format() for headers + data)
    s3_operations.rb          S3 upload/download/status with MD5 comparison
    s3_scanner.rb             S3 bucket scanner for s3-scan command
    status.rb                 Project git/S3 status display
    manifest_generator.rb     Video project manifest
    sync_from_ssd.rb          SSD sync operations
    ssd_status.rb             SSD backup status
    share_operations.rb       Pre-signed URL generation
    config_loader.rb          Loads .video-tools.env per brand
    repo_push.rb, repo_status.rb, repo_sync.rb
    # NEW — being created in this campaign:
    local_sync_status.rb      [WU2] Enrich project data with local s3-staging sync status
    s3_scan_command.rb        [WU3] S3 scan orchestration + display (extracted from VatCLI)
    s3_arg_parser.rb          [WU4] CLI argument parsing for S3 commands (extracted from VatCLI)
lib/appydave/tools.rb         Require file — ADD new dam files here after creating them
spec/
  appydave/tools/dam/         One spec file per dam/ class
  support/
    dam_filesystem_helpers.rb Shared contexts for DAM filesystem testing
```

---

## This Campaign: What We're Extracting from bin/dam

`bin/dam` is a 1,600-line `VatCLI` class with 20+ `rubocop-disable` comments. Four clusters of business logic are being extracted.

### Work Unit Dependencies

All 4 work units touch `bin/dam`. Run SEQUENTIALLY — never in parallel.

```
WU1: extract-format-bytes        (no deps)
WU2: extract-local-sync-status   (no deps — but WU3 depends on it)
WU3: extract-s3-scan-command     (DEPENDS ON WU2 — uses LocalSyncStatus)
WU4: extract-s3-arg-parser       (no deps on WU1-3 — run after WU3 for safety)
```

### WU1: extract-format-bytes

**What:** `VatCLI#format_bytes` is a duplicate of `FileHelper.format_size` (already exists, already tested).

**Change:**
- Replace 3 callers in `bin/dam` with `Appydave::Tools::Dam::FileHelper.format_size(x)`:
  - Line 1510 in `display_s3_scan_table`
  - Line 696 in `display_s3_files`
  - Line 702 in `display_s3_files`
- Delete `format_bytes` method from VatCLI (lines 1586-1597, including rubocop-disable/enable wrapper)
- No new spec needed — `FileHelper.format_size` already has specs

**Done when:** rubocop 0 offenses, 831 examples passing, `format_bytes` gone from bin/dam.

### WU2: extract-local-sync-status

**What:** `add_local_sync_status!` and `format_local_status` are VatCLI private methods. They contain business logic (filesystem inspection + status classification) that belongs in a library class.

**Create** `lib/appydave/tools/dam/local_sync_status.rb`:
```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Enriches S3 scan project data with local s3-staging sync status
      module LocalSyncStatus
        module_function

        # Mutates matched_projects hash to add :local_status key
        # @param matched_projects [Hash] Map of project_id => S3 data
        # @param brand_key [String] Brand key (e.g., 'appydave')
        def enrich!(matched_projects, brand_key)
          # (move add_local_sync_status! body here — change Config.project_path call to use Dam::Config)
        end

        # Format local sync status for display
        # @param status [Symbol] :synced, :no_files, :partial, :no_project
        # @param local_count [Integer, nil] Number of local files
        # @param s3_count [Integer] Number of S3 files
        # @return [String] Formatted status string
        def format(status, local_count, s3_count)
          # (move format_local_status body here)
        end
      end
    end
  end
end
```

**Update callers in bin/dam:**
- `scan_single_brand_s3`: replace `add_local_sync_status!(matched_projects, brand_key)` with `Appydave::Tools::Dam::LocalSyncStatus.enrich!(matched_projects, brand_key)`
- `display_s3_scan_table`: replace `format_local_status(data[:local_status], data[:local_file_count], data[:file_count])` with `Appydave::Tools::Dam::LocalSyncStatus.format(data[:local_status], data[:local_file_count], data[:file_count])`

**Register** in `lib/appydave/tools.rb` after line 79: `require 'appydave/tools/dam/local_sync_status'`

**Add spec** `spec/appydave/tools/dam/local_sync_status_spec.rb` — test `enrich!` with a temp filesystem (use `include_context 'with vat filesystem and brands'`), test `format` for all 4 status symbols.

**Done when:** rubocop 0 offenses, 832+ examples passing (new specs), `add_local_sync_status!` and `format_local_status` gone from bin/dam.

### WU3: extract-s3-scan-command

**What:** `scan_single_brand_s3`, `scan_all_brands_s3`, and `display_s3_scan_table` are 140 lines of orchestration + display logic in VatCLI. Extract to a new class.

**Prerequisite:** WU2 must be complete — `S3ScanCommand` uses `LocalSyncStatus.enrich!` and `LocalSyncStatus.format`.

**Create** `lib/appydave/tools/dam/s3_scan_command.rb` — class with:
- `scan_single(brand_key)` — body from `scan_single_brand_s3`
- `scan_all` — body from `scan_all_brands_s3`
- `display_table(matched_projects, orphaned_projects, bucket, prefix, region)` — body from `display_s3_scan_table` (private, called from scan_single)

**Update bin/dam:**
```ruby
def s3_scan_command(args)
  all_brands = args.include?('--all')
  args = args.reject { |arg| arg.start_with?('--') }
  brand_arg = args[0]

  if all_brands
    Appydave::Tools::Dam::S3ScanCommand.new.scan_all
  elsif brand_arg
    Appydave::Tools::Dam::S3ScanCommand.new.scan_single(brand_arg)
  else
    # show usage (keep inline — 4 lines)
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
  exit 1
end
```
Delete `scan_single_brand_s3`, `scan_all_brands_s3`, `display_s3_scan_table` from VatCLI.

**Register** in `lib/appydave/tools.rb`: `require 'appydave/tools/dam/s3_scan_command'`

**Add spec** `spec/appydave/tools/dam/s3_scan_command_spec.rb` — smoke test that the class loads and methods exist; mock `S3Scanner` and `Config`; no full S3 integration needed.

**Done when:** rubocop 0 offenses, 832+ examples passing, 3 methods gone from bin/dam.

### WU4: extract-s3-arg-parser

**What:** `parse_s3_args`, `valid_brand?`, `parse_share_args`, `show_share_usage_and_exit`, `parse_discover_args` are 130 lines of argument parsing in VatCLI. All set `ENV['BRAND_PATH']` and share the same brand/project resolution chain.

**Create** `lib/appydave/tools/dam/s3_arg_parser.rb` — module with `module_function`:
- `parse_s3(args, command)` — from `parse_s3_args`
- `parse_share(args)` — from `parse_share_args`
- `parse_discover(args)` — from `parse_discover_args`
- `valid_brand?(brand_key)` — from `valid_brand?` (private helper, keep as module_function)
- `show_share_usage_and_exit` — from `show_share_usage_and_exit` (private helper)

**Update callers in bin/dam** (5 methods to update):
- `s3_up_command`, `s3_down_command`, `s3_status_command`, `s3_cleanup_remote_command`, `s3_cleanup_local_command`, `archive_command`: replace `parse_s3_args(args, '...')` with `Appydave::Tools::Dam::S3ArgParser.parse_s3(args, '...')`
- `s3_share_command`: replace `parse_share_args(args)` with `Appydave::Tools::Dam::S3ArgParser.parse_share(args)`
- `s3_discover_command`: replace `parse_discover_args(args)` with `Appydave::Tools::Dam::S3ArgParser.parse_discover(args)`

**Register** in `lib/appydave/tools.rb`: `require 'appydave/tools/dam/s3_arg_parser'`

**Add spec** `spec/appydave/tools/dam/s3_arg_parser_spec.rb` — test `parse_s3` with brand+project args, with PWD auto-detect (mock `ProjectResolver.detect_from_pwd`), with invalid brand; test `valid_brand?` with known brands.

**Done when:** rubocop 0 offenses, 833+ examples passing, 5 methods gone from bin/dam.

---

## Success Criteria

Every work unit must satisfy ALL of the following before marking `[x]`:

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 831+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 85.92%
- [ ] Any new `.rb` files start with `# frozen_string_literal: true`
- [ ] New class/module registered in `lib/appydave/tools.rb`
- [ ] At least 1 spec for each new library file
- [ ] Extracted methods removed from VatCLI in `bin/dam`
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
Appydave::Tools::Dam::FileHelper.format_size(bytes)          # "1.5 GB"
Appydave::Tools::Dam::FileHelper.calculate_directory_size(path) # Integer bytes
Appydave::Tools::Dam::FileHelper.format_age(time)            # "3d", "2w", etc.
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
raise ProjectNotFoundError, 'Project name is required' if project_hint.nil?
raise BrandNotFoundError.new(brand, available_brands, fuzzy_suggestions)
```

---

## Anti-Patterns to Avoid

- ❌ Inline brand transformations — never write `"v-#{brand}"` outside BrandResolver
- ❌ `format_bytes` — does not exist anymore; use `FileHelper.format_size`
- ❌ Duplicating `format_size` / byte formatting logic — use `FileHelper.format_size`
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

### External Services

```ruby
# S3 calls
stub_request(:get, /s3\.amazonaws\.com/).to_return(body: '...')
```

---

## Quality Gates

- **Tests:** `RUBYOPT="-W0" bundle exec rspec` — 831+ examples, 0 failures
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

- **Dirty working tree + kfix = accidental staging.** Always run `git status` before committing. micro-cleanup accidentally staged a pre-existing `lib/appydave/tools.rb` change.
- **Pre-existing "already fixed" items:** Check B-items aren't already done before acting (B031, B033 were already committed; B015, B019 also).

### From Architectural Review (2026-03-19)

- **bin/dam is the primary DAM CLI entry point.** Regressions here affect real workflows. Test every command path after extraction.
- **`ENV['BRAND_PATH']` is set in 5 places in bin/dam.** Three are in parse methods (being extracted). Two remain in `generate_single_manifest` and `sync_ssd_command` — out of scope.
- **Do NOT attempt B020 (split S3Operations) in this campaign.** Different class, different risk profile.
