# AGENTS.md — micro-cleanup

> Inherited from final-test-gaps AGENTS.md. Self-contained.
> Last updated: 2026-03-19

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**This campaign:** 2 test additions + 1 production fix (1 line).
**Commits:** Always use `kfix` — never `git commit`.

---

## Build & Run Commands

```bash
eval "$(rbenv init -)"

RUBYOPT="-W0" bundle exec rspec                                                    # All tests
bundle exec rspec spec/appydave/tools/jump/commands/add_spec.rb
bundle exec rspec spec/appydave/tools/gpt_context/cli_spec.rb
bundle exec rspec spec/appydave/tools/gpt_context/file_collector_spec.rb
bundle exec rubocop --format clang
```

**Baseline:** 830 examples, 0 failures, 85.92% line coverage

---

## Directory Structure

```
lib/appydave/tools/gpt_context/
  file_collector.rb         LINE 19 — change `return build_formats unless` to `return '' unless`

spec/appydave/tools/jump/commands/
  add_spec.rb               ADD `type` field to existing data integrity it block

spec/appydave/tools/gpt_context/
  cli_spec.rb               ADD new it block for `-f json` in the `-f format` describe block
  file_collector_spec.rb    UPDATE nonexistent-dir test to confirm empty string (verify still passes)
```

---

## Work Unit Details

---

### fix-b031 — add_spec: add type field to data integrity test

**Read first:** `spec/appydave/tools/jump/commands/add_spec.rb`

**Find the `'returns location data matching all input attrs'` it block** (added in final-test-gaps). It currently asserts: key, path, jump, tags, description.

**Add one assertion** to that same it block:
```ruby
expect(location[:type]).to eq('tool')
```

`valid_attrs` has `type: 'tool'` so this will pass. The `location.to_h` in Location uses `.compact` — since type is set, it will be present.

**Do NOT create a new it block** — add the assertion to the existing one.

**Run:**
```bash
bundle exec rspec spec/appydave/tools/jump/commands/add_spec.rb
```

All 15 examples should pass. Then full suite. Then:
```bash
kfix "add type field assertion to add_spec location data integrity test"
```

---

### fix-b032 — cli_spec: subprocess test for -f json

**Read first:** `spec/appydave/tools/gpt_context/cli_spec.rb` — specifically the `-f format` describe block.

**Add a new it block** to the `-f format` describe context:

```ruby
it 'outputs valid JSON when -f json specified' do
  Dir.mktmpdir do |tmpdir|
    File.write(File.join(tmpdir, 'test.rb'), '# test content')
    outfile = File.join(tmpdir, 'output.txt')

    `ruby #{script} -i '*.rb' -f json -b #{tmpdir} -o #{outfile} 2>&1`

    content = File.read(outfile)
    expect { JSON.parse(content) }.not_to raise_error
    parsed = JSON.parse(content)
    expect(parsed).to have_key('tree')
    expect(parsed).to have_key('content')
  end
end
```

Note: `JSON` is available in the spec because Ruby stdlib is loaded. No require needed.

**Run:**
```bash
bundle exec rspec spec/appydave/tools/gpt_context/cli_spec.rb
```

Then full suite. Then:
```bash
kfix "add subprocess test for -f json flag to cli_spec"
```

---

### fix-b033 — file_collector.rb: fix silent CWD collection

**Read first:** `lib/appydave/tools/gpt_context/file_collector.rb` line 19.

Current code:
```ruby
return build_formats unless @working_directory && Dir.exist?(@working_directory)
```

**Change to:**
```ruby
return '' unless @working_directory && Dir.exist?(@working_directory)
```

This ensures a missing working directory always returns empty string rather than silently collecting files from the current process working directory.

**Then verify the existing spec still passes:**
```bash
bundle exec rspec spec/appydave/tools/gpt_context/file_collector_spec.rb
```

The `'#build with nonexistent working directory'` example already asserts `expect(subject.build).to eq('')` — this should still pass (and now it's guaranteed by the code, not by an accident of the glob pattern).

**Run rubocop:**
```bash
bundle exec rubocop lib/appydave/tools/gpt_context/file_collector.rb --format clang
```

Then full suite. Then:
```bash
kfix "fix file_collector silent collection from CWD when working directory does not exist"
```

---

## Success Criteria

- [ ] `RUBYOPT="-W0" bundle exec rspec` — 831+ examples, 0 failures
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 85.92%
- [ ] B031: `type` field asserted in add_spec data integrity test
- [ ] B032: json format verified via subprocess in cli_spec
- [ ] B033: `file_collector.rb:19` returns `''` not `build_formats` when dir missing

---

## Anti-Patterns to Avoid

- ❌ Do NOT use `$?` — use `$CHILD_STATUS`
- ❌ Do NOT use `git commit` — use `kfix`
- ❌ Do NOT add `require 'spec_helper'`
- ❌ Do NOT add multiple separate `before` blocks on same context (RSpec/ScatteredSetup)
- ❌ Do NOT create new it blocks for B031 — add assertion to existing block

---

## Learnings (inherited from final-test-gaps)

- **`$CHILD_STATUS` not `$?`** — rubocop Style/SpecialGlobalVars cop
- **`options.format` defaults to `'tree,content'`** — never nil
- **`options.prompt` defaults to nil** — aider format returns `''` when nil
- **`location.to_h` uses symbol keys + `.compact`** — nil fields are dropped
- **Agent pre-read pattern works** — read source files before writing assertions; zero wrong field name failures
- **Parallel wave, all different files** — no merge conflicts expected
- **JSON in subprocess test** — `JSON.parse(content)` in subprocess tests — ensure JSON output goes to outfile not stdout; use `-o outfile` flag
