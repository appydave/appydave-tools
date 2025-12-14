# Repository Guidelines

## Project Structure & Module Organization
Core Ruby code lives in `lib/appydave/tools/` with one folder per CLI (gpt_context, youtube_manager, subtitle_processor, etc.). Executables in `bin/` are for development helpers, while packaged entrypoints reside in `exe/`. Specs mirror the library layout under `spec/`, supported by sample data in `spec/samples/`. Shared docs and walkthroughs are collected under `docs/`. Temporary or generated artifacts (`coverage/`, `tmp/`, `transient/`) should stay out of commits.

## Build, Test, and Development Commands
`bin/setup` installs gem dependencies and any Node helpers declared in `package.json`. Run `bundle exec rake spec` (aliased as `rake spec`) for the full test suite, and keep `guard` running during feature work to auto-rerun specs. Use `bundle exec rubocop` to enforce lint rules, and `bin/console` for an interactive Pry session preloaded with the gem. CLI binaries can be invoked directly, e.g., `bin/gpt_context.rb -i '**/*.rb' -d`.

## Coding Style & Naming Conventions
The codebase targets Ruby 2.7 with two-space indentation and descriptive method names. Follow `.rubocop.yml`: 200-character line limit, relaxed metrics inside `spec/`, and RuboCop RSpec/Rake plugins enabled. Namespaces follow `AppyDave::Tools::<Feature>` inside `lib/`, and CLI filenames stay snake_case (`bin/move_images.rb`). Prefer keyword args, early returns, and guard clauses over deeply nested conditionals.

## Testing Guidelines
RSpec is the canonical framework. Name files `*_spec.rb` that mirror lib paths (e.g., `spec/gpt_context/collector_spec.rb`). Isolate behavior with `describe '#method'` blocks, keep helpers in `spec/support`, and favor `let`/`let!` over global state. Run focused tests via `bundle exec rspec spec/path/to/file_spec.rb` when iterating, then finish with `rake spec`. Add regression tests for every bug fix to keep CLI behavior stable.

## Commit & Pull Request Guidelines
Commits follow conventional commits consumed by semantic-release (`feat:`, `fix:`, `chore:`, `feat!:`, etc.). Scope messages to a single tool when possible (`fix(subtitle_processor): correct offset buffer`). Before opening a PR, ensure `rake spec` and `rubocop` pass, summarize the change, link issues or YouTube scripts, and include CLI output or screenshots if user-facing behavior shifts. Leave follow-up tasks in checklists so reviewers can track outstanding work.

## Agent Coordination
Claude is the primary automation agent; align with the collaboration notes in `CLAUDE.md` before introducing new flows or prompt templates. When scripting repeatable tasks (gpt_context runs, metadata syncs), document the expected Claude inputs/outputs so the agent can reproduce them. Flag breaking CLI changes in PR descriptions with a dedicated **Claude Impact** subsection to keep downstream automations in sync.

## Slash Command Agents

This project has specialized agents activated via slash commands:

| Command | Agent | Purpose |
|---------|-------|---------|
| `/po` | Product Owner | Requirements gathering, spec writing, documentation |
| `/dev` | Developer | Feature implementation, code changes |
| `/uat` | UAT Tester | User acceptance testing, verification |
| `/progress` | Status Check | Quick project status summary |

### Workflow

```
/progress → Quick orientation, see what's pending
    ↓
/po → Discuss requirements, write specs to docs/backlog.md
    ↓
/dev → Implement features based on specs
    ↓
/uat → Test implementation against acceptance criteria
    ↓
/po → Review UAT results, update documentation
```

### Agent Files

Located in `.claude/commands/`:
- `po.md` - Product Owner agent instructions
- `dev.md` - Developer agent instructions
- `uat.md` - UAT tester agent instructions
- `progress.md` - Status check command

### Key Documentation Files

| File | Purpose | Maintained By |
|------|---------|---------------|
| `docs/backlog.md` | Requirements (FR/NFR) with status | /po |
| `docs/brainstorming-notes.md` | Ideas being explored | /po |
| `docs/uat/` | UAT plans and results | /uat |
| `CHANGELOG.md` | Version history | Auto (semantic-release) |
| `CLAUDE.md` | Project context for Claude | Manual |

## Security & Configuration Tips
Keep API keys and OAuth secrets in `.env` or `~/.config/appydave/` (managed via `ad_config`). Never commit those files; `.gitignore` already excludes them. Validate YouTube API changes against a test channel before touching production content, and rotate credentials when machines change owners.
