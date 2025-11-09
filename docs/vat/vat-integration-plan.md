# VAT Integration Plan

**Date**: 2025-11-08
**Status**: Planning Phase
**Target**: Integrate VAT (Video Asset Tools) into appydave-tools gem

---

## Executive Summary

### What
Integrate VAT (Video Asset Tools) from `/Users/davidcruwys/dev/video-projects/video-asset-tools/` into the appydave-tools gem using a "pull" approach.

### Why
- VAT currently has NO version control, NO backup, NO testing infrastructure
- Perfect alignment with appydave-tools philosophy (consolidated toolkit, single-purpose, CLI-first)
- Part of AppyDave's YouTube workflow (video project asset management)
- Enables collaboration (Jan can submit PRs), testing (RSpec + Guard), and professional distribution

### Scope
- **Phase 1 (Working)**: `vat list`, `vat s3-up` - Already support CLI args
- **Phase 2 (Needs Work)**: `vat s3-down`, `vat s3-status`, `vat s3-cleanup` - Add CLI arg support
- **All Phases**: Complete integration with tests, docs, and quality checks

---

## Architecture Analysis

### Current VAT Structure

```
video-asset-tools/
├── vat                          # Bash dispatcher
├── bin/
│   ├── vat_init.rb             # Initialize ~/.vat-config
│   ├── vat_help.rb             # Help system
│   ├── vat_list.rb             # ✅ Phase 1 complete
│   ├── s3_sync_up.rb           # ✅ Phase 1 complete
│   ├── s3_sync_down.rb         # ⏳ Phase 2 - needs CLI args
│   ├── s3_sync_status.rb       # ⏳ Phase 2 - needs CLI args
│   ├── s3_sync_cleanup.rb      # ⏳ Phase 2 - needs CLI args
│   ├── generate_manifest.rb    # Generate projects.json
│   ├── archive_project.rb      # Archive to SSD
│   └── sync_from_ssd.rb        # Sync from SSD backup
├── lib/
│   ├── vat_config.rb           # Config management (VIDEO_PROJECTS_ROOT, brands)
│   ├── project_resolver.rb     # Project name resolution (b65 → full name)
│   └── config_loader.rb        # Load .video-tools.env files
└── docs/
    ├── README.md
    ├── architecture.md
    ├── onboarding.md
    └── aws-setup.md
```

### Target appydave-tools Structure

```
appydave-tools/
├── bin/
│   ├── vat                      # Bash dispatcher (from VAT)
│   ├── vat_init.rb             # Direct executable
│   ├── vat_help.rb
│   ├── vat_list.rb
│   ├── s3_sync_up.rb
│   ├── s3_sync_down.rb         # Update for CLI args
│   ├── s3_sync_status.rb       # Update for CLI args
│   ├── s3_sync_cleanup.rb      # Update for CLI args
│   ├── generate_manifest.rb
│   ├── archive_project.rb
│   └── sync_from_ssd.rb
│
├── lib/appydave/tools/vat/
│   ├── config.rb               # From vat_config.rb
│   ├── project_resolver.rb     # From project_resolver.rb
│   └── config_loader.rb        # From config_loader.rb
│
├── spec/appydave/tools/vat/
│   ├── config_spec.rb
│   ├── project_resolver_spec.rb
│   └── config_loader_spec.rb
│
└── docs/usage/
    ├── vat.md                  # Comprehensive usage guide
    └── vat/
        ├── architecture.md
        ├── aws-setup.md
        └── onboarding.md
```

### Key Design Patterns (from existing appydave-tools)

**Module Namespacing**:
```ruby
module Appydave
  module Tools
    module Vat
      class Config
        # Implementation
      end
    end
  end
end
```

**Executable Pattern** (from `bin/gpt_context.rb`):
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'appydave/tools'

# Use namespaced modules
options = Appydave::Tools::Vat::Options.new
# ... parse args, run command
```

**Testing Pattern** (from `config_spec.rb`):
```ruby
# frozen_string_literal: true

require 'rspec'
require 'tmpdir'

RSpec.describe Appydave::Tools::Vat::Config do
  let(:temp_folder) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(temp_folder)
  end

  describe '.projects_root' do
    context 'when ~/.vat-config exists' do
      it 'returns configured path'
    end

    context 'when config missing' do
      it 'raises helpful error'
    end
  end
end
```

---

## Phase 2 Command Updates (Critical)

### Problem
The following commands work via auto-detection (PWD) but DO NOT accept CLI args:
- `s3_sync_down.rb`
- `s3_sync_status.rb`
- `s3_sync_cleanup.rb`

### Solution Pattern (from s3_sync_up.rb lines 227-276)

**Before (s3_sync_down.rb lines 253-269)**:
```ruby
def parse_args
  dry_run = ARGV.include?('--dry-run')
  project_id = ARGV.find { |arg| !arg.start_with?('--') }

  # Auto-detect if not provided
  project_id ||= detect_project_id

  unless project_id
    puts "❌ Error: Could not detect project ID"
    exit 1
  end

  [project_id, dry_run]
end
```

**After (following s3_sync_up.rb pattern)**:
```ruby
def parse_args
  args = ARGV.reject { |arg| arg.start_with?('--') }
  dry_run = ARGV.include?('--dry-run')

  brand_arg = args[0]
  project_arg = args[1]

  # If no args, try to auto-detect from pwd
  if brand_arg.nil?
    brand, project_id = ProjectResolver.detect_from_pwd

    unless brand && project_id
      puts "❌ Error: Could not detect brand and project"
      puts ""
      puts "Usage:"
      puts "  vat s3-down [brand] [project] [--dry-run]"
      exit 1
    end

    return [brand, project_id, dry_run]
  end

  # Expand brand shortcut
  brand = VatConfig.expand_brand(brand_arg)

  # Resolve project name (handles b65 → b65-full-name expansion)
  begin
    project_id = if project_arg
                   ProjectResolver.resolve(brand_arg, project_arg)
                 else
                   puts "❌ Error: Project name required"
                   puts "Usage: vat s3-down #{brand_arg} <project>"
                   exit 1
                 end
  rescue StandardError => e
    puts e.message
    exit 1
  end

  [brand, project_id, dry_run]
end
```

**Required Changes**:
1. Add `require_relative '../lib/vat_config'` at top
2. Add `require_relative '../lib/project_resolver'` at top
3. Update `parse_args` to accept brand + project args
4. Remove hardcoded `detect_brand()` functions
5. Use `VatConfig.expand_brand()` and `ProjectResolver.resolve()`
6. Update main to set `ENV['BRAND_PATH']` for config loading

---

## Critical Knowledge: The 6 Brands

**Must preserve these in tests and code**:

| Shortcut | Full Name | Purpose | Pattern |
|----------|-----------|---------|---------|
| `appydave` | `v-appydave` | AppyDave brand | FliVideo (b65, b66) |
| `voz` | `v-voz` | VOZ client | Storyline (boy-baker) |
| `aitldr` | `v-aitldr` | AITLDR brand | Storyline (movie-posters) |
| `kiros` | `v-kiros` | Kiros client | Storyline |
| `joy` | `v-beauty-and-joy` | Beauty & Joy | Storyline |
| `ss` | `v-supportsignal` | SupportSignal | Storyline |

**Project Name Patterns**:
- **FliVideo**: `b65` → `b65-guy-monroe-marketing-plan` (short name expansion)
- **Storyline**: `boy-baker` → `boy-baker` (exact match, no expansion)

---

## Migration Checklist

### ✅ Phase 1: Discovery & Planning (CURRENT)
- [x] Read integration-brief.md
- [x] Read purpose-and-philosophy.md
- [x] Explore VAT source structure
- [x] Review existing appydave-tools patterns
- [x] Create this integration plan document

### [ ] Phase 2: Core Module Migration
- [ ] Create `lib/appydave/tools/vat/` directory
- [ ] Migrate `vat_config.rb` → `lib/appydave/tools/vat/config.rb`
  - [ ] Add module namespacing: `Appydave::Tools::Vat::Config`
  - [ ] Update all method references
  - [ ] Update `require_relative` paths
- [ ] Migrate `project_resolver.rb` → `lib/appydave/tools/vat/project_resolver.rb`
  - [ ] Add module namespacing
  - [ ] Update VatConfig references to use module path
- [ ] Migrate `config_loader.rb` → `lib/appydave/tools/vat/config_loader.rb`
  - [ ] Add module namespacing
  - [ ] Keep as utility class (no VatConfig dependencies)

### [ ] Phase 3: Executable Migration
- [ ] Copy `vat` bash dispatcher to `bin/vat`
- [ ] Copy `bin/*.rb` files to appydave-tools `bin/`
- [ ] Update all executables:
  - [ ] Add `$LOAD_PATH.unshift` for lib access
  - [ ] Update requires: `require 'appydave/tools'`
  - [ ] Update class references to use module namespace

### [ ] Phase 4: Complete Phase 2 Commands
- [ ] Update `s3_sync_down.rb`:
  - [ ] Add `require_relative '../lib/vat_config'`
  - [ ] Add `require_relative '../lib/project_resolver'`
  - [ ] Replace `parse_args` with Phase 1 pattern
  - [ ] Remove hardcoded `detect_brand()` function
  - [ ] Remove hardcoded `find_repo_root()` function
  - [ ] Update main to use `VatConfig.brand_path()`
- [ ] Update `s3_sync_status.rb`:
  - [ ] Same changes as s3_sync_down.rb
- [ ] Update `s3_sync_cleanup.rb`:
  - [ ] Same changes as s3_sync_down.rb
- [ ] Test all three commands:
  - [ ] CLI args: `vat s3-down appydave b65`
  - [ ] Auto-detect: `cd v-appydave/b65-project && vat s3-down`

### [ ] Phase 5: Testing
- [ ] Create `spec/appydave/tools/vat/` directory
- [ ] Write `config_spec.rb`:
  - [ ] Test `.projects_root` with temp config file
  - [ ] Test `.brand_path` expansion (appydave → v-appydave)
  - [ ] Test `.expand_brand` shortcuts (joy → v-beauty-and-joy, ss → v-supportsignal)
  - [ ] Test `.available_brands` discovery
  - [ ] Test error cases (config missing, brand not found)
  - [ ] Test all 6 brands
- [ ] Write `project_resolver_spec.rb`:
  - [ ] Test short name expansion (b65 → b65-project-name)
  - [ ] Test exact match (boy-baker → boy-baker)
  - [ ] Test pattern matching (b6* → b60-b69)
  - [ ] Test multiple matches (interactive selection)
  - [ ] Test error cases (no matches, invalid selection)
  - [ ] Test `.detect_from_pwd`
- [ ] Write `config_loader_spec.rb`:
  - [ ] Test `.load_from_repo` with valid config
  - [ ] Test error cases (missing file, missing required keys)
  - [ ] Test `.parse_env_file` with various formats
  - [ ] Test quote removal from values
- [ ] Run all tests: `bundle exec rspec spec/appydave/tools/vat/`
- [ ] Verify >80% coverage

### [ ] Phase 6: Documentation
- [ ] Create `docs/usage/vat.md`:
  - [ ] Quick start / installation
  - [ ] Configuration setup (`vat init`)
  - [ ] Command reference (list, s3-up, s3-down, s3-status, s3-cleanup)
  - [ ] Examples for all 6 brands
  - [ ] Pattern matching examples
  - [ ] Troubleshooting section
- [ ] Migrate architecture docs:
  - [ ] Copy `docs/architecture.md` → `docs/usage/vat/architecture.md`
  - [ ] Copy `docs/aws-setup.md` → `docs/usage/vat/aws-setup.md`
  - [ ] Copy `docs/onboarding.md` → `docs/usage/vat/onboarding.md`
- [ ] Update `README.md`:
  - [ ] Add VAT to "CLI Tools Usage" section
  - [ ] Add quick examples
  - [ ] Link to full guide
- [ ] Update `CLAUDE.md`:
  - [ ] Add VAT to tool index
  - [ ] Add CLI examples
  - [ ] Add configuration notes
- [ ] Update `CHANGELOG.md`:
  - [ ] Document VAT integration as new feature

### [ ] Phase 7: Quality & CI/CD
- [ ] Run RuboCop on all VAT files:
  - [ ] `bundle exec rubocop lib/appydave/tools/vat/`
  - [ ] `bundle exec rubocop spec/appydave/tools/vat/`
  - [ ] Fix all violations
- [ ] Update `Guardfile`:
  - [ ] Add VAT watch patterns
  - [ ] Test Guard auto-runs on file changes
- [ ] Verify all tests pass: `bundle exec rspec`
- [ ] Verify Guard works: `guard`
- [ ] Check CI/CD pipeline includes VAT tests

### [ ] Phase 8: Local Testing
- [ ] Update `lib/appydave/tools/version.rb` (note version, don't publish)
- [ ] Test gem build: `rake build`
- [ ] Test local gem install: `gem install pkg/appydave-tools-*.gem`
- [ ] Verify VAT commands work:
  - [ ] `vat init`
  - [ ] `vat list`
  - [ ] `vat list appydave`
  - [ ] `vat list appydave 'b6*'`
  - [ ] `vat s3-up appydave b65 --dry-run`
  - [ ] `vat s3-down voz boy-baker --dry-run`
  - [ ] Test auto-detection from PWD
- [ ] Test all 6 brands
- [ ] Document any issues for David to review

---

## Success Criteria

Integration succeeds when ALL of these are true:

### Functionality
- [ ] All VAT commands work with CLI args
- [ ] All VAT commands work with auto-detection
- [ ] Brand shortcuts expand correctly
- [ ] Short name expansion works (b65 → b65-project-name)
- [ ] Pattern matching works (b6* → b60-b69)
- [ ] Phase 2 commands completed with CLI arg support
- [ ] All 6 brands tested and working

### Testing
- [ ] RSpec tests pass with >80% coverage
- [ ] Tests for all 6 brands
- [ ] Tests for short name expansion
- [ ] Tests for pattern matching
- [ ] Guard auto-runs tests on file changes

### Integration
- [ ] Follows appydave-tools patterns (namespacing, require paths)
- [ ] Uses `lib/appydave/tools/vat/` namespace
- [ ] RuboCop passes (no violations)
- [ ] No breaking changes to existing tools

### Documentation
- [ ] README.md includes VAT
- [ ] CLAUDE.md includes VAT examples
- [ ] docs/usage/vat.md created
- [ ] Architecture docs migrated
- [ ] AWS setup guide included

### Local Testing (No Publishing)
- [ ] Gem builds successfully
- [ ] Local gem install works
- [ ] All commands functional after install
- [ ] Original VAT folder preserved until approved

---

## Risk Assessment

### Low Risk
✅ Core logic is production-ready (used in real projects)
✅ No changes to existing appydave-tools functionality
✅ Clear patterns to follow from existing code
✅ No gem dependencies (pure Ruby + AWS CLI)

### Medium Risk
⚠️ Phase 2 commands need updates (but pattern is clear)
⚠️ Testing AWS operations (need to stub `Open3.capture3`)
⚠️ Multiple hardcoded brand lists to update

### Mitigation
- Complete Phase 2 before declaring "done"
- Use temp directories for config tests
- Stub AWS CLI calls in tests
- Test all 6 brands explicitly
- Keep original VAT folder until approved

---

## Notes for Implementation

### Configuration Strategy
**Decision**: Keep separate (`~/.vat-config`, `.video-tools.env`)
**Rationale**: Minimal changes, proven pattern, merge later if needed

### Namespacing Strategy
**Decision**: Full module namespacing (`Appydave::Tools::Vat::Config`)
**Rationale**: Matches existing tools, avoids conflicts, professional

### Testing AWS Operations
**Strategy**: Stub `Open3.capture3` calls to `aws s3` commands
**Example**:
```ruby
allow(Open3).to receive(:capture3).with(
  'aws', 's3api', 'head-object', anything
).and_return(['{"ETag":"abc123"}', '', double(success?: true)])
```

### Brand Detection Refactoring (Future)
**Current**: Hardcoded if/elsif chains in multiple files
**Future**: Pattern-based discovery using regex
**Timeline**: Not critical for MVP, document as improvement

---

## Post-Integration Tasks (For David)

After integration is complete and tested:

1. **Review**:
   - [ ] Review all code changes
   - [ ] Test VAT commands manually
   - [ ] Verify documentation accuracy

2. **Cleanup**:
   - [ ] Decide whether to delete original `/video-projects/video-asset-tools/`
   - [ ] Update any workflows that reference old VAT location

3. **Publishing** (when ready):
   - [ ] Commit with conventional message: `feat: integrate VAT (Video Asset Tools) into appydave-tools`
   - [ ] Let semantic-release handle version bump and gem publishing
   - [ ] Announce VAT availability in appydave-tools

---

**Plan Created**: 2025-11-08
**Ready to Execute**: Awaiting approval to proceed with Phase 2
