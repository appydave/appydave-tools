# AGENTS.md — fr2-gpt-context-help

> Operational knowledge for this campaign's background agents.
> Inherited from docs/planning/AGENTS.md (2026-03-19). Campaign-specific additions below.
> Self-contained — you receive only this file + your work unit prompt.

---

## Project Overview

**What:** Ruby gem providing CLI productivity tools for AppyDave's YouTube content creation workflow.
**Stack:** Ruby 3.4.2, Bundler 2.6.2, RSpec, RuboCop, semantic-release CI/CD.
**This campaign:** FR-2 — enhance `bin/gpt_context.rb` OptionParser with structured help system. One file. No lib/ changes.
**Commits:** Always use `kfeat`/`kfix` — never `git commit`.

---

## Build & Run Commands

```bash
# Initialize rbenv (required if rbenv not in PATH)
eval "$(rbenv init -)"

# Run tests
bundle exec rspec                                        # All tests
bundle exec rspec spec/appydave/tools/gpt_context/       # GPT context specs only
RUBYOPT="-W0" bundle exec rspec                          # Suppress Ruby 3.4 platform warnings

# Lint
bundle exec rubocop --format clang                       # Standard lint check (matches CI)

# Manual verification
bin/gpt_context.rb --help                                # Should show structured help
bin/gpt_context.rb --version                             # Should show version
bin/gpt_context.rb -v                                    # Short version flag
bin/gpt_context.rb --help | grep -E "^(SYNOPSIS|DESCRIPTION|OPTIONS|OUTPUT FORMATS|EXAMPLES)"

# Commit (never use git commit directly)
kfeat "add AI-friendly help system to GPT Context"       # Use this exact message
```

**Baseline (2026-03-19):** 748 examples, 0 failures, 84.88% line coverage (7680/9048)

---

## Directory Structure

```
bin/gpt_context.rb                              ← THE ONLY FILE TO CHANGE
lib/appydave/tools/gpt_context/
  file_collector.rb                             Read-only reference (DO NOT MODIFY)
  options.rb                                    Read-only reference (DO NOT MODIFY)
  output_handler.rb                             Read-only reference (DO NOT MODIFY)
lib/appydave/tools/version.rb                   Read-only — VERSION constant lives here
spec/appydave/tools/gpt_context/
  cli_spec.rb                                   ← CREATE THIS (new file)
  file_collector_spec.rb                        Existing — do not modify
```

---

## Success Criteria

Every work unit must satisfy ALL before marking `[x]`:

- [ ] `bundle exec rspec` — 748+ examples, 0 failures (new specs add to this count)
- [ ] `bundle exec rubocop --format clang` — 0 offenses
- [ ] Line coverage stays ≥ 84.88%
- [ ] `bin/gpt_context.rb --help` output includes SYNOPSIS, DESCRIPTION, OPTIONS, OUTPUT FORMATS, EXAMPLES sections
- [ ] `bin/gpt_context.rb --version` outputs `gpt_context version X.Y.Z`
- [ ] `spec/appydave/tools/gpt_context/cli_spec.rb` exists with ≥ 3 passing tests
- [ ] Banner no longer says `gather_content.rb` — it says `gpt_context`
- [ ] `# frozen_string_literal: true` at top of new spec file

---

## Work Unit Spec

### fr2-gpt-context-help — Implement AI-friendly help system

**File to modify:** `bin/gpt_context.rb`

**What to do:**

1. Replace the `opts.banner` line with a heredoc banner containing Synopsis and Description sections
2. Add `opts.separator` calls for OUTPUT FORMATS and EXAMPLES sections after the options
3. Add `--version` / `-v` flag before the `--help` flag
4. Enhance each option's description to include defaults and examples (multi-line array format)
5. Fix the banner script name: currently `gather_content.rb` → should be `gpt_context`

**Full implementation pattern** (from spec, Option A):

```ruby
OptionParser.new do |opts|
  opts.banner = <<~BANNER
    GPT Context Gatherer - Collect project files for AI context

    SYNOPSIS
        gpt_context [options]

    DESCRIPTION
        Collects and packages codebase files for AI assistant context.
        Outputs to clipboard (default), file, or stdout.

  BANNER

  opts.separator "OPTIONS"
  opts.separator ""

  opts.on('-i', '--include PATTERN',
          'Glob pattern for files to include (repeatable)',
          'Example: -i "lib/**/*.rb" -i "bin/**/*.rb"') do |pattern|
    options.include_patterns << pattern
  end

  opts.on('-e', '--exclude PATTERN',
          'Glob pattern for files to exclude (repeatable)',
          'Example: -e "spec/**/*" -e "node_modules/**/*"') do |pattern|
    options.exclude_patterns << pattern
  end

  opts.on('-f', '--format FORMATS',
          'Output format(s): tree, content, json, aider, files',
          'Comma-separated. Default: content',
          'Example: -f tree,content') do |format|
    options.format = format
  end

  opts.on('-o', '--output TARGET',
          'Output target: clipboard, filename, or stdout',
          'Default: clipboard. Repeatable for multiple targets.') do |target|
    options.output_target << target
  end

  opts.on('-d', '--debug [MODE]', 'Enable debug mode [none, info, params, debug]',
          'none', 'info', 'params', 'debug') do |debug|
    options.debug = debug || 'info'
  end

  opts.on('-l', '--line-limit N', Integer,
          'Limit lines per file (default: unlimited)') do |n|
    options.line_limit = n
  end

  opts.on('-b', '--base-dir DIRECTORY',
          'Set the base directory to gather files from') do |directory|
    options.working_directory = directory
  end

  opts.on('-p', '--prompt TEXT',
          'Prompt text for aider format output') do |message|
    options.prompt = message
  end

  opts.separator ""
  opts.separator "OUTPUT FORMATS"
  opts.separator "    tree     - Directory tree structure"
  opts.separator "    content  - File contents with headers (default)"
  opts.separator "    json     - Structured JSON output"
  opts.separator "    aider    - Aider CLI command format (requires -p)"
  opts.separator "    files    - File paths only"
  opts.separator ""
  opts.separator "EXAMPLES"
  opts.separator "    # Gather Ruby library code for AI context"
  opts.separator "    gpt_context -i 'lib/**/*.rb' -e 'spec/**/*' -d"
  opts.separator ""
  opts.separator "    # Project structure overview"
  opts.separator "    gpt_context -i '**/*' -f tree -e 'node_modules/**/*'"
  opts.separator ""
  opts.separator "    # Save to file with tree and content"
  opts.separator "    gpt_context -i 'src/**/*.ts' -f tree,content -o context.txt"
  opts.separator ""
  opts.separator "    # Generate aider command"
  opts.separator "    gpt_context -i 'lib/**/*.rb' -f aider -p 'Add logging'"
  opts.separator ""

  opts.on('-v', '--version', 'Show version') do
    puts "gpt_context version #{Appydave::Tools::VERSION}"
    exit
  end

  opts.on_tail('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end.parse!
```

**New spec file** `spec/appydave/tools/gpt_context/cli_spec.rb`:

```ruby
# frozen_string_literal: true

RSpec.describe 'gpt_context CLI help' do
  let(:script) { File.expand_path('../../../../bin/gpt_context.rb', __dir__) }

  describe '--help' do
    subject(:output) { `ruby #{script} --help 2>&1` }

    it 'includes SYNOPSIS section' do
      expect(output).to include('SYNOPSIS')
    end

    it 'includes EXAMPLES section' do
      expect(output).to include('EXAMPLES')
    end

    it 'includes OUTPUT FORMATS section' do
      expect(output).to include('OUTPUT FORMATS')
    end
  end

  describe '--version' do
    it 'shows version number' do
      output = `ruby #{script} --version 2>&1`
      expect(output).to match(/gpt_context version \d+\.\d+\.\d+/)
    end
  end
end
```

---

## Anti-Patterns to Avoid

- ❌ Do NOT modify any file in `lib/` — this campaign is bin/ only
- ❌ Do NOT use `opts.on_tail` for `--version` (use `opts.on` so it appears before `--help` in output)
- ❌ Do NOT leave the banner saying `gather_content.rb`
- ❌ Do NOT require spec_helper explicitly — it's auto-required via `.rspec` config
- ❌ Do NOT use `system()` or backticks in specs to call the script with a path that includes spaces

---

## Quality Gates

- **Tests:** `bundle exec rspec` — 748+ examples, 0 failures
- **Lint:** `bundle exec rubocop --format clang` — 0 offenses
- **Coverage:** ≥ 84.88% line coverage
- **Manual:** `bin/gpt_context.rb --help` and `--version` work as expected
- **Commit format:** `kfeat "add AI-friendly help system to GPT Context"`

---

## Learnings (inherited)

### From Three-Lens Audit (2026-03-19)
- `file_collector.rb` pre-conditions (B015, B019) already fixed in commit 13d5f87 — do not re-fix
- BUG-1 already verified fixed — do not re-investigate

### From DAM Enhancement Sprint (Jan 2025)
- `Config.configure` is memoized — idempotent
- Table format() pattern: always use same format string for headers and data rows

### From Jump Location Tool (Dec 2025)
- Dependency injection for path validators required for CI compatibility
- Jump Commands layer is undertested — not relevant to this campaign
