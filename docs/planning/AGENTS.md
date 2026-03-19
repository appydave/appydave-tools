# AGENTS.md — AppyDave Tools

> Operational knowledge for every background agent. Self-contained — you receive only this file + your work unit prompt.
> Last updated: 2026-03-19 (derived from actual files, not guesswork)

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Active area:** DAM (Digital Asset Management) — `lib/appydave/tools/dam/` — is the primary focus of recent campaigns.
**Commits:** Trigger automated semantic versioning via GitHub Actions. Always use `kfeat`/`kfix` — never `git commit`.

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

**Baseline (2026-03-19):** 748 examples, 0 failures, 84.88% line coverage (7680/9048)

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
    file_helper.rb            File utility methods (directory size, format_size)
    config.rb                 Delegates brand resolution to BrandResolver; memoized Config loading
    project_resolver.rb       Project name resolution with regex pattern matching
    project_listing.rb        Table display for `dam list` command (format() for headers + data)
    s3_operations.rb          S3 upload/download/status with MD5 comparison
    status.rb                 Project git/S3 status display
    manifest_generator.rb     Video project manifest
    sync_from_ssd.rb          SSD sync operations
    ssd_status.rb             SSD backup status
    repo_push.rb, repo_status.rb, repo_sync.rb, share_operations.rb, config_loader.rb, s3_scanner.rb
  configuration/              Config file management (settings.json, channels.json)
  gpt_context/                File collection for AI context gathering
  subtitle_processor/         SRT file cleaning and joining
  youtube_manager/            YouTube API integration
  name_manager/               Jump location tool (fuzzy search, CRUD, alias generation)
  types/                      BaseModel, ArrayType, HashType, IndifferentAccessHash
spec/
  appydave/tools/dam/         14 spec files (one per dam/ class)
  support/
    dam_filesystem_helpers.rb Shared contexts for DAM filesystem testing
    jump_test_helpers.rb      Jump tool test helpers
docs/
  backlog.md                  Legacy requirements (BACKLOG.md in this folder supersedes)
  code-quality/               Audit reports (behavioral-audit-2025-01-22, uat-report-2025-01-22)
  planning/                   Ralphy campaign artifacts (this folder)
  architecture/               CLI patterns, testing patterns, configuration systems
```

---

## Success Criteria

Every work unit must satisfy ALL of the following before marking `[x]`:

- [ ] `bundle exec rspec` — 748+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 84.88%
- [ ] Any new functionality has ≥ 1 spec covering it
- [ ] All new `.rb` files start with `# frozen_string_literal: true`
- [ ] No hardcoded brand transformation strings (always use BrandResolver)

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
    FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
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

### BrandResolver — All Brand Name Transformations

```ruby
BrandResolver.expand('appydave')      # => 'v-appydave'
BrandResolver.expand('ad')            # => 'v-appydave' (shortcut)
BrandResolver.expand('joy')           # => 'v-beauty-and-joy'
BrandResolver.normalize('v-appydave') # => 'appydave'
BrandResolver.to_config_key('ad')     # => 'appydave'
BrandResolver.to_display('voz')       # => 'v-voz'
BrandResolver.validate('appydave')    # => 'appydave' or raises BrandNotFoundError
BrandResolver.exists?('appydave')     # => true/false
```

### Typed Exception Pattern

```ruby
# Use errors from lib/appydave/tools/dam/errors.rb
raise ProjectNotFoundError, 'Project name is required' if project_hint.nil?
raise BrandNotFoundError.new(brand, available_brands, fuzzy_suggestions)

# Exception hierarchy:
# DamError < StandardError
#   BrandNotFoundError < DamError
#   ProjectNotFoundError < DamError
#   ConfigurationError < DamError
#   S3OperationError < DamError
#   GitOperationError < DamError
```

### Table Display — Headers Must Use format()

```ruby
# CORRECT — headers and data use same format string
header = format('%-45s %12s %15s %10s', 'PROJECT', 'SIZE', 'AGE', 'GIT')
row    = format('%-45s %12s %15s %10s', name,      size,   age,  git_status)

# WRONG — hardcoded header string causes misalignment
header = 'PROJECT        SIZE    AGE     GIT'
```

---

## Anti-Patterns to Avoid

- ❌ Inline brand transformations — never write `"v-#{brand}"` or `.sub(/^v-/, '')` outside BrandResolver
- ❌ Mocking Config class methods in DAM specs — use `include_context 'with vat filesystem and brands'` instead
- ❌ `raise 'string error'` in DAM module — use typed exceptions from `errors.rb`
- ❌ Duplicating git command methods — use `GitHelper` module
- ❌ Duplicating file size calculations — use `FileHelper` module
- ❌ `include FileUtils` (conflicts with Ruby stdlib) — use dam's `FileHelper`
- ❌ Hardcoded header strings for table output — always use `format()` with same format string as data rows

---

## Mock Patterns

### External Services — DO Mock

```ruby
# S3 calls — use WebMock or VCR cassettes
stub_request(:get, /s3\.amazonaws\.com/).to_return(body: '...')

# YouTube API — VCR cassettes in spec/fixtures/vcr_cassettes/
VCR.use_cassette('youtube/get_video') do
  # make API call
end
```

### Internal DAM Classes — DON'T Mock

Use real temp filesystem via shared context instead. The only acceptable mock inside DAM specs:
- `SettingsConfig#video_projects_root` — already mocked by the shared context
- `Config.available_brands` — acceptable when testing "no brands found" edge case

### Config.configure — Safe to Call Multiple Times

```ruby
# Config.configure is memoized — idempotent, no-op after first call
# Called in multiple places across DAM module; this is known/acceptable technical debt
Appydave::Tools::Configuration::Config.configure
```

---

## Quality Gates

- **Tests:** `bundle exec rspec` — 748 examples, 0 failures (do not ship if any fail)
- **Lint:** `bundle exec rubocop --format clang` — 0 offenses (CI will reject)
- **Coverage:** ≥ 84.88% line coverage
- **frozen_string_literal:** Required on every new `.rb` file
- **Commit format:** `kfeat`/`kfix` only — triggers semantic versioning + CI wait

---

## Learnings

### From DAM Enhancement Sprint (Jan 2025 — 75 commits, 9e49668 → 4228b51)

- **BrandResolver is the critical path.** All `dam` commands flow through it. Any change to brand resolution must be tested with all shortcuts (ad, joy, ss, voz, aitldr, kiros) and case variations (APPYDAVE, AppyDave).
- **`Regexp.last_match` is reset by `.sub()` calls.** Always capture regex groups BEFORE any string transformation: `project = ::Regexp.last_match(2)` then `brand_key = BrandResolver.normalize(brand_with_prefix)`.
- **`Config.configure` is memoized but called redundantly.** ~7 calls in config.rb, plus more in other files. Known issue, not worsened. Don't add new calls; reference existing ones.
- **FuzzyMatcher threshold is 3 (Levenshtein distance).** Wired via `Config#brand_path` → `FuzzyMatcher.find_matches(brand_key, all_brand_identifiers, threshold: 3)`. Works for "appydav" → "appydave".
- **Performance: ~2s per project** for git/S3 checks during `dam list`. 13 projects = ~26s total. Acceptable. Grows linearly — flag if brand has > 20 projects.
- **Table format() pattern is non-obvious.** Headers misaligned 3 times in UAT before fix. Always verify with real data that has long names (e.g., "beauty-and-joy" = 14 chars).
- **Test strategy:** 5 new spec files (+648 lines) added for DAM helper classes. `project_listing_spec.rb` refactored from 20 Config mocks to shared filesystem context. Task 3.1 complete.

### From Jump Location Tool (Dec 2025)

- **Dependency injection for path validators** is required for CI compatibility. Path existence checks fail in CI — inject via parameter, not hardcoded.
- **BUG-1 status (as of 2026-03-19 audit):** Static analysis shows `Jump::Config#find` and `Commands::Remove` both have correct dual-key guards (`loc.key == key` on Location objects; `loc['key'] == key || loc[:key] == key` on raw hashes). The bug may be environmental or already fixed. Always verify live before writing fix code.
- **Jump Commands layer is undertested:** `Commands::Remove`, `Commands::Add`, `Commands::Update` have zero dedicated specs. Auto-regenerate CLI spec does not substitute for command-layer unit tests verifying `--force` guards, error codes, and suggestion logic (see B018).
- **Jump report commands** got `--limit` and `--skip-unassigned` flags after initial implementation. Jump tool scope grows incrementally.

### From Three-Lens Audit (2026-03-19)

- **`file_collector.rb` has two landmines before FR-2:** `puts @working_directory` at line 15 pollutes stdout; `FileUtils.cd` without `ensure` leaves process in wrong directory on exception. Fix both before adding any code to this class.
- **ManifestGenerator and SyncFromSsd produce incompatible range strings (B016).** `determine_range('b65')` returns `"b50-b99"` in one and `"60-69"` in the other. This is a data integrity bug for SSD archive path construction. Do not add new archive features before this is resolved.
- **`ssl_verify_peer: false` is set unconditionally in S3Operations and ShareOperations (B017).** Not safe despite the comment. Remove before adding any new S3 functionality.
- **`Config.configure` fires inside nested call chains** (e.g., `brand_path` → `BrandResolver.to_config_key` → `configure` = 3 calls for one operation). Memoized, so no performance cost, but pattern will spread if not watched. Do not add new `Config.configure` calls; reference from the existing top-level call.
- **BUG-1 is NOT in `name_manager/`.** Jump's `name_manager/project_name.rb` is a different unrelated class. BUG-1 root is in `lib/appydave/tools/jump/` (Config, Search, Commands).
