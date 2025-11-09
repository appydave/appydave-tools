# CODEX Recommendations

> Last updated: 2025-11-09 13:36:08 UTC  
> Maintenance note: whenever files outside this document change, review them and reflect any new patterns/risks here so the recommendations stay authoritative.

Guide created by Codex (GPT-5) to capture near-term cleanups and deeper refactors that will make `appydave-tools` easier to extend and test.

## Snapshot

- **Primary friction**: global configuration access makes VAT objects hard to test, forcing `allow_any_instance_of` overrides in specs such as `spec/appydave/tools/vat/config_spec.rb:6`.
- **Secondary friction**: command classes mix terminal IO with core logic (see `lib/appydave/tools/vat/project_resolver.rb:19-50`), which complicates automation and reuse.
- **Tooling debt**: RuboCop is configured (`.rubocop.yml`) but not enforced; the current run emits 108 offenses (93 auto-correctable per Claude logs) and engineers silence cops instead of resolving root causes.

## Priority Map

| Order | Theme | Why it matters |
| --- | --- | --- |
| P0 | Make configuration/services injectable | Unlocks clean tests, eliminates global stubs, and keeps future CLIs composable. |
| P1 | Re-enable effective lint/test automation | 93 auto-fixes are “free”; the remaining 15 surface real architecture problems that deserve explicit debt tracking. |
| P2 | Separate IO from business logic in CLI helpers | Enables automation agents (Claude) and humans to reuse services without TTY prompts. |
| P3 | Standardize filesystem fixtures | Reduces the bespoke `Dir.mktmpdir` + `FileUtils` boilerplate sprinkled through VAT specs; faster, safer tests. |

## Detailed Recommendations

### 1. Introduce configuration adapters

- **Problem**: `Appydave::Tools::Vat::Config.projects_root` reaches directly into `Configuration::Config.settings` (`lib/appydave/tools/vat/config.rb:13-21`), so specs must stub *every* `SettingsConfig` instance (`spec/appydave/tools/vat/config_spec.rb:14`).  
- **Action**:
  1. Create a lightweight `SettingsProvider` (duck-typed or interface module) that exposes `video_projects_root`.
  2. Update VAT entry points to accept `settings:` or `config:` keyword args defaulting to the singleton, e.g. `def projects_root(settings: default_settings)`.
  3. Provide a `Config.with_settings(temp_settings) { ... }` helper for specs and CLI overrides.
- **Impact**: RSpec can inject fakes without `allow_any_instance_of`; RuboCop warning disappears with no cop disable required.

### 2. Capture the remaining RuboCop debt deliberately

- **Problem**: Engineers currently choose between “ignore 108 offenses” or “disable cops,” which erodes lint value. `.rubocop.yml` already sets generous limits (200-char lines, spec exclusions), so remaining issues are meaningful.
- **Action plan**:
  1. Run `bundle exec rubocop --auto-correct` and commit format-only fixes (expect ~93 files touched).
  2. For the 15 blocking offenses, open a short-lived spreadsheet (or GH issue tracker) that records *cop → file → fix owner*. This keeps the queue visible without blocking merges.
  3. Add a CI step (GitHub Action or Circle job) that executes `bundle exec rubocop` plus `bundle exec rake spec`, failing PRs that reintroduce offenses.
- **Fallback**: If any `allow_any_instance_of` remains after Step 1, convert it to the adapter pattern described above; avoid new `rubocop:disable` directives unless there’s a written justification beside them.

### 3. Decouple terminal IO from VAT services

- **Problem**: `ProjectResolver.resolve` blends filesystem globbing with interactive prompts (`puts`/`$stdin.gets`, `lib/appydave/tools/vat/project_resolver.rb:41-48`). These prompts block automation agents, and the logic cannot be reused inside other CLIs or tests without stubbing global IO.
- **Action**:
  1. Extract the pure resolution logic so it always returns a result set (possibly multi-match) and never prints.
  2. Create an `InteractiveResolver` (or CLI layer) that takes `io_in:`/`io_out:` and handles messaging/selection.
  3. Update `bin/vat` commands to use the interactive wrapper; specs can cover both the pure resolver and the IO adapter with deterministic streams.
- **Bonus**: While refactoring, move the repeated `Dir.glob` filtering into a shared helper (e.g., `Projects::Scanner`) so CLAUDE/Code agents can reuse it for listing commands.

### 4. Standardize filesystem fixtures

- **Observation**: VAT specs repeatedly open temp dirs, `mkdir_p` brand/project skeletons, and remember to clean up (see blocks at `spec/appydave/tools/vat/config_spec.rb:22-178` and `spec/appydave/tools/vat/project_resolver_spec.rb:9-70`). Minor mistakes (missing cleanup, duplicated brand shortcuts) cause flaky tests locally.
- **Action**:
  1. Add `spec/support/filesystem_helpers.rb` with helpers like `with_projects_root(brands: %w[appydave]) { |root| ... }`.
  2. Include the helper in `spec/spec_helper.rb`, then convert VAT specs to the helper to remove boilerplate and centralize cleanup.
  3. Consider shipping seeded sample trees under `spec/samples/video-projects` for regression-style tests that need deeper structures.

### 5. Harden `Configuration::Config`

- **Problem**: `Configuration::Config` uses `method_missing` to expose registered configs (`lib/appydave/tools/configuration/config.rb:31-39`), which hides failures until runtime and complicates auto-complete.
- **Action**:
  1. Replace `method_missing` with explicit reader methods or `Forwardable`, or at minimum raise descriptive errors that list the registered keys (`configurations.keys`).
  2. Expose a `fetch(:settings)` API that returns nil-friendly values for easier dependency injection.
  3. Document the registration flow in `docs/development/cli-architecture-patterns.md` so new tools follow the same adapter approach.

### 6. Bake the plan into docs & automation

- Add a **Claude Impact** note whenever a CLI behavior changes (per `AGENTS.md`), and link back to this file so the agent knows why tests may require new prompts.
- Create a short checklist in `docs/development/README.md` (“Before merging VAT changes: run rubocop, run VAT specs, update configuration adapters”) to keep the recommendations visible.

## Architecture-Wide Opportunities

### CLI boundaries & shared ergonomics

- `bin/gpt_context.rb:15-88` hand-rolls its `OptionParser` setup even though `lib/appydave/tools/cli_actions/base_action.rb:8-44` already codifies a reusable CLI contract. Promote `BaseAction` to the default entrypoint for every CLI (gpt_context, prompt_tools, subtitle_processor, Ito/AI-TLDR helpers) so options, `-h`, and validation logic stay consistent.  
- Extract a `Cli::Runner` that discovers actions via naming (`Appydave::Tools::<Tool>::Cli::<Command>`) and wire it into each `bin/*` – this keeps future tools (Hey Ito, BMAD, etc.) aligned without duplicating boilerplate.  
- Add smoke specs that exercise each executable via `CLIHelpers.run('bin/gpt_context.rb --help')` to catch option regressions and ensure Guard/Claude can rely on deterministic output.

### GptContext as a reusable service

- `lib/appydave/tools/gpt_context/file_collector.rb:12-77` mutates global process state with `FileUtils.cd` and prints the working directory from inside the constructor. Replace this with `Dir.chdir(working_dir) { … }` blocks and pass a logger so the class can run quietly when invoked programmatically.  
- The collector silently reads every match into memory; for large worktrees (Ito + AppyDave), the CLI will thrash. Consider yielding per-file chunks to a stream-aware `OutputHandler` so future AI agents can request incremental context.  
- Normalize include/exclude matching by compiling glob patterns once (e.g., using `File::FNM_EXTGLOB`) to avoid repeated `Dir.glob` passes, and consider exposing a dry-run mode that returns candidate file lists for Claude prompt generation.

### Subtitle pipeline robustness

- `lib/appydave/tools/subtitle_processor/clean.rb:9-95` combines parsing, normalization, and IO side-effects. Break this into (1) a pure parser that operates on enumerables, (2) a formatter that emits SRT or VTT, and (3) a CLI wrapper for file IO. Doing so makes it easier to add BMAD-specific filters (emoji stripping, custom timelines) without forking the entire class.  
- Add quick fuzz tests that feed malformed SRT snippets to ensure the parser fails fast instead of silently swallowing lines.  
- Document the workflow in `docs/tools/subtitle_processor.md` (currently absent) so collaborators understand how to integrate Hey Ito or AI-TLDR narration scripts.

### YouTube automation hardening

- `lib/appydave/tools/youtube_manager/youtube_base.rb:8-17` constructs a Google API client on every command invocation. Cache the service in a memoized factory or inject it so tests can supply a fake client.  
- `lib/appydave/tools/youtube_manager/authorization.rb:9-54` shells out a WEBrick server and prints instructions; wrap this interaction in a strategy object so Claude can be told “launch headless auth” versus “prompt operator David Cruwys.”  
- Build retries and quota awareness around `@service.update_video` (`lib/appydave/tools/youtube_manager/update_video.rb:31-43`) so Ito/BMAD batch jobs can recover from `Google::Apis::RateLimitError` instead of crashing half-way through.

### Configuration & type safety

- `lib/appydave/tools/types/base_model.rb` + siblings provide a mini ActiveModel alternative but many tools now depend directly on `ActiveModel` (see `appydave-tools.gemspec:28-34`). Decide whether to lean fully into ActiveModel validations (Ruby 3-ready) or keep the custom types. If the latter, add coercion specs to lock down behavior for indifferent hashes (useful for AI ingestion).  
- Expose typed settings objects per feature (`VatSettings`, `YoutubeSettings`) that wrap `SettingsConfig` so each CLI only sees the keys it needs. This makes future schema evolution (e.g., extra Ito endpoints) less risky.

### Testing & observability

- `spec/spec_helper.rb:5-41` always bootstraps SimpleCov/WebMock, which slows down iterative TDD. Guard these with ENV flags (`COVERAGE=true`, `ALLOW_NET=true`) so developers can opt into faster loops when needed.  
- Add contract tests for each CLI that ensure stdout/stderr remain machine-readable—critical for Claude pipelines documented in `CLAUDE.md`. Snapshot testing (via `rspec-snapshot`) works well for command help text.  
- Extend logging: `k_log` is only used inside configuration; wire it into VAT, GPT Context, and YouTube workflows so all tools share the same structured logging style. Include context like `brand=appydave` or `persona=Hey Ito` to help when multiple personas (Ito, AI-TLDR, AppyDave, BMAD) run jobs concurrently.

### Platform & dependency strategy

- `appydave-tools.gemspec:11-37` still declares `required_ruby_version >= 2.7`, but dependencies such as `activemodel ~> 8` and `google-api-client` are already Ruby 3-first. Move the baseline to Ruby 3.2 (or 3.3) so pattern matching, numbered parameters, and improved GC become available.  
- Once on Ruby 3.2+, enable YJIT in local scripts (document via `docs/development/README.md`) to speed up large jobs like GPT context scans.  
- Create a `Dependabot` (or Renovate) config so gem bumps don’t surprise automation—Ito and Hey Ito will benefit from predictable upgrade cadences. Pair this with a changelog checklist entry reminding you to note **Claude Impact** when APIs change.

## Suggested Next Steps

1. **Week 1**: Implement the configuration adapter + filesystem helper, convert VAT specs, and remove the `RSpec/AnyInstance` disable comment.
2. **Week 2**: Run RuboCop auto-correct, triage the residual offenses, and wire RuboCop/spec runs into CI.
3. **Week 3**: Refactor `ProjectResolver` IO separation and document the new contract for CLI callers.
4. **Week 4**: Revisit other CLIs (`youtube_manager`, `subtitle_processor`) and apply the same adapter/IO patterns once VAT proves the approach.

Ping Codex if you’d like guidance on scoping or sequencing—happy to help break these down into actionable tickets.
