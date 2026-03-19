# AGENTS.md — final-test-gaps

> Inherited from test-coverage-gaps AGENTS.md. Self-contained.
> Last updated: 2026-03-19

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**This campaign:** Test-only gap closure. No lib/ production code changes.
**Commits:** Always use `kfix` — never `git commit`.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                                                    # All tests
bundle exec rspec spec/appydave/tools/gpt_context/file_collector_spec.rb
bundle exec rspec spec/appydave/tools/gpt_context/cli_spec.rb
bundle exec rspec spec/appydave/tools/jump/commands/add_spec.rb
bundle exec rspec spec/appydave/tools/jump/commands/update_spec.rb
bundle exec rubocop --format clang
```

**Baseline:** 817 examples, 0 failures, 85.61% line coverage

---

## Directory Structure

```
lib/appydave/tools/gpt_context/
  file_collector.rb         READ ONLY — formats: content, tree, json, aider
  options.rb                READ ONLY — Struct with: include_patterns, exclude_patterns,
                                         format, line_limit, debug, output_target,
                                         working_directory, prompt (all keyword_init)

spec/appydave/tools/gpt_context/
  file_collector_spec.rb    ADD json format, aider format, error path tests
  cli_spec.rb               ADD body content assertions to -i and -e describe blocks

spec/appydave/tools/jump/commands/
  add_spec.rb               ADD location data integrity assertions (path, jump, tags, description)
  update_spec.rb            ADD field isolation assertions (non-updated fields unchanged)
```

---

## Work Unit Details

---

### fix-b023 — file_collector_spec: json, aider, error paths

**Read first:** `lib/appydave/tools/gpt_context/file_collector.rb` and
`spec/appydave/tools/gpt_context/file_collector_spec.rb`

**What `build_json` produces:**
```ruby
{
  'tree' => {},      # nested hash matching tree structure
  'content' => [     # array of hashes, one per file
    { 'file' => 'path/to/file.txt', 'content' => '...' }
  ]
}
```
Returns `JSON.pretty_generate(json_output)` — a valid JSON string.

**What `build_aider` produces:**
- With `prompt` set: `aider --message "my prompt" path/to/file1.rb path/to/file2.rb`
- Without `prompt` (nil): returns `''`

**Add these describe blocks to file_collector_spec.rb:**

```ruby
describe '#build with json format' do
  let(:format) { 'json' }
  let(:include_patterns) { ['**/*.txt'] }
  let(:exclude_patterns) { [] }

  it 'returns valid JSON' do
    result = subject.build
    expect { JSON.parse(result) }.not_to raise_error
  end

  it 'includes a tree key in the JSON output' do
    result = JSON.parse(subject.build)
    expect(result).to have_key('tree')
  end

  it 'includes a content key in the JSON output' do
    result = JSON.parse(subject.build)
    expect(result).to have_key('content')
  end

  it 'includes file paths and content in the content array' do
    result = JSON.parse(subject.build)
    files = result['content'].map { |f| f['file'] }
    expect(files).to include('included/file1.txt')

    entry = result['content'].find { |f| f['file'] == 'included/file1.txt' }
    expect(entry['content']).to include('File 1 content')
  end

  it 'excludes files matching exclude patterns from content' do
    result = JSON.parse(subject.build)
    files = result['content'].map { |f| f['file'] }
    expect(files).not_to include('excluded/excluded_file.txt')
  end
end

describe '#build with aider format' do
  let(:format) { 'aider' }
  let(:include_patterns) { ['**/*.txt'] }
  let(:exclude_patterns) { [] }

  context 'when prompt is set' do
    let(:options) do
      Appydave::Tools::GptContext::Options.new(
        include_patterns: include_patterns,
        exclude_patterns: exclude_patterns,
        format: format,
        line_limit: nil,
        working_directory: temp_dir,
        prompt: 'fix the bug'
      )
    end

    it 'returns an aider command string' do
      expect(subject.build).to start_with('aider --message')
    end

    it 'includes the prompt in the command' do
      expect(subject.build).to include('fix the bug')
    end

    it 'includes collected file paths in the command' do
      result = subject.build
      expect(result).to include('included/file1.txt')
    end
  end

  context 'when prompt is not set' do
    it 'returns an empty string' do
      expect(subject.build).to eq('')
    end
  end
end

describe '#build with nonexistent working directory' do
  let(:options) do
    Appydave::Tools::GptContext::Options.new(
      include_patterns: ['**/*.txt'],
      exclude_patterns: [],
      format: 'content',
      line_limit: nil,
      working_directory: '/tmp/does-not-exist-12345'
    )
  end

  it 'returns empty string without raising an error' do
    expect { subject.build }.not_to raise_error
    expect(subject.build).to eq('')
  end
end
```

**Note:** The existing `before` block creates files under `temp_dir`. The aider context with `prompt` needs its own `let(:options)` that overrides the parent — this is fine in RSpec because the inner let shadows the outer.

**Commit:** `kfix "add json, aider, and error path tests to file_collector_spec"`

---

### fix-b028 — cli_spec: add file body content assertions to -i and -e tests

**Read first:** `spec/appydave/tools/gpt_context/cli_spec.rb`

**The gap:** `-i` tests write known content to temp files but only assert on `# file: test.rb` headers. File body content (`# test content`, `# ruby file`) is never asserted. File truncation or body corruption would pass silently.

**Find the `-i include pattern` describe block (lines 43-68). Add body assertions to each existing `it` block:**

In the first `-i` example (`'collects files matching the include pattern'`):
```ruby
# After the existing assertion, add:
expect(File.read(outfile)).to include('# test content')
```

In the second `-i` example (`'does not include files that do not match the pattern'`):
```ruby
# The file 'test.rb' has content '# ruby file'
# After the existing assertions, add:
expect(content).to include('# ruby file')
expect(content).not_to include('# markdown file')
```

**Find the `-e exclude pattern` describe block (lines 70-95). Add body assertions:**

In the first `-e` example (`'excludes files matching the exclude pattern'`):
```ruby
# 'keep.rb' has content '# keep'
# After existing assertions, add:
expect(content).to include('# keep')
```

In the second `-e` example (`'keeps all files when exclude pattern matches nothing'`):
```ruby
# 'keep.rb' has content '# keep'
# After existing assertion, add:
expect(File.read(outfile)).to include('# keep')
```

**Do NOT modify the `-f`, `-o`, or `no arguments` describe blocks** — those are not in scope.

**Commit:** `kfix "add file body content assertions to cli_spec -i and -e tests"`

---

### fix-b029 — add_spec: validate all returned location data fields

**Read first:** `spec/appydave/tools/jump/commands/add_spec.rb`

**The gap:** The `'returns the created location data'` example (lines 35-41) only asserts `result[:location][:key]`. The path, jump, tags, description are never verified — data corruption or field mapping bugs would pass silently.

**Add a new `it` block** in the `'with valid attributes and existing path'` context, immediately after the existing `'returns the created location data'` block:

```ruby
it 'returns location data matching all input attrs' do
  cmd = described_class.new(config, valid_attrs, path_validator: path_validator)
  result = cmd.run

  location = result[:location]
  expect(location[:key]).to eq('new-project')
  expect(location[:path]).to eq('~/dev/new-project')
  expect(location[:jump]).to eq('jnew')
  expect(location[:tags]).to eq(%w[ruby])
  expect(location[:description]).to eq('A new project')
end
```

**Do NOT modify the existing `'returns the created location data'` example** — add alongside it.

**Commit:** `kfix "add data integrity assertions to add_spec returned location data"`

---

### fix-b030 — update_spec: verify non-updated fields remain unchanged

**Read first:** `spec/appydave/tools/jump/commands/update_spec.rb`
**Also read:** `spec/support/jump_test_locations.rb` to get the exact field values for `JumpTestLocations.ad_tools` and `JumpTestLocations.flivideo`

**Gap 1:** `'leaves unmodified locations intact'` (lines 48-53) only checks `config.key_exists?('flivideo')`. The flivideo record's fields (path, jump, tags, description) could be corrupted and the test would still pass.

**Gap 2:** When updating `ad-tools` description, the key/path/jump/tags of the `ad-tools` record itself are never verified to be unchanged.

**Add two new `it` blocks** in the `'when location exists and update is valid'` context:

```ruby
it 'does not modify non-updated fields on the updated record' do
  original = config.find('ad-tools')
  original_path = original.path
  original_jump = original.jump
  original_tags = original.tags

  cmd = described_class.new(config, 'ad-tools', { description: 'Changed' }, path_validator: path_validator)
  cmd.run

  updated = config.find('ad-tools')
  expect(updated.path).to eq(original_path)
  expect(updated.jump).to eq(original_jump)
  expect(updated.tags).to eq(original_tags)
end

it 'does not modify the sibling record fields' do
  original_flivideo = config.find('flivideo')
  original_path = original_flivideo.path
  original_jump = original_flivideo.jump

  cmd = described_class.new(config, 'ad-tools', { description: 'Changed' }, path_validator: path_validator)
  cmd.run

  flivideo = config.find('flivideo')
  expect(flivideo.path).to eq(original_path)
  expect(flivideo.jump).to eq(original_jump)
end
```

**Do NOT modify existing examples** — add alongside them.

**Note:** Read jump_test_locations.rb to understand what fields `JumpTestLocations.flivideo` has before assuming field names.

**Commit:** `kfix "add field isolation assertions to update_spec non-updated fields"`

---

## Success Criteria

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 817+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 85.61%
- [ ] All new `it` blocks use descriptive behaviour names
- [ ] No `require 'spec_helper'` added (auto-required)
- [ ] All new spec files start with `# frozen_string_literal: true` (if any new files created)

---

## Anti-Patterns to Avoid

- ❌ Do NOT use `$?` — use `$CHILD_STATUS` (rubocop Style/SpecialGlobalVars)
- ❌ Do NOT modify existing passing examples — add new ones alongside
- ❌ Do NOT require spec_helper explicitly
- ❌ Do NOT change production lib/ code
- ❌ Do NOT use multiple separate `before` blocks on the same context — rubocop RSpec/ScatteredSetup; merge into one
- ❌ Do NOT assume field names on JumpTestLocations — read the file first

---

## Learnings (inherited from test-coverage-gaps)

- **`$CHILD_STATUS` not `$?`** — rubocop Special/GlobalVars cop
- **`exit` with no code exits 0** — specs asserting no-args exit should expect 0
- **`options.format` defaults to `'tree,content'`** — never nil
- **Grep full codebase before writing scope** — actual files may differ from brief
- **ENV stubbing:** `allow(ENV).to receive(:[]).and_call_original` then targeted override — no climate_control gem
- **Merge `before` blocks** — multiple separate `before` blocks on same context trigger RSpec/ScatteredSetup
- **`options.prompt` defaults to nil** — aider format returns `''` when prompt is nil
- **Parallel wave had zero merge conflicts across 5 agents** — all different files
- **B023 `build_json`:** returns `JSON.pretty_generate` — must `JSON.parse(result)` before asserting on keys
- **B028 body assertions:** file content is written in Dir.mktmpdir blocks; check the `File.write` call to know what body text to assert
