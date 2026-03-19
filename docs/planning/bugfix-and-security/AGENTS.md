# AGENTS.md — bugfix-and-security

> Inherited from docs/planning/AGENTS.md + fr2-gpt-context-help campaign learnings.
> Self-contained — you receive only this file + your work unit prompt.
> Last updated: 2026-03-19

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**This campaign:** 3 independent bug fixes — security (B017), data integrity (B016), dead code (B021).
**Commits:** Always use `kfeat`/`kfix` — never `git commit`.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

# Run all tests
RUBYOPT="-W0" bundle exec rspec

# Run specific spec files
bundle exec rspec spec/appydave/tools/dam/s3_operations_spec.rb
bundle exec rspec spec/appydave/tools/dam/sync_from_ssd_spec.rb
bundle exec rspec spec/appydave/tools/dam/manifest_generator_spec.rb
bundle exec rspec spec/appydave/tools/gpt_context/cli_spec.rb

# Lint
bundle exec rubocop --format clang

# Commit (never use git commit directly)
kfix "description of what you fixed"
```

**Baseline (2026-03-19):** 754 examples, 0 failures, 84.92% line coverage

---

## Directory Structure

```
lib/appydave/tools/dam/
  s3_operations.rb          B017 — configure_ssl_options method (~line 102)
  share_operations.rb       B017 — configure_ssl_options method (~line 89)
  s3_scanner.rb             B017 — inline ssl_verify_peer in Aws::S3::Client.new (~line 111)
  sync_from_ssd.rb          B016 — determine_range method (~line 185)
  manifest_generator.rb     B016 — determine_range method (~line 332) — canonical format
spec/appydave/tools/dam/
  s3_operations_spec.rb     Existing spec — do not break
  share_operations_spec.rb  Existing spec — do not break
  sync_from_ssd_spec.rb     B016 — update determine_range examples (~line 277)
  manifest_generator_spec.rb B016 — add determine_range examples (currently none)
bin/gpt_context.rb          B021 — guard at line 115
spec/appydave/tools/gpt_context/
  cli_spec.rb               B021 — add/update no-args spec
```

---

## Work Unit Details

### fix-b017-ssl

**Problem:** `ssl_verify_peer: false` is set unconditionally in 3 files, disabling MITM protection on all S3 operations including AWS credential transmission. The comment "safe for AWS S3" is incorrect — HTTPS encryption alone does not protect against a MITM attack without peer verification.

**Files to change:**

**1. `lib/appydave/tools/dam/s3_operations.rb` (~line 102):**
```ruby
# BEFORE:
def configure_ssl_options
  if ENV['AWS_SDK_RUBY_SKIP_SSL_VERIFICATION'] == 'true'
    puts '⚠️  WARNING: SSL verification is disabled (development mode)'
    return { ssl_verify_peer: false }
  end

  # Disable SSL peer verification to work around OpenSSL 3.4.x CRL checking issues
  # This is safe for AWS S3 connections as we're still using HTTPS (encrypted connection)
  {
    ssl_verify_peer: false
  }
end

# AFTER:
def configure_ssl_options
  return { ssl_verify_peer: false } if ENV['AWS_SDK_RUBY_SKIP_SSL_VERIFICATION'] == 'true'

  {}
end
```

**2. `lib/appydave/tools/dam/share_operations.rb` (~line 89):**
Same pattern as s3_operations.rb — same fix.

**3. `lib/appydave/tools/dam/s3_scanner.rb` (~line 111):**
```ruby
# BEFORE (inline in Aws::S3::Client.new):
Aws::S3::Client.new(
  credentials: credentials,
  region: brand_info.aws.region,
  http_wire_trace: false,
  ssl_verify_peer: false
)

# AFTER:
Aws::S3::Client.new(
  credentials: credentials,
  region: brand_info.aws.region,
  http_wire_trace: false
)
```

**Commit:** `kfix "remove unconditional ssl_verify_peer: false from S3 clients; keep env override"`

**Note on WARNING puts:** The original had `puts '⚠️  WARNING...'` in the env-guard branch. You may keep or remove it — if you keep it, ensure rubocop doesn't flag it (it shouldn't). If RuboCop complains about the `puts`, use `warn` instead.

---

### fix-b016-range

**Problem:** Two methods both named `determine_range` produce incompatible folder path strings:
- `ManifestGenerator#determine_range('b65')` → `"b50-b99"` (letter + 50-number range)
- `SyncFromSsd#determine_range('b65')` → `"60-69"` (no letter, 10-number range)

Both are used to construct `archived/[range]/[project_id]` paths. A project archived via SyncFromSsd lands in `archived/60-69/b65-project/`. ManifestGenerator then looks for it at `archived/b50-b99/b65-project/` — misses it (though glob fallback saves it in practice).

**ManifestGenerator format is canonical** — it handles any letter prefix (a*, b*, c*, ...) and uses 50-number ranges which are less granular and more stable.

**Fix: Update `SyncFromSsd#determine_range` to match ManifestGenerator's algorithm:**

```ruby
# lib/appydave/tools/dam/sync_from_ssd.rb

# BEFORE (~line 185):
def determine_range(project_id)
  # FliVideo pattern: b40, b41, ... b99
  if project_id =~ /^b(\d+)/
    tens = (Regexp.last_match(1).to_i / 10) * 10
    "#{tens}-#{tens + 9}"
  else
    '000-099'
  end
end

# AFTER (match ManifestGenerator exactly):
def determine_range(project_id)
  if project_id =~ /^([a-z])(\d+)/
    letter = Regexp.last_match(1)
    number = Regexp.last_match(2).to_i
    range_start = (number / 50) * 50
    range_end = range_start + 49
    format("#{letter}%02d-#{letter}%02d", range_start, range_end)
  else
    '000-099'
  end
end
```

**Update `spec/appydave/tools/dam/sync_from_ssd_spec.rb` — the existing determine_range examples (~line 277) must be updated to the new format:**

```ruby
describe '#determine_range' do
  it 'determines range for FliVideo pattern b40' do
    range = sync_from_ssd.send(:determine_range, 'b40-test-project')
    expect(range).to eq('b00-b49')
  end

  it 'determines range for FliVideo pattern b65' do
    range = sync_from_ssd.send(:determine_range, 'b65-guy-monroe')
    expect(range).to eq('b50-b99')
  end

  it 'determines range for FliVideo pattern b99' do
    range = sync_from_ssd.send(:determine_range, 'b99-final-project')
    expect(range).to eq('b50-b99')
  end

  it 'returns default range for non-FliVideo pattern' do
    range = sync_from_ssd.send(:determine_range, 'boy-baker')
    expect(range).to eq('000-099')
  end
end
```

**Add to `spec/appydave/tools/dam/manifest_generator_spec.rb` — currently zero specs for determine_range:**

Look at the existing manifest_generator_spec.rb for the describe block structure and shared context, then add:
```ruby
describe '#determine_range' do
  it 'determines range for b40' do
    range = manifest_generator.send(:determine_range, 'b40-test-project')
    expect(range).to eq('b00-b49')
  end

  it 'determines range for b65' do
    range = manifest_generator.send(:determine_range, 'b65-guy-monroe')
    expect(range).to eq('b50-b99')
  end

  it 'determines range for b99' do
    range = manifest_generator.send(:determine_range, 'b99-final-project')
    expect(range).to eq('b50-b99')
  end

  it 'returns default range for non-FliVideo pattern' do
    range = manifest_generator.send(:determine_range, 'boy-baker')
    expect(range).to eq('000-099')
  end
end
```

Read `manifest_generator_spec.rb` first to understand how the `manifest_generator` subject is set up before adding these examples.

**Commit:** `kfix "align SyncFromSsd#determine_range with ManifestGenerator format; add specs"`

---

### fix-b021-guard

**Problem:** `bin/gpt_context.rb` line 115:
```ruby
if options.include_patterns.empty? && options.exclude_patterns.empty? && options.format.nil?
```
`options.format` defaults to `'content'` in the Options class — it is never nil. The third AND condition is always false, making the whole guard dead when only format is set. In practice the guard fires on empty include+exclude (which is the normal "no args" path), but the dead condition is confusing and could mask future bugs.

**Fix:** Remove `&& options.format.nil?` from line 115:
```ruby
# BEFORE:
if options.include_patterns.empty? && options.exclude_patterns.empty? && options.format.nil?

# AFTER:
if options.include_patterns.empty? && options.exclude_patterns.empty?
```

**Add/update spec in `spec/appydave/tools/gpt_context/cli_spec.rb`:**

Add a context for no-args behavior:
```ruby
describe 'no arguments' do
  it 'exits with an error message when no patterns provided' do
    output = `ruby #{script} 2>&1`
    expect(output).to include('No options provided')
    expect($?.exitstatus).to_not eq(0)
  end
end
```

Note: The script currently calls `exit` (no code) on this path — check the actual exit status. If it exits 0, adjust the expectation or leave exit code assertion out and just check the message.

**Commit:** `kfix "remove dead format.nil? guard in gpt_context no-args check"`

---

## Success Criteria

Every work unit must satisfy ALL before marking `[x]`:

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 754+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 84.92%
- [ ] All new `.rb` file additions start with `# frozen_string_literal: true`
- [ ] Commit uses `kfix` (not `git commit`)

---

## Anti-Patterns to Avoid

- ❌ Do NOT remove the `ENV['AWS_SDK_RUBY_SKIP_SSL_VERIFICATION']` dev escape hatch — only remove the unconditional fallback below it
- ❌ Do NOT mock S3 clients when testing ssl options — check what the existing specs do and follow the pattern
- ❌ Do NOT change ManifestGenerator#determine_range — it is the canonical implementation, SyncFromSsd is the one to fix
- ❌ Do NOT use `puts` in lib/ code without checking if it violates rubocop (use `warn` for warnings)
- ❌ Do NOT inline brand transformations — always use BrandResolver
- ❌ Do NOT use `require 'spec_helper'` in new spec files — auto-required via .rspec

---

## Mock Patterns

### S3 Tests — Check Existing Specs First

Before writing any new S3-related test, read the existing spec file for the class you're touching. The existing patterns use WebMock or stub the S3 client at a higher level. Do NOT add new S3 network stubs — just verify the existing test suite still passes after your change.

### DAM Filesystem Tests — Shared Context

```ruby
include_context 'with vat filesystem and brands', brands: %w[appydave]
```

---

## Quality Gates

- **Tests:** 754+ examples, 0 failures
- **Lint:** 0 rubocop offenses
- **Coverage:** ≥ 84.92%
- **Commit:** `kfix` only

---

## Learnings (inherited)

### From Three-Lens Audit (2026-03-19)
- `format.nil?` in gpt_context is always false — do not re-introduce
- `ssl_verify_peer: false` is not safe for AWS — HTTPS alone doesn't prevent MITM without peer verification
- ManifestGenerator `determine_range` is the canonical format; SyncFromSsd must match it

### From fr2-gpt-context-help (2026-03-19)
- `opts.on_tail` vs `opts.on` matters for option ordering in OptionParser
- Subprocess specs (`ruby #{script} --flag`) are correct for CLI integration tests
- Pre-conditions from prior commits — always verify live before planning

### From DAM Enhancement Sprint (Jan 2025)
- BrandResolver is the critical path — all dam commands flow through it
- `Regexp.last_match` is reset by `.sub()` calls — capture groups BEFORE any string transformation
- `Config.configure` is memoized — do not add new calls
- Table format() pattern: always use same format string for headers and data rows

### From Jump Location Tool (Dec 2025)
- Dependency injection for path validators required for CI compatibility
- Jump Commands layer has zero dedicated specs (B018 — scheduled separately)
