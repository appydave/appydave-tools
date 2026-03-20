# AGENTS.md — AppyDave Tools / s3-operations-split campaign

> Self-contained operational knowledge. You receive only this file + your work unit prompt.
> Inherited from: batch-a-features (2026-03-20)

---

## Project Overview

**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**Baseline:** 870 examples, 0 failures, 86.47% line coverage, v0.77.1
**Commits:** `kfeat "message"` for new features (minor bump), `kfix "message"` for fixes (patch bump). Never `git commit` directly.
**Wave size:** 1 — all work units are SEQUENTIAL. Do not attempt parallel execution. Each WU modifies s3_operations.rb AND creates a new file; concurrent edits would conflict.

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
git checkout -- path/to/unintended/file    # discard specific file
```

Then call kfix/kfeat once the tree is clean.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                    # Full suite (870 examples baseline)
bundle exec rspec spec/path/to/file_spec.rb        # Single file
bundle exec rubocop --format clang                 # Lint (must be 0 offenses)

kfeat "add feature description"    # new feature — minor version bump
kfix "fix description"             # fix/improvement — patch version bump
```

---

## Architecture Overview — What We're Splitting

`lib/appydave/tools/dam/s3_operations.rb` is 1,021 lines with:
- Mixed I/O (`puts` everywhere) and computation (MD5, path building)
- All upload, download, status, archive logic in one class
- Used by: `bin/dam` (8 call sites), `project_listing.rb` (calculate_sync_status + sync_timestamps), `status.rb` (indirectly via project_listing)

### Target Architecture

```
S3Base (shared infrastructure + shared helpers)
  ├── S3Uploader < S3Base        (upload only)
  ├── S3Downloader < S3Base      (download only)
  ├── S3StatusChecker < S3Base   (status, calculate_sync_status, sync_timestamps)
  ├── S3Archiver < S3Base        (archive, cleanup, cleanup_local)
  └── S3Operations < S3Base      (thin facade — delegates to above 4)
```

**S3Operations inherits from S3Base** so that existing specs calling `.send(:build_s3_key, ...)` etc. continue to work. Public methods delegate to focused sub-classes.

---

## Current S3Operations Method Map

Use this as your reference when deciding where each method belongs.

### Constructor + Client (→ S3Base)
- L32  `initialize(brand, project_id, brand_info: nil, brand_path: nil, s3_client: nil)`
- L43  `s3_client` (public, lazy-loaded)
- L49  `load_brand_info(brand)` (private)
- L55  `project_directory_path` (private)
- L65  `determine_aws_profile(brand_info)` (private)
- L85  `create_s3_client(brand_info)` (private)
- L102 `configure_ssl_options` (private)

### Shared Helpers (→ S3Base)
- L590 `build_s3_key(relative_path)` (public used by specs via send)
- L595 `extract_relative_path(s3_key)` (public used by specs via send)
- L600 `file_md5(file_path)` (private)
- L619 `s3_file_md5(s3_path)` (private)
- L631 `multipart_etag?(etag)` (private)
- L640 `compare_files(local_file:, s3_etag:, s3_size:)` (private)
- L660 `s3_file_size(s3_path)` (private)
- L721 `format_duration(seconds)` (private)
- L735 `format_time_ago(seconds)` (private)
- L850 `list_s3_files` (private — used by upload, download, status, calculate_sync_status, sync_timestamps)
- L873 `get_s3_file_info(s3_key)` (private — used by upload)
- L902 `file_size_human(bytes)` (private)
- L973 `excluded_path?(relative_path)` (private — used by upload + copy_with_exclusions)

### Upload Operations (→ S3Uploader)
- L111 `upload(dry_run: false)` (public)
- L671 `upload_file(local_file, s3_path, dry_run: false)` (private)
- L757 `detect_content_type(filename)` (private)

### Download Operations (→ S3Downloader)
- L188 `download(dry_run: false)` (public)
- L790 `download_file(s3_key, local_file, dry_run: false)` (private)

### Status Operations (→ S3StatusChecker)
- L260 `status` (public)
- L495 `calculate_sync_status` (public — called by project_listing.rb)
- L562 `sync_timestamps` (public — called by project_listing.rb)
- L890 `list_local_files(staging_dir)` (private)

### Archive Operations (→ S3Archiver)
- L354 `cleanup(force: false, dry_run: false)` (public)
- L393 `cleanup_local(force: false, dry_run: false)` (public)
- L448 `archive(force: false, dry_run: false)` (public)
- L818 `delete_s3_file(s3_key, dry_run: false)` (private)
- L836 `delete_local_file(file_path, dry_run: false)` (private)
- L915 `copy_to_ssd(source_dir, dest_dir, dry_run: false)` (private)
- L949 `copy_with_exclusions(source_dir, dest_dir)` (private)
- L990 `delete_local_project(project_dir, dry_run: false)` (private)
- L1015 `calculate_directory_size(dir_path)` (private)

---

## Directory Structure

```
lib/appydave/tools/
  dam/
    s3_operations.rb      EXISTING — shrinks to thin facade (~70 lines after all WUs)
    s3_base.rb            NEW (WU1) — shared infrastructure + shared helpers
    s3_uploader.rb        NEW (WU2) — upload only
    s3_downloader.rb      NEW (WU3) — download only
    s3_status_checker.rb  NEW (WU4) — status, calculate_sync_status, sync_timestamps
    s3_archiver.rb        NEW (WU5) — archive, cleanup, cleanup_local
  tools.rb                MODIFY (WU5) — add requires for new files
spec/appydave/tools/dam/
  s3_operations_spec.rb   EXISTING — do NOT touch until all 5 WUs complete
  s3_base_spec.rb         (optional, WU1) — only if time allows
```

---

## WU1: Extract S3Base

**File to create:** `lib/appydave/tools/dam/s3_base.rb`
**File to modify:** `lib/appydave/tools/dam/s3_operations.rb`

### What to build

Create S3Base containing everything from the "Constructor + Client" and "Shared Helpers" sections above.

```ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'digest'
require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # Shared infrastructure and helpers for S3 operations.
      # All S3 operation classes inherit from this base.
      class S3Base
        attr_reader :brand_info, :brand, :project_id, :brand_path

        EXCLUDE_PATTERNS = %w[
          **/node_modules/**
          **/.git/**
          **/.next/**
          **/dist/**
          **/build/**
          **/out/**
          **/.cache/**
          **/coverage/**
          **/.turbo/**
          **/.vercel/**
          **/tmp/**
          **/.DS_Store
          **/*:Zone.Identifier
        ].freeze

        def initialize(brand, project_id, brand_info: nil, brand_path: nil, s3_client: nil)
          # ... (copy exactly from s3_operations.rb)
        end

        def s3_client
          # ... (copy exactly)
        end

        private

        # All private infrastructure methods ...
        # All shared helper methods ...
      end
    end
  end
end
```

### Modify S3Operations after creating S3Base

Change the class declaration to inherit from S3Base, and REMOVE all methods that are now in S3Base:

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Facade for S3 operations — delegates to focused sub-classes.
      # Inherits shared helpers from S3Base for backward-compatible spec access.
      class S3Operations < S3Base
        # upload, download, status, cleanup, cleanup_local, archive
        # (these remain here for now — moved out in WU2-WU5)
      end
    end
  end
end
```

**Important**: S3Operations must keep `require 'fileutils'` etc. removed since S3Base now has them. But s3_base.rb has the requires, and since s3_operations.rb will require s3_base via the autoload chain, that's fine.

Actually: DO NOT add `require` calls inside individual lib files — the load order is managed by `lib/appydave/tools.rb`. Just make the class inherit.

### Modify lib/appydave/tools.rb (WU1)

Add `require 'appydave/tools/dam/s3_base'` on a NEW line immediately BEFORE line 70 (`require 'appydave/tools/dam/s3_operations'`). Without this, S3Operations < S3Base will fail at load time.

```ruby
# Line 69: require 'appydave/tools/dam/config_loader'
require 'appydave/tools/dam/s3_base'         # ADD THIS
require 'appydave/tools/dam/s3_operations'   # EXISTING line 70
```

### Done when WU1 is complete
- `lib/appydave/tools/dam/s3_base.rb` created with all infrastructure + helpers
- `lib/appydave/tools/dam/s3_operations.rb` still has upload/download/status/cleanup/archive methods intact, but class is now `S3Operations < S3Base` and constructor + shared helpers are removed
- `lib/appydave/tools/tools.rb` has new s3_base require before s3_operations
- `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "extract S3Base with shared infrastructure and helpers from S3Operations"`

---

## WU2: Extract S3Uploader

**Prerequisite:** WU1 complete.
**File to create:** `lib/appydave/tools/dam/s3_uploader.rb`
**File to modify:** `lib/appydave/tools/dam/s3_operations.rb`

### What to build

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 upload operations.
      class S3Uploader < S3Base
        def upload(dry_run: false)
          # MOVE exactly from s3_operations.rb L111-L185
        end

        private

        def upload_file(local_file, s3_path, dry_run: false)
          # MOVE exactly from s3_operations.rb L671-L719
        end

        def detect_content_type(filename)
          # MOVE exactly from s3_operations.rb L757-L787
        end
      end
    end
  end
end
```

### Modify S3Operations

Replace the `upload` method body with delegation. Remove `upload_file` and `detect_content_type` from S3Operations:

```ruby
def upload(dry_run: false)
  S3Uploader.new(brand, project_id, brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override).upload(dry_run: dry_run)
end
```

### Modify lib/appydave/tools.rb (WU2)

Add s3_uploader require immediately before s3_operations:
```ruby
require 'appydave/tools/dam/s3_base'
require 'appydave/tools/dam/s3_uploader'    # ADD THIS
require 'appydave/tools/dam/s3_operations'
```

### Done when WU2 is complete
- `s3_uploader.rb` created
- `s3_operations.rb` upload delegates to S3Uploader; upload_file + detect_content_type removed from s3_operations.rb
- `lib/appydave/tools.rb` has s3_uploader require
- `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "extract S3Uploader from S3Operations; upload delegates to focused class"`

---

## WU3: Extract S3Downloader

**Prerequisite:** WU2 complete.
**File to create:** `lib/appydave/tools/dam/s3_downloader.rb`
**File to modify:** `lib/appydave/tools/dam/s3_operations.rb`

### What to build

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 download operations.
      class S3Downloader < S3Base
        def download(dry_run: false)
          # MOVE exactly from s3_operations.rb L188-L257
        end

        private

        def download_file(s3_key, local_file, dry_run: false)
          # MOVE exactly from s3_operations.rb L790-L815
        end
      end
    end
  end
end
```

### Modify S3Operations

```ruby
def download(dry_run: false)
  S3Downloader.new(brand, project_id, brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override).download(dry_run: dry_run)
end
```

Remove `download_file` from S3Operations.

### Modify lib/appydave/tools.rb (WU3)

Add s3_downloader require:
```ruby
require 'appydave/tools/dam/s3_base'
require 'appydave/tools/dam/s3_uploader'
require 'appydave/tools/dam/s3_downloader'  # ADD THIS
require 'appydave/tools/dam/s3_operations'
```

### Done when WU3 is complete
- `s3_downloader.rb` created, delegation in place, `download_file` removed from s3_operations.rb
- `lib/appydave/tools.rb` has s3_downloader require
- `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "extract S3Downloader from S3Operations; download delegates to focused class"`

---

## WU4: Extract S3StatusChecker

**Prerequisite:** WU3 complete.
**File to create:** `lib/appydave/tools/dam/s3_status_checker.rb`
**File to modify:** `lib/appydave/tools/dam/s3_operations.rb`

### What to build

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles S3 status checking, sync status calculation, and timestamp queries.
      # Used directly by project_listing.rb for dam list S3 column.
      class S3StatusChecker < S3Base
        def status
          # MOVE exactly from s3_operations.rb L260-L351
        end

        def calculate_sync_status
          # MOVE exactly from s3_operations.rb L495-L558
        end

        def sync_timestamps
          # MOVE exactly from s3_operations.rb L562-L587
        end

        private

        def list_local_files(staging_dir)
          # MOVE exactly from s3_operations.rb L890-L900
        end
      end
    end
  end
end
```

### Modify S3Operations

```ruby
def status
  S3StatusChecker.new(brand, project_id, brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override).status
end

def calculate_sync_status
  S3StatusChecker.new(brand, project_id, brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override).calculate_sync_status
end

def sync_timestamps
  S3StatusChecker.new(brand, project_id, brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override).sync_timestamps
end
```

Remove `status`, `calculate_sync_status`, `sync_timestamps`, `list_local_files` from S3Operations.

**Note:** `project_listing.rb` calls `S3Operations.new(brand_arg, project, brand_info: brand_info).calculate_sync_status` — this still works because S3Operations delegates. No change needed in project_listing.rb.

### Modify lib/appydave/tools.rb (WU4)

Add s3_status_checker require:
```ruby
require 'appydave/tools/dam/s3_base'
require 'appydave/tools/dam/s3_uploader'
require 'appydave/tools/dam/s3_downloader'
require 'appydave/tools/dam/s3_status_checker'  # ADD THIS
require 'appydave/tools/dam/s3_operations'
```

### Done when WU4 is complete
- `s3_status_checker.rb` created, delegation in place, 4 methods removed from s3_operations.rb
- `lib/appydave/tools.rb` has s3_status_checker require
- `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "extract S3StatusChecker from S3Operations; status methods delegate to focused class"`

---

## WU5: Extract S3Archiver + Final Cleanup

**Prerequisite:** WU4 complete.
**File to create:** `lib/appydave/tools/dam/s3_archiver.rb`
**Files to modify:** `lib/appydave/tools/dam/s3_operations.rb`, `lib/appydave/tools/tools.rb`

### What to build

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Handles archive to SSD and S3/local cleanup operations.
      class S3Archiver < S3Base
        def cleanup(force: false, dry_run: false)
          # MOVE exactly from s3_operations.rb L354-L390
        end

        def cleanup_local(force: false, dry_run: false)
          # MOVE exactly from s3_operations.rb L393-L445
        end

        def archive(force: false, dry_run: false)
          # MOVE exactly from s3_operations.rb L448-L491
        end

        private

        def delete_s3_file(s3_key, dry_run: false)
          # MOVE exactly from s3_operations.rb L818-L833
        end

        def delete_local_file(file_path, dry_run: false)
          # MOVE exactly from s3_operations.rb L836-L847
        end

        def copy_to_ssd(source_dir, dest_dir, dry_run: false)
          # MOVE exactly from s3_operations.rb L915-L947
        end

        def copy_with_exclusions(source_dir, dest_dir)
          # MOVE exactly from s3_operations.rb L949-L971
          # Note: calls excluded_path? which is in S3Base — still accessible via inheritance
        end

        def delete_local_project(project_dir, dry_run: false)
          # MOVE exactly from s3_operations.rb L990-L1013
        end

        def calculate_directory_size(dir_path)
          # MOVE exactly from s3_operations.rb L1015-L1021
        end
      end
    end
  end
end
```

### Modify S3Operations (final form ~70 lines)

After removing all methods, S3Operations should look like:

```ruby
# frozen_string_literal: true

module Appydave
  module Tools
    module Dam
      # Thin facade for S3 operations.
      # Inherits shared helpers from S3Base for backward-compatible spec access via send().
      # Delegates all operations to focused sub-classes.
      class S3Operations < S3Base
        def upload(dry_run: false)
          S3Uploader.new(brand, project_id, **delegated_opts).upload(dry_run: dry_run)
        end

        def download(dry_run: false)
          S3Downloader.new(brand, project_id, **delegated_opts).download(dry_run: dry_run)
        end

        def status
          S3StatusChecker.new(brand, project_id, **delegated_opts).status
        end

        def calculate_sync_status
          S3StatusChecker.new(brand, project_id, **delegated_opts).calculate_sync_status
        end

        def sync_timestamps
          S3StatusChecker.new(brand, project_id, **delegated_opts).sync_timestamps
        end

        def cleanup(force: false, dry_run: false)
          S3Archiver.new(brand, project_id, **delegated_opts).cleanup(force: force, dry_run: dry_run)
        end

        def cleanup_local(force: false, dry_run: false)
          S3Archiver.new(brand, project_id, **delegated_opts).cleanup_local(force: force, dry_run: dry_run)
        end

        def archive(force: false, dry_run: false)
          S3Archiver.new(brand, project_id, **delegated_opts).archive(force: force, dry_run: dry_run)
        end

        private

        def delegated_opts
          { brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override }
        end
      end
    end
  end
end
```

### Modify lib/appydave/tools.rb (WU5)

Add s3_archiver require (WU1-4 already added the others):
```ruby
require 'appydave/tools/dam/s3_base'
require 'appydave/tools/dam/s3_uploader'
require 'appydave/tools/dam/s3_downloader'
require 'appydave/tools/dam/s3_status_checker'
require 'appydave/tools/dam/s3_archiver'    # ADD THIS
require 'appydave/tools/dam/s3_operations'  # existing
```

### Done when WU5 is complete
- `s3_archiver.rb` created
- `s3_operations.rb` is now ~70 lines (thin facade)
- `lib/appydave/tools.rb` has 5 new require lines before `s3_operations`
- `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- `bundle exec rubocop --format clang` → 0 offenses
- Commit: `kfix "extract S3Archiver; S3Operations is now a thin delegation facade"`

---

## Success Criteria (Every Work Unit)

- [ ] `RUBYOPT="-W0" bundle exec rspec` → 870 examples, 0 failures
- [ ] `bundle exec rubocop --format clang` → 0 offenses
- [ ] Coverage ≥ 86.47%
- [ ] Working tree clean before calling kfix (git status check)

---

## Reference Patterns

### S3Base inheritance pattern (how sub-classes access shared state)

Methods in S3Uploader, S3Downloader, etc. can call any method defined in S3Base via `self`:

```ruby
class S3Uploader < S3Base
  def upload(dry_run: false)
    staging_dir = File.join(project_directory_path, 's3-staging')  # from S3Base
    files = list_s3_files  # from S3Base
    s3_key = build_s3_key(relative_path)  # from S3Base
    s3_client.put_object(...)  # from S3Base
    file_size_human(bytes)  # from S3Base
  end
end
```

### Delegation opts helper (in S3Operations)

```ruby
private

def delegated_opts
  { brand_info: brand_info, brand_path: brand_path, s3_client: @s3_client_override }
end
```

Use `**delegated_opts` in every delegation call to avoid repetition.

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

- ❌ Don't add `require` statements inside individual `lib/` files — only in `lib/appydave/tools.rb`
- ❌ Don't change any method signatures — exact copies only (no refactoring during extraction)
- ❌ Don't remove `rubocop:disable` comments unless you're fixing the actual offense
- ❌ `exit 1` in library code — use typed exceptions (already done in prior campaigns)
- ❌ `instance_double('StringForm')` — fails CI on Ubuntu
- ❌ Multiple `before` blocks in same context — merge them (RSpec/ScatteredSetup)
- ❌ `$?` for subprocess status — use `$CHILD_STATUS`
- ❌ Don't touch spec files during WU1-WU5 — all existing specs test through S3Operations facade
- ❌ Don't try to parallelize — wave size is 1, these WUs MUST be sequential

---

## Learnings

### From batch-a-features (2026-03-20)

- **kfix runs `git add .` internally.** Clean the working tree before calling kfix. Check `git status` first.
- **`instance_double` string form fails CI on Ubuntu.** Always use full constant.
- **`warn` not `$stderr.puts`** — rubocop Style/StderrPuts cop
- **`not_to raise_error` is a weak assertion.** Prefer field-value assertions.

### From env-dead-code-cleanup (2026-03-20)

- **`exit 1` in library code → use typed exceptions.** VatCLI rescue blocks catch StandardError.
- **Config.brands needs separate mock** from shared filesystem context.

### From library-boundary-cleanup (2026-03-20)

- **S3ScanCommand#scan_all rescues per-brand** — per-brand failures are isolated.
- **`not_to raise_error` is a weak assertion.** Prefer field-value or method-spy assertions.

### Key s3_operations.rb note: `rubocop:disable Metrics/BlockLength`

The `upload` and `download` methods have `# rubocop:disable Metrics/BlockLength` / `# rubocop:enable Metrics/BlockLength` comments around their `each` blocks. When you MOVE these methods to S3Uploader/S3Downloader, carry those comments along. Rubocop will still flag them without the disable.
