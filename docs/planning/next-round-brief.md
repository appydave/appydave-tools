# Next Round Brief

**Created:** 2026-03-19
**Updated:** 2026-03-19 (after bugfix-and-security assessment)

---

## Recommended Next Campaign: test-coverage-gaps

### Goal

Protect the B017 SSL security fix with a regression test, expand functional test coverage across gpt_context CLI and DAM range logic, and add the missing Jump Commands layer specs.

### Background

Quality audit after bugfix-and-security found:

1. **B024** — `configure_ssl_options` has zero unit tests. The B017 SSL fix (removing unconditional `ssl_verify_peer: false`) has no regression protection. If reverted, all tests still pass. Must fix.
2. **B022** — `cli_spec.rb` only tests `--help`, `--version`, no-args. No functional tests for `-i`, `-e`, `-f`, `-o`. Core behaviour untested at CLI level.
3. **B026** — `determine_range` tests narrow (b40, b65, b99 only). Missing: b00, b9, a40. Both sync_from_ssd_spec and manifest_generator_spec need these.
4. **B027** — gpt_context no-args spec only checks output string. Does not verify file collection stops.
5. **B018** — Jump Commands (Remove/Add/Update) — zero dedicated specs.
6. **B025** — Stale comment sync_from_ssd.rb line 173 (says 60-69, should say b50-b99).

### Suggested Work Units (parallel — all test-only except B025)

1. **fix-b024-ssl-tests** — Add `configure_ssl_options` unit tests to s3_operations_spec and share_operations_spec. Verify empty hash on default path; `{ssl_verify_peer: false}` when ENV override set. Stub ENV directly (`allow(ENV).to receive(:[]).with('AWS_SDK_RUBY_SKIP_SSL_VERIFICATION').and_return('true')`).
2. **fix-b022-cli-tests** — Add functional subprocess tests to cli_spec.rb for -i, -e, -f, -o flags. Write to Tempfile, verify content. Use `Dir.mktmpdir` and clean up after.
3. **fix-b026-b025-range-tests** — Add edge cases (b00, b9, a40) to sync_from_ssd_spec and manifest_generator_spec. Fix stale comment sync_from_ssd.rb line 173 while in the file.
4. **fix-b027-noargs-test** — Strengthen no-args spec: `expect(Appydave::Tools::GptContext::FileCollector).not_to receive(:new)` when no patterns given.
5. **fix-b018-jump-specs** — Add spec files for Jump Commands::Remove, Commands::Add, Commands::Update. Read existing Jump CLI spec first for setup pattern. Use JumpTestLocations + `with jump filesystem` context.

### Mode Recommendation

**Extend** — same stack, same patterns, test-only work. Inherit AGENTS.md.

### Pre-Campaign Notes

- Check if `climate_control` gem is in Gemfile before using ClimateControl — use direct ENV stubbing if not available
- For B022 functional tests: subprocess writes to file, assert content includes `# file:` headers
- For B027: stub at the class level, not instance — `expect(described_class).not_to receive(:new)`
- For B018: read `spec/appydave/tools/jump/` existing specs before writing new command specs
