# IMPLEMENTATION_PLAN.md — s3-operations-split

**Goal**: Split 1,021-line S3Operations into S3Base + 4 focused classes (S3Uploader, S3Downloader, S3StatusChecker, S3Archiver), with S3Operations becoming a thin delegation facade. Prepares for B007 parallelism.
**Started**: 2026-03-20
**Target**: 870 examples passing, rubocop 0, S3Operations ≤ 80 lines, each focused class standalone

## Summary
- Total: 5 | Complete: 0 | In Progress: 0 | Pending: 5 | Failed: 0

## Pending
- [ ] WU1-s3-base — Extract shared infrastructure into S3Base class; S3Operations inherits from it; all 870 tests pass with no public API change
- [ ] WU2-s3-uploader — Create S3Uploader < S3Base; move upload + helpers; S3Operations.upload delegates
- [ ] WU3-s3-downloader — Create S3Downloader < S3Base; move download + helpers; S3Operations.download delegates
- [ ] WU4-s3-status-checker — Create S3StatusChecker < S3Base; move status/calculate_sync_status/sync_timestamps + helpers; S3Operations delegates
- [ ] WU5-s3-archiver — Create S3Archiver < S3Base; move archive/cleanup/cleanup_local + helpers; S3Operations becomes thin facade; add s3_base require to lib/appydave/tools.rb

## In Progress

## Complete

## Failed / Needs Retry

## Notes & Decisions

### Architecture Decision: Inheritance + Delegation
- S3Base: shared infrastructure + shared helpers (no public operation methods)
- S3Uploader/S3Downloader/S3StatusChecker/S3Archiver each inherit S3Base
- S3Operations inherits S3Base (so send(:build_s3_key) etc. still work in existing specs)
  and delegates its public methods to the appropriate sub-class

### Require Order in lib/appydave/tools.rb (add before existing s3_operations line)
```ruby
require 'appydave/tools/dam/s3_base'
require 'appydave/tools/dam/s3_uploader'
require 'appydave/tools/dam/s3_downloader'
require 'appydave/tools/dam/s3_status_checker'
require 'appydave/tools/dam/s3_archiver'
require 'appydave/tools/dam/s3_operations'   # thin facade — keep existing line
```

### Wave size: 1 (sequential only — each WU modifies both a new file AND s3_operations.rb)
### kfix commit after each WU once tests + rubocop are green
