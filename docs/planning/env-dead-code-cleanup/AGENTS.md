# AGENTS.md — AppyDave Tools / env-dead-code-cleanup campaign

> Operational knowledge for every background agent. Self-contained — you receive only this file + your work unit prompt.
> Inherited from: library-boundary-cleanup campaign (2026-03-20)
> Updated for: env-dead-code-cleanup campaign (2026-03-20)

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Active campaign:** env-dead-code-cleanup — remove confirmed dead ENV code and strengthen one test assertion.
**Commits:** Always use `kfeat`/`kfix` — never `git commit` directly.

---

## ⚠️ Pre-Commit Check (Mandatory Every Commit)

`kfix` and `kfeat` run `git add .` internally — they stage EVERYTHING in the working tree unconditionally. You cannot selectively stage files.

**The only safe approach: ensure the working tree contains ONLY your intended changes before calling kfix.**

```bash
git status          # What files are modified/untracked?
git diff            # What are the actual changes?
```

If unintended files appear (e.g. planning docs, other specs):
- `git stash -- path/to/file` to temporarily stash a specific file
- OR `git checkout -- path/to/file` to discard an unintended change
- OR `git clean -n` to preview, then `git clean -f path/to/file` for untracked files

Once the working tree contains ONLY the files you intended to change, call:
```bash
kfix "your message here"
```

kfix/kfeat then:
1. `git add .` — stages everything (working tree must be clean of unintended files)
2. `git commit -m "fix: ..."` — commits
3. `git pull` + `git push` — syncs and pushes
4. Waits for CI (`gh run watch`) — blocks until green or red
5. On success: `git pull` again to pick up semantic-release version bump + CHANGELOG
6. Prints the new version tag

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                              # Full suite
bundle exec rspec spec/appydave/tools/dam/s3_scan_command_spec.rb  # Single file
bundle exec rubocop --format clang                           # Lint (matches CI)

kfeat "description"   # Minor version bump
kfix "description"    # Patch version bump
```

**Baseline (start of env-dead-code-cleanup):** 861 examples, 0 failures, 86.43% line coverage

---

## Directory Structure

```
bin/
  dam                           Main DAM CLI — target of B038 (10 ENV removals)
lib/appydave/tools/dam/
  errors.rb                     UsageError, ConfigurationError, etc.
  s3_scan_command.rb            S3 scan orchestration
  s3_arg_parser.rb              CLI arg parsing — ENV side-effect already removed
  local_sync_status.rb          Local s3-staging sync status
  manifest_generator.rb         ManifestGenerator — confirmed does NOT read ENV['BRAND_PATH']
  sync_from_ssd.rb              SyncFromSsd — confirmed does NOT read ENV['BRAND_PATH']
spec/
  appydave/tools/dam/
    s3_scan_command_spec.rb     Target of B039 (strengthen assertions)
    local_sync_status_spec.rb   Already updated in library-boundary-cleanup
```

---

## This Campaign

### B038 — remove-env-dead-code

**File:** `bin/dam` only.

Remove all 10 `ENV['BRAND_PATH'] =` lines. Confirmed dead:
- `grep -rn "BRAND_PATH" lib/ spec/` → 0 results
- ManifestGenerator, SyncFromSsd: grep confirmed no reads

**10 lines to delete** (line numbers approximate after prior edits — grep to find exact):

| Method | Pattern to remove |
|--------|------------------|
| s3_up_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_down_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_status_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_cleanup_remote_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_cleanup_local_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_archive_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_share_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| s3_discover_command | `ENV['BRAND_PATH'] = options[:brand_path]` |
| generate_single_manifest | `ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand_arg)` |
| sync_ssd_command | `ENV['BRAND_PATH'] = Appydave::Tools::Dam::Config.brand_path(brand_arg)` |

After removing, also check if `options[:brand_path]` was the ONLY use of `options` in any method. If so, the `options =` assignment itself may now be unused. Grep the method body before removing.

**Done when:**
- `grep -n "BRAND_PATH" bin/dam` → 0 results
- `RUBYOPT="-W0" bundle exec rspec` → 861 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- `git status` clean (working tree contains ONLY bin/dam changes before calling kfix)

**Commit:** `kfix "remove ENV BRAND_PATH dead code from bin/dam (10 assignments, never read in lib)"`

---

### B039 — strengthen-s3-scan-spec

**File:** `spec/appydave/tools/dam/s3_scan_command_spec.rb` only.

**Read the current spec file in full before making any changes.**

Two specific improvements:

**1. Replace `not_to be_empty` with field-value assertion**

Find the test that checks `project[:storage][:s3]` and replace the weak emptiness check:
```ruby
# Before (weak):
expect(project[:storage][:s3]).not_to be_empty

# After (catches wrong values):
expect(project[:storage][:s3]).to include(
  file_count: 3,
  total_bytes: 1_500_000,
  last_modified: '2025-01-01T00:00:00Z'
)
```

Match the values to whatever the mock `scan_all_projects` returns in that context.

**2. Remove LocalSyncStatus stub, let integration run**

Find:
```ruby
allow(Appydave::Tools::Dam::LocalSyncStatus).to receive(:enrich!)
```

Remove this line. `LocalSyncStatus.enrich!` uses the filesystem — it needs the s3-staging directory to exist (or it sets `:no_project`/:no_files`). The test doesn't need to assert on `:local_status` — just ensure it doesn't raise.

If removing the stub causes failures because LocalSyncStatus can't find the brand path, add an `s3-staging` folder to the fixture:
```ruby
FileUtils.mkdir_p(File.join(appydave_path, 'b65-test-project', 's3-staging'))
```

**Done when:**
- `bundle exec rspec spec/appydave/tools/dam/s3_scan_command_spec.rb` → all pass
- `RUBYOPT="-W0" bundle exec rspec` → 861 examples, 0 failures (count unchanged — no new specs)
- `bundle exec rubocop --format clang` → 0 offenses
- `git status` clean (working tree contains ONLY the spec file changes before calling kfix)

**Commit:** `kfix "strengthen s3_scan_command_spec field assertions; remove LocalSyncStatus stub"`

---

## Success Criteria (Every Work Unit)

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 861+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage ≥ 86.43%
- [ ] `git status` clean (working tree contains ONLY intended changes before calling kfix)

---

## Reference Patterns

### Shared Context for DAM Specs

```ruby
RSpec.describe Appydave::Tools::Dam::SomeClass do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]
  # Provides: temp_folder, projects_root, appydave_path, voz_path
  # SettingsConfig#video_projects_root mocked to return projects_root
end
```

### instance_double — Always Use Full Constant

```ruby
# Correct:
instance_double(Appydave::Tools::Configuration::Models::BrandsConfig)

# Wrong — fails CI on Ubuntu:
instance_double('BrandsConfig')
```

### Typed Exception Pattern

```ruby
raise Appydave::Tools::Dam::ConfigurationError, 'Manifest not found: /path'
raise Appydave::Tools::Dam::UsageError, 'Usage: dam s3-up <brand> <project>'
```

---

## Anti-Patterns to Avoid

- ❌ Calling `kfix`/`kfeat` with unintended files in the working tree — clean the tree first, then call kfix
- ❌ `exit 1` in library code — use typed exceptions (already fixed in library-boundary-cleanup)
- ❌ `ENV['BRAND_PATH'] =` in any file — confirmed dead, being removed in B038
- ❌ `instance_double('StringForm')` — use full constant always
- ❌ Inline brand transformations — use BrandResolver
- ❌ Multiple `before` blocks in same RSpec context — merge them (RSpec/ScatteredSetup)
- ❌ `$?` for subprocess status — use `$CHILD_STATUS`

---

## Learnings

### From library-boundary-cleanup (2026-03-20)

- **`instance_double` string form fails CI on Ubuntu.** Always use full constant: `instance_double(Fully::Qualified::ClassName)`.
- **Dirty working tree + kfix = accidental staging.** `kfix` runs `git add .` internally — it stages everything. Ensure the working tree contains ONLY intended changes before calling kfix.
- **`ENV['BRAND_PATH']` in bin/dam is dead code.** 10 assignments, 0 reads. Being removed in B038.
- **VatCLI rescue blocks catch DamError correctly.** `UsageError < DamError < StandardError` — all 17 rescue blocks catch it without modification.

### From extract-vat-cli (2026-03-19)

- **Dirty working tree + kfix = accidental staging.** Run `git status` before every commit.
- **rubocop-disable directives become redundant when methods move.** Check for orphaned disable/enable pairs after extraction.
- **valid_brand? needs Config.brands mock.** Shared filesystem context only mocks SettingsConfig; Config.brands needs a separate mock.
- **S3ScanCommand#scan_all already rescues per-brand.** Per-brand exceptions are isolated by design.

### From DAM Enhancement Sprint (Jan 2025)

- **BrandResolver is the critical path.** All dam commands flow through it.
- **`Config.configure` is memoized but called redundantly.** Don't add new calls.
- **Table format() pattern is non-obvious.** Headers misaligned 3× in UAT. Always verify with real data.
