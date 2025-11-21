# Code Quality Implementation Plan

**Based on:** [report-2025-01-21.md](./report-2025-01-21.md)

## Overview

This document outlines the step-by-step implementation plan for addressing code quality issues identified in the Jan 21, 2025 retrospective analysis.

## Implementation Strategy

### Phase 1: Quick Wins (1-2 days)
Extract duplicated utility code and establish patterns.

### Phase 2: Architectural Improvements (2-3 days)
Address core architectural issues (brand resolution, git helpers).

### Phase 3: Test Improvements (1 day)
Refactor tests to use consistent patterns.

### Phase 4: Documentation & Cleanup (1 day)
Document patterns and create guidelines.

---

## Phase 1: Quick Wins (Priority 1)

### Task 1.1: Extract FileUtils Module
**Effort:** 1 hour | **Priority:** Medium | **Risk:** Low

**Goal:** Consolidate directory size calculation into single module.

**Steps:**
1. Create `lib/appydave/tools/dam/file_utils.rb`
2. Extract methods:
   - `calculate_directory_size(path)` - from project_listing.rb:154, s3_operations.rb:770
   - `format_size(bytes)` - from project_listing.rb:176, sync_from_ssd.rb:270
3. Update callers:
   - `lib/appydave/tools/dam/project_listing.rb` (2 locations)
   - `lib/appydave/tools/dam/s3_operations.rb` (1 location)
   - `lib/appydave/tools/dam/sync_from_ssd.rb` (1 location)
4. Write specs: `spec/appydave/tools/dam/file_utils_spec.rb`
5. Run tests: `bundle exec rspec spec/appydave/tools/dam/`

**Implementation Example:**
```ruby
# lib/appydave/tools/dam/file_utils.rb
module Appydave
  module Tools
    module Dam
      module FileUtils
        module_function

        # Calculate total size of directory in bytes
        # @param path [String] Directory path
        # @return [Integer] Size in bytes
        def calculate_directory_size(path)
          return 0 unless Dir.exist?(path)

          total = 0
          Find.find(path) do |file_path|
            total += File.size(file_path) if File.file?(file_path)
          rescue StandardError
            # Skip files we can't read
          end
          total
        end

        # Format bytes into human-readable size
        # @param bytes [Integer] Size in bytes
        # @return [String] Formatted size (e.g., "1.5 GB")
        def format_size(bytes)
          return '0 B' if bytes.zero?

          units = %w[B KB MB GB TB]
          exp = (Math.log(bytes) / Math.log(1024)).to_i
          exp = [exp, units.length - 1].min

          format('%.1f %s', bytes.to_f / (1024**exp), units[exp])
        end
      end
    end
  end
end
```

**Testing Strategy:**
```ruby
RSpec.describe Appydave::Tools::Dam::FileUtils do
  describe '.calculate_directory_size' do
    it 'returns 0 for non-existent directory'
    it 'calculates size of directory with files'
    it 'handles permission errors gracefully'
  end

  describe '.format_size' do
    it 'formats bytes correctly' do
      expect(described_class.format_size(0)).to eq('0 B')
      expect(described_class.format_size(1024)).to eq('1.0 KB')
      expect(described_class.format_size(1_048_576)).to eq('1.0 MB')
    end
  end
end
```

**Success Criteria:**
- [ ] All tests pass
- [ ] 4 files updated to use new module
- [ ] ~40 lines of duplication eliminated

---

### Task 1.2: Define DAM Exception Hierarchy
**Effort:** 2 hours | **Priority:** Medium | **Risk:** Low

**Goal:** Create consistent error handling pattern for DAM module.

**Steps:**
1. Create `lib/appydave/tools/dam/errors.rb`
2. Define exception classes
3. Update error raises in:
   - `project_resolver.rb:19` (string raise → ProjectNotFoundError)
   - `config.rb:40` (string raise → BrandNotFoundError)
   - Other locations using string raises
4. Write specs
5. Update CLAUDE.md with error handling guidelines

**Implementation:**
```ruby
# lib/appydave/tools/dam/errors.rb
module Appydave
  module Tools
    module Dam
      # Base error for all DAM operations
      class DamError < StandardError; end

      # Raised when brand directory not found
      class BrandNotFoundError < DamError
        def initialize(brand, available_brands = [])
          message = "Brand directory not found: #{brand}"
          if available_brands.any?
            message += "\n\nAvailable brands:\n#{available_brands.join("\n")}"
          end
          super(message)
        end
      end

      # Raised when project not found in brand
      class ProjectNotFoundError < DamError; end

      # Raised when configuration invalid or missing
      class ConfigurationError < DamError; end

      # Raised when S3 operation fails
      class S3OperationError < DamError; end

      # Raised when git operation fails
      class GitOperationError < DamError; end
    end
  end
end
```

**Migration Example:**
```ruby
# BEFORE (project_resolver.rb:19)
raise '❌ Project name is required' if project_hint.nil? || project_hint.empty?

# AFTER
raise ProjectNotFoundError, 'Project name is required' if project_hint.nil? || project_hint.empty?
```

**Success Criteria:**
- [ ] All string raises replaced with typed exceptions
- [ ] CLI error handling in bin/dam still works
- [ ] Error messages remain user-friendly

---

## Phase 2: Architectural Improvements (Priority 2)

### Task 2.1: Extract GitHelper Module
**Effort:** 3 hours | **Priority:** High | **Risk:** Medium

**Goal:** Eliminate 90 lines of git command duplication.

**Steps:**
1. Create `lib/appydave/tools/dam/git_helper.rb`
2. Extract git methods from:
   - `status.rb:243-275` (4 methods)
   - `repo_status.rb:109-144` (6 methods)
   - `repo_push.rb:107-119` (3 methods)
3. Make module methods accept `repo_path` parameter
4. Include module in classes
5. Update all callers
6. Write comprehensive specs
7. Run full test suite

**Implementation:**
```ruby
# lib/appydave/tools/dam/git_helper.rb
module Appydave
  module Tools
    module Dam
      # Git operations helper for DAM classes
      # Provides reusable git command wrappers
      module GitHelper
        module_function

        # Get current branch name
        # @param repo_path [String] Path to git repository
        # @return [String] Branch name or 'unknown' if error
        def current_branch(repo_path)
          `git -C "#{repo_path}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
        rescue StandardError
          'unknown'
        end

        # Get git remote URL
        # @param repo_path [String] Path to git repository
        # @return [String, nil] Remote URL or nil if not configured
        def remote_url(repo_path)
          result = `git -C "#{repo_path}" remote get-url origin 2>/dev/null`.strip
          result.empty? ? nil : result
        rescue StandardError
          nil
        end

        # Count commits ahead of remote
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of commits ahead
        def commits_ahead(repo_path)
          `git -C "#{repo_path}" rev-list --count @{upstream}..HEAD 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        # Count commits behind remote
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of commits behind
        def commits_behind(repo_path)
          `git -C "#{repo_path}" rev-list --count HEAD..@{upstream} 2>/dev/null`.strip.to_i
        rescue StandardError
          0
        end

        # Count modified files
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of modified files
        def modified_files_count(repo_path)
          `git -C "#{repo_path}" status --porcelain 2>/dev/null | grep -E "^.M|^M" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        # Count untracked files
        # @param repo_path [String] Path to git repository
        # @return [Integer] Number of untracked files
        def untracked_files_count(repo_path)
          `git -C "#{repo_path}" status --porcelain 2>/dev/null | grep -E "^\\?\\?" | wc -l`.strip.to_i
        rescue StandardError
          0
        end

        # Check if repository has uncommitted changes
        # @param repo_path [String] Path to git repository
        # @return [Boolean] true if changes exist
        def uncommitted_changes?(repo_path)
          system("git -C \"#{repo_path}\" diff-index --quiet HEAD -- 2>/dev/null")
          !$CHILD_STATUS.success?
        rescue StandardError
          false
        end

        # Fetch from remote
        # @param repo_path [String] Path to git repository
        # @return [Boolean] true if successful
        def fetch(repo_path)
          system("git -C \"#{repo_path}\" fetch 2>/dev/null")
          $CHILD_STATUS.success?
        rescue StandardError
          false
        end
      end
    end
  end
end
```

**Migration Example:**
```ruby
# BEFORE (status.rb)
class Status
  def current_branch
    `git -C "#{brand_path}" rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
  end
end

# AFTER (status.rb)
class Status
  include GitHelper

  def current_branch
    GitHelper.current_branch(brand_path)
  end
end
```

**Testing Strategy:**
```ruby
RSpec.describe Appydave::Tools::Dam::GitHelper do
  let(:temp_repo) { Dir.mktmpdir }

  before do
    # Initialize git repo for testing
    system("git init #{temp_repo} 2>/dev/null")
  end

  after { FileUtils.rm_rf(temp_repo) }

  describe '.current_branch' do
    it 'returns branch name'
    it 'handles non-git directory gracefully'
  end

  # ... similar for other methods
end
```

**Success Criteria:**
- [ ] All 3 classes using GitHelper
- [ ] All tests pass
- [ ] ~90 lines of duplication eliminated
- [ ] Git commands centralized

---

### Task 2.2: Create BrandResolver Class
**Effort:** 6-8 hours | **Priority:** High | **Risk:** High

**Goal:** Centralize brand name transformation logic to prevent ongoing bugs.

**Steps:**
1. Create `lib/appydave/tools/dam/brand_resolver.rb`
2. Move logic from:
   - `config.rb:91-116` (expand_brand)
   - `project_resolver.rb:118-121` (strip v- prefix)
3. Define clear API:
   - `expand(shortcut)` - appydave → v-appydave
   - `normalize(brand)` - v-appydave → appydave
   - `validate(brand)` - raises if invalid
   - `to_config_key(brand)` - always key form (no v-)
   - `to_display(brand)` - always display form (v-)
4. Update all callers (10+ files)
5. Write comprehensive specs
6. Document API in class comments

**Implementation:**
```ruby
# lib/appydave/tools/dam/brand_resolver.rb
module Appydave
  module Tools
    module Dam
      # Centralized brand name resolution and transformation
      #
      # Handles conversion between:
      # - Shortcuts: 'appydave', 'ad', 'joy', 'ss'
      # - Config keys: 'appydave', 'beauty-and-joy', 'supportsignal'
      # - Display names: 'v-appydave', 'v-beauty-and-joy', 'v-supportsignal'
      #
      # @example
      #   BrandResolver.expand('ad')          # => 'v-appydave'
      #   BrandResolver.normalize('v-voz')    # => 'voz'
      #   BrandResolver.to_config_key('ad')   # => 'appydave'
      #   BrandResolver.to_display('voz')     # => 'v-voz'
      class BrandResolver
        class << self
          # Expand shortcut or key to full display name
          # @param shortcut [String] Brand shortcut or key
          # @return [String] Full brand name with v- prefix
          def expand(shortcut)
            return shortcut if shortcut.to_s.start_with?('v-')

            key = to_config_key(shortcut)
            "v-#{key}"
          end

          # Normalize brand name to config key (strip v- prefix)
          # @param brand [String] Brand name (with or without v-)
          # @return [String] Config key without v- prefix
          def normalize(brand)
            brand.to_s.sub(/^v-/, '')
          end

          # Convert to config key (handles shortcuts)
          # @param input [String] Shortcut, key, or display name
          # @return [String] Config key
          def to_config_key(input)
            # Strip v- prefix first
            normalized = normalize(input)

            # Look up from brands.json
            Appydave::Tools::Configuration::Config.configure
            brands_config = Appydave::Tools::Configuration::Config.brands

            # Check if matches brand key
            brand = brands_config.brands.find { |b| b.key.downcase == normalized.downcase }
            return brand.key if brand

            # Check if matches shortcut
            brand = brands_config.brands.find { |b| b.shortcut.downcase == normalized.downcase }
            return brand.key if brand

            # Fall back to hardcoded shortcuts (backward compatibility)
            case normalized.downcase
            when 'joy' then 'beauty-and-joy'
            when 'ss' then 'supportsignal'
            else
              normalized
            end
          end

          # Convert to display name (always v- prefix)
          # @param input [String] Shortcut, key, or display name
          # @return [String] Display name with v- prefix
          def to_display(input)
            expand(input)
          end

          # Validate brand exists
          # @param brand [String] Brand to validate
          # @raise [BrandNotFoundError] if brand invalid
          # @return [String] Config key if valid
          def validate(brand)
            key = to_config_key(brand)
            brand_path = Config.brand_path(key)

            unless Dir.exist?(brand_path)
              available = Config.available_brands_display
              raise BrandNotFoundError.new(brand, available)
            end

            key
          rescue StandardError => e
            raise BrandNotFoundError, e.message
          end
        end
      end
    end
  end
end
```

**Migration Plan:**
```ruby
# PHASE 1: Create BrandResolver with tests
# PHASE 2: Update Config class to use BrandResolver
# PHASE 3: Update ProjectResolver to use BrandResolver
# PHASE 4: Update CLI (bin/dam) to use BrandResolver
# PHASE 5: Update remaining callers
# PHASE 6: Remove old methods from Config (mark deprecated first)
```

**Testing Strategy:**
```ruby
RSpec.describe Appydave::Tools::Dam::BrandResolver do
  include_context 'with vat filesystem and brands', brands: %w[appydave voz]

  describe '.expand' do
    it 'expands shortcut to display name' do
      expect(described_class.expand('appydave')).to eq('v-appydave')
      expect(described_class.expand('ad')).to eq('v-appydave')
    end

    it 'leaves display names unchanged' do
      expect(described_class.expand('v-appydave')).to eq('v-appydave')
    end
  end

  describe '.normalize' do
    it 'strips v- prefix' do
      expect(described_class.normalize('v-appydave')).to eq('appydave')
    end

    it 'leaves normalized names unchanged' do
      expect(described_class.normalize('appydave')).to eq('appydave')
    end
  end

  describe '.to_config_key' do
    it 'converts shortcuts to config keys' do
      expect(described_class.to_config_key('ad')).to eq('appydave')
      expect(described_class.to_config_key('joy')).to eq('beauty-and-joy')
      expect(described_class.to_config_key('ss')).to eq('supportsignal')
    end

    it 'handles display names' do
      expect(described_class.to_config_key('v-appydave')).to eq('appydave')
    end
  end

  describe '.validate' do
    it 'validates existing brand' do
      expect { described_class.validate('appydave') }.not_to raise_error
    end

    it 'raises for invalid brand' do
      expect { described_class.validate('invalid') }.to raise_error(BrandNotFoundError)
    end
  end
end
```

**Success Criteria:**
- [ ] All brand transformation logic centralized
- [ ] Clear API with documented responsibilities
- [ ] All callers updated (10+ files)
- [ ] All tests pass
- [ ] No regression in brand resolution

**Rollback Plan:**
If issues arise, keep old methods and mark BrandResolver as experimental. Gradually migrate one file at a time.

---

## Phase 3: Test Improvements (Priority 3)

### Task 3.1: Refactor ProjectListing Specs
**Effort:** 4 hours | **Priority:** Medium | **Risk:** Low

**Goal:** Standardize test patterns using shared filesystem contexts.

**Steps:**
1. Analyze `spec/appydave/tools/dam/project_listing_spec.rb`
2. Identify all Config mocks (20 lines)
3. Replace with `include_context 'with vat filesystem and brands'`
4. Update test expectations
5. Verify all tests pass
6. Document pattern in spec/support/README.md

**Before:**
```ruby
# Heavy mocking
allow(Appydave::Tools::Dam::Config).to receive_messages(projects_root: temp_root)
allow(Appydave::Tools::Dam::Config).to receive(:brand_path).with('appydave').and_return(brand1_path)
# ... 18 more allow() statements
```

**After:**
```ruby
include_context 'with vat filesystem and brands', brands: %w[appydave voz]

before do
  # Create real test projects
  FileUtils.mkdir_p(File.join(appydave_path, 'b65-test'))
  FileUtils.mkdir_p(File.join(voz_path, 'boy-baker'))
end
```

**Success Criteria:**
- [ ] Mock count reduced from 20 to <5
- [ ] All tests pass
- [ ] Test setup clearer and more maintainable

---

## Phase 4: Documentation & Cleanup (Priority 4)

### Task 4.1: Document Configuration Loading
**Effort:** 1 hour | **Priority:** Low | **Risk:** None

**Goal:** Add inline documentation explaining Config.configure memoization.

**Steps:**
1. Add module-level comment to `lib/appydave/tools/configuration/config.rb`
2. Document `configure` method behavior
3. Add examples to CLAUDE.md

**Implementation:**
```ruby
# lib/appydave/tools/configuration/config.rb
module Appydave
  module Tools
    module Configuration
      # Central configuration management for appydave-tools
      #
      # Thread-safe singleton pattern with memoization.
      # Calling `Config.configure` multiple times is safe and idempotent.
      #
      # @example Basic usage
      #   Config.configure  # Load config (idempotent)
      #   Config.settings.video_projects_root
      #   Config.brands.get_brand('appydave')
      #
      # @example DAM module usage
      #   # Config.configure called once at module load
      #   # All subsequent calls are no-ops (memoized)
      class Config
        class << self
          # Load configuration from JSON files
          # Safe to call multiple times (idempotent/memoized)
          # @return [void]
          def configure
            # Implementation uses @@configured flag for memoization
            # ...
          end
        end
      end
    end
  end
end
```

---

## Implementation Timeline

### Week 1 (Days 1-2): Quick Wins
- **Day 1 Morning:** Task 1.1 - Extract FileUtils
- **Day 1 Afternoon:** Task 1.2 - Define exception hierarchy
- **Day 2:** Review and test Phase 1 changes

### Week 2 (Days 3-5): Architectural Improvements
- **Day 3-4:** Task 2.1 - Extract GitHelper (test thoroughly)
- **Day 5:** Task 2.2 - Start BrandResolver

### Week 3 (Days 6-8): BrandResolver & Tests
- **Day 6-7:** Task 2.2 - Complete BrandResolver migration
- **Day 8:** Task 3.1 - Refactor specs

### Week 4 (Day 9): Documentation
- **Day 9:** Task 4.1 - Documentation and final review

---

## Risk Management

### High-Risk Tasks
1. **BrandResolver refactor** - Touches many files, complex logic
   - Mitigation: Implement gradually, one file at a time
   - Keep old methods during transition
   - Extensive testing at each step

2. **GitHelper extraction** - Changes behavior of 3 classes
   - Mitigation: Write tests first
   - Test each class individually after migration
   - Run full test suite after each change

### Medium-Risk Tasks
1. **Test refactoring** - Could break existing tests
   - Mitigation: One test file at a time
   - Keep git commits small for easy rollback

### Low-Risk Tasks
1. **FileUtils extraction** - Pure utility code
2. **Exception hierarchy** - Additive changes
3. **Documentation** - No code changes

---

## Success Metrics

### Code Quality Metrics (Before → After)
- **Duplicated lines:** 150 → <30 (80% reduction)
- **Mock density in tests:** 8% → <3%
- **Files with brand logic:** 5 → 1 (BrandResolver)
- **Test coverage:** Maintain >90%

### Behavioral Metrics
- [ ] All existing tests pass
- [ ] No regression in CLI behavior
- [ ] No breaking changes to public API
- [ ] Gem version: Minor bump (backward compatible)

---

## Commit Strategy

Use semantic commit messages for automated versioning:

```bash
# Phase 1
kfeat "extract FileUtils module for directory size calculations"
kfeat "add DAM exception hierarchy for consistent error handling"

# Phase 2
kfeat "extract GitHelper module to eliminate 90 lines of duplication"
kfeat "create BrandResolver to centralize brand transformation logic"

# Phase 3
kfix "refactor project_listing_spec to use shared filesystem contexts"

# Phase 4
kdocs "add configuration loading documentation and memoization notes"
```

---

## Getting Help

If you encounter issues:
1. **Check report:** [report-2025-01-21.md](./report-2025-01-21.md)
2. **Run tests:** `bundle exec rspec`
3. **Verify changes:** `git diff`
4. **Rollback:** `git reset --hard HEAD`

**Need clarification?** Ask before implementing high-risk changes.

---

**Plan Created:** 2025-01-21
**Estimated Total Effort:** 18-24 hours across 2 weeks
**Risk Level:** Medium (manageable with phased approach)
