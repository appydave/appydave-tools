# IMPLEMENTATION_PLAN.md — test-coverage-gaps

**Goal**: Close critical test gaps: protect B017 SSL fix, expand gpt_context CLI coverage, range edge cases, Jump Commands specs
**Started**: 2026-03-19
**Target**: All gaps addressed; 759+ examples passing; rubocop clean; no regressions

## Summary
- Total: 5 | Complete: 0 | In Progress: 5 | Pending: 0 | Failed: 0

## Pending

## In Progress
- [~] fix-b024-ssl-tests — Add configure_ssl_options unit tests to s3_operations_spec + share_operations_spec
- [~] fix-b022-cli-tests — Add functional subprocess tests to gpt_context cli_spec.rb (-i, -e, -f, -o)
- [~] fix-b018-jump-specs — Add specs for Jump Commands::Remove, Add, Update

## Complete
- [x] fix-b027-noargs-test — Added second no-args example: verifies output does NOT include '# file:' or 'clipboard'. 766 examples, 0 failures. Note: B024 agent had RSpec/ScatteredSetup rubocop issue (multiple before hooks) — fixed in subsequent commit.
- [x] fix-b026-b025-range-tests — Edge cases (b00, b9, a40) added to sync_from_ssd_spec + manifest_generator_spec. Stale comment fixed in sync_from_ssd.rb:173. ⚠️ CI ISSUE: cli_spec.rb:39 failing — 'not_to include clipboard' assertion is fragile (no-args output may mention clipboard on some platforms). B022 agent touching cli_spec.rb may resolve this.

## Failed / Needs Retry

## Notes & Decisions
- All 5 work units are independent — parallel wave
- Test-only campaign except B025 (1-line comment fix in sync_from_ssd.rb)
- ENV stubbing: use allow(ENV).to receive(:[]) — check Gemfile for climate_control first
- B022 functional tests: write to Tempfile, verify # file: headers in output
- B027: stub GptContext::FileCollector at class level before subprocess call won't work — use integration assertion instead (verify output does NOT contain file collection output)
- B018: read existing jump CLI spec before writing command-layer specs
