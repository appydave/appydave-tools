# AGENTS.md — test-coverage-gaps

> Inherited from bugfix-and-security AGENTS.md. Self-contained.
> Last updated: 2026-03-19

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**This campaign:** Test-only gap closure. No lib/ production code changes except 1-line comment fix (B025).
**Commits:** Always use `kfix` — never `git commit`.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                                         # All tests
bundle exec rspec spec/appydave/tools/dam/s3_operations_spec.rb
bundle exec rspec spec/appydave/tools/dam/share_operations_spec.rb
bundle exec rspec spec/appydave/tools/dam/sync_from_ssd_spec.rb
bundle exec rspec spec/appydave/tools/dam/manifest_generator_spec.rb
bundle exec rspec spec/appydave/tools/gpt_context/cli_spec.rb
bundle exec rspec spec/appydave/tools/jump/                             # All jump specs
bundle exec rubocop --format clang
```

**Baseline:** 759 examples, 0 failures, 85.0% line coverage

---

## Directory Structure

```
lib/appydave/tools/dam/
  s3_operations.rb          configure_ssl_options method (~line 102) — READ ONLY
  share_operations.rb       configure_ssl_options method (~line 89) — READ ONLY
  sync_from_ssd.rb          determine_range (~line 185); stale comment line 173 — FIX COMMENT
  manifest_generator.rb     determine_range (~line 332) — READ ONLY
  jump/
    commands/
      remove.rb             READ ONLY — write spec for this
      add.rb                READ ONLY — write spec for this (may be called create.rb or set.rb)
      update.rb             READ ONLY — write spec for this
spec/appydave/tools/dam/
  s3_operations_spec.rb     ADD configure_ssl_options tests
  share_operations_spec.rb  ADD configure_ssl_options tests
  sync_from_ssd_spec.rb     ADD determine_range edge cases
  manifest_generator_spec.rb ADD determine_range edge cases
spec/appydave/tools/gpt_context/
  cli_spec.rb               ADD functional tests (-i, -e, -f, -o)
spec/appydave/tools/jump/
  commands/
    remove_spec.rb          CREATE THIS
    add_spec.rb             CREATE THIS (check actual filename first)
    update_spec.rb          CREATE THIS (check actual filename first)
spec/support/
  jump_test_helpers.rb      Reference for shared context
  jump_test_locations.rb    Reference for test fixture data
```

---

## Work Unit Details

### fix-b024-ssl-tests

**Goal:** Protect the B017 security fix. `configure_ssl_options` must have unit tests verifying:
1. Default path returns `{}` (no ssl_verify_peer key at all)
2. ENV override path returns `{ ssl_verify_peer: false }`

**Check Gemfile first** — if `climate_control` is present, use it. Otherwise, stub ENV directly:

```ruby
# Direct ENV stub (works without climate_control)
describe '#configure_ssl_options' do
  subject(:ssl_options) { s3_ops.send(:configure_ssl_options) }

  context 'when AWS_SDK_RUBY_SKIP_SSL_VERIFICATION is not set' do
    before { allow(ENV).to receive(:[]).and_call_original }
    before { allow(ENV).to receive(:[]).with('AWS_SDK_RUBY_SKIP_SSL_VERIFICATION').and_return(nil) }

    it 'returns empty hash (SSL verification enabled by default)' do
      expect(ssl_options).to eq({})
    end

    it 'does not include ssl_verify_peer key' do
      expect(ssl_options).not_to have_key(:ssl_verify_peer)
    end
  end

  context 'when AWS_SDK_RUBY_SKIP_SSL_VERIFICATION is "true"' do
    before { allow(ENV).to receive(:[]).and_call_original }
    before { allow(ENV).to receive(:[]).with('AWS_SDK_RUBY_SKIP_SSL_VERIFICATION').and_return('true') }

    it 'returns ssl_verify_peer: false' do
      expect(ssl_options).to eq({ ssl_verify_peer: false })
    end
  end
end
```

Read the existing spec to find how `s3_ops` subject is set up. Add these examples within the existing describe block structure. Same pattern for `share_operations_spec.rb`.

**Commit:** `kfix "add configure_ssl_options unit tests to protect B017 security fix"`

---

### fix-b022-cli-tests

**Goal:** Functional subprocess tests for gpt_context CLI. Test that the actual flags work end-to-end.

**Pattern — write to Tempfile, verify content:**

```ruby
describe '-i include pattern' do
  it 'collects files matching the include pattern' do
    Dir.mktmpdir do |tmpdir|
      # Create a test file
      File.write(File.join(tmpdir, 'test.rb'), '# test content')
      outfile = File.join(tmpdir, 'output.txt')

      `ruby #{script} -i '*.rb' -b #{tmpdir} -o #{outfile} 2>&1`

      expect(File.read(outfile)).to include('# file: test.rb')
    end
  end
end

describe '-e exclude pattern' do
  it 'excludes files matching the exclude pattern' do
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, 'keep.rb'), '# keep')
      File.write(File.join(tmpdir, 'exclude.rb'), '# exclude')
      outfile = File.join(tmpdir, 'output.txt')

      `ruby #{script} -i '*.rb' -e 'exclude.rb' -b #{tmpdir} -o #{outfile} 2>&1`

      content = File.read(outfile)
      expect(content).to include('# file: keep.rb')
      expect(content).not_to include('# file: exclude.rb')
    end
  end
end

describe '-f format' do
  it 'outputs tree format when -f tree specified' do
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, 'test.rb'), '# test')
      outfile = File.join(tmpdir, 'output.txt')

      `ruby #{script} -i '*.rb' -f tree -b #{tmpdir} -o #{outfile} 2>&1`

      expect(File.read(outfile)).to include('test.rb')
    end
  end
end
```

Note: `-b` sets the base directory, `-o` writes to file. Read the existing cli_spec.rb first for the `script` let binding.

**Commit:** `kfix "add functional CLI tests for -i -e -f -o flags to cli_spec"`

---

### fix-b026-b025-range-tests

**Goal:** Add edge case tests for `determine_range` + fix 1-line stale comment.

**In `sync_from_ssd_spec.rb`** — add to the existing `describe '#determine_range'` block:
```ruby
it 'determines range for boundary b00' do
  range = sync_from_ssd.send(:determine_range, 'b00-first-project')
  expect(range).to eq('b00-b49')
end

it 'determines range for single-digit b9' do
  range = sync_from_ssd.send(:determine_range, 'b9-project')
  expect(range).to eq('b00-b49')
end

it 'determines range for non-b letter prefix a40' do
  range = sync_from_ssd.send(:determine_range, 'a40-test-project')
  expect(range).to eq('a00-a49')
end
```

**In `manifest_generator_spec.rb`** — add same 3 examples to the `describe '#determine_range'` block.

**In `sync_from_ssd.rb` line 173** — update comment:
```ruby
# Determine local destination path (archived structure)
# Extract range from project ID (e.g., b65 → b50-b99 range)
```
(Was: `b65 → 60-69 range`)

**Commit:** `kfix "add determine_range edge cases and fix stale comment"`

---

### fix-b027-noargs-test

**Goal:** Strengthen the no-args gpt_context spec to verify file collection stops — not just message output.

The subprocess approach can't easily stub FileCollector. Use a stronger output assertion instead:

```ruby
describe 'no arguments' do
  it 'prints an error message when no patterns provided' do
    output = `ruby #{script} 2>&1`
    expect(output).to include('No options provided')
    expect($CHILD_STATUS.exitstatus).to eq(0)
  end

  it 'does not produce file content output when no patterns provided' do
    output = `ruby #{script} 2>&1`
    expect(output).not_to include('# file:')
    expect(output).not_to include('clipboard')
  end
end
```

The second test verifies file collection output markers are absent — catches regressions where the guard is removed but the script continues to run.

Read existing cli_spec.rb first — update the existing no-args describe block rather than adding a duplicate.

**Commit:** `kfix "strengthen gpt_context no-args spec to verify collection does not proceed"`

---

### fix-b018-jump-specs

**Goal:** Add dedicated unit specs for Jump Commands::Remove, Commands::Add (or Create), Commands::Update.

**Step 1:** Read the source files first:
```
lib/appydave/tools/jump/commands/
```
List what files exist — the command names may differ from Remove/Add/Update.

**Step 2:** Read an existing jump spec (e.g., `spec/appydave/tools/jump/`) for setup patterns.

**Step 3:** For each command, create a spec file covering:
- Happy path: command executes with valid key
- `--force` guard: command without --force prompts/refuses where applicable
- Not-found path: key does not exist — shows suggestion or error
- Error codes / output messages

**Pattern (based on jump_test_helpers.rb):**
```ruby
# frozen_string_literal: true

RSpec.describe Appydave::Tools::Jump::Commands::Remove do
  include_context 'with jump filesystem'

  describe '#run' do
    context 'when location exists' do
      before { setup_jump_config([JumpTestLocations.ad_tools]) }

      it 'removes the location with --force' do
        # ...
      end

      it 'refuses to remove without --force' do
        # ...
      end
    end

    context 'when location does not exist' do
      it 'shows not-found error' do
        # ...
      end
    end
  end
end
```

**Commit:** `kfix "add dedicated specs for Jump Commands Remove Add Update"`

---

## Success Criteria

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 759+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 85.0%
- [ ] `configure_ssl_options` default path verified to NOT include ssl_verify_peer
- [ ] All new spec files start with `# frozen_string_literal: true`
- [ ] No `require 'spec_helper'` in new spec files (auto-required)

---

## Anti-Patterns to Avoid

- ❌ Do NOT use `$?` in specs — use `$CHILD_STATUS` (rubocop)
- ❌ Do NOT use `options.format.nil?` — format defaults to 'tree,content', never nil
- ❌ Do NOT mock internal DAM classes — use shared filesystem context
- ❌ Do NOT require spec_helper explicitly
- ❌ Do NOT modify production lib/ code (except 1-line comment fix in sync_from_ssd.rb)
- ❌ Do NOT use `puts` in lib/ — use `warn` for warnings

---

## Learnings (inherited)

- **`$CHILD_STATUS` not `$?`** — rubocop Special/GlobalVars cop
- **`exit` with no code exits 0** — specs asserting no-args exit should expect 0
- **`options.format` defaults to `'tree,content'`** — never nil
- **Grep full codebase before writing scope** — actual files may differ from brief
- **Integration path assertions** — when changing path algorithms, search specs for old path strings
- **BrandResolver is critical path** — all dam commands flow through it
- **`Regexp.last_match` reset by `.sub()`** — capture groups before string transformation
- **Dependency injection for path validators** — required for CI compatibility in Jump tests
